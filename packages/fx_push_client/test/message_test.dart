import 'package:flutter_test/flutter_test.dart';
import 'package:fx_push_client/fx_push_client.dart';

void main() {
  test('decodes an APNs alert and root custom data', () {
    final codec = FxPushMessageCodec(
      deeplinkValidator: (uri) =>
          uri.scheme == 'fxtest' && uri.host == 'notification',
    );

    final message = codec.decode(<Object?, Object?>{
      'aps': <Object?, Object?>{
        'alert': <Object?, Object?>{
          'title': 'Received',
          'body': 'You received 1 USDT',
        },
        'sound': 'default',
      },
      'event_id': 'transfer-123',
      'launchUrl': 'fxtest://notification/transfer-123',
      'account': 'primary',
    });

    expect(message.title, 'Received');
    expect(message.body, 'You received 1 USDT');
    expect(message.eventId, 'transfer-123');
    expect(
      message.deeplink,
      Uri.parse('fxtest://notification/transfer-123'),
    );
    expect(message.data['account'], 'primary');
    expect(
      () => message.data['new'] = 'value',
      throwsUnsupportedError,
    );
  });

  test('decodes a normalized FCM notification and nested data', () {
    final codec = FxPushMessageCodec();

    final message = codec.decode(<Object?, Object?>{
      'notification': <Object?, Object?>{
        'title': 'Price alert',
        'body': 'BTC moved',
      },
      'data': <Object?, Object?>{
        'event_id': 'price:btc:001',
        'launchUrl': 'fxwallet://market/btc',
      },
    });

    expect(message.title, 'Price alert');
    expect(message.body, 'BTC moved');
    expect(message.eventId, 'price:btc:001');
    expect(message.deeplink, Uri.parse('fxwallet://market/btc'));
  });

  test('rejects conflicting provider text and non-string data', () {
    final codec = FxPushMessageCodec();

    expect(
      () => codec.decode(<Object?, Object?>{
        'aps': <Object?, Object?>{
          'alert': <Object?, Object?>{'title': 'APNs'},
        },
        'notification': <Object?, Object?>{'title': 'FCM'},
      }),
      throwsA(isA<FxPushMessageFormatException>()),
    );
    expect(
      () => codec.decode(<Object?, Object?>{
        'data': <Object?, Object?>{'count': 1},
      }),
      throwsA(isA<FxPushMessageFormatException>()),
    );
  });

  test('rejects a deeplink denied by the host validator', () {
    final codec = FxPushMessageCodec(
      deeplinkValidator: (uri) => uri.scheme == 'fxtest',
    );

    expect(
      () => codec.decode(<Object?, Object?>{
        'launchUrl': 'fxwallet://notification/event-1',
      }),
      throwsA(
        isA<FxPushMessageFormatException>().having(
          (error) => error.field,
          'field',
          'launchUrl',
        ),
      ),
    );
  });

  test('normalizes foreground, open, and cold-start events', () async {
    final bridge = FxPushNotificationBridge(
      codec: FxPushMessageCodec(
        deeplinkValidator: (uri) => uri.scheme == 'fxtest',
      ),
    );
    final emitted = <FxPushNotificationEvent>[];
    final subscription = bridge.events.listen(emitted.add);
    final time = DateTime.utc(2026, 9, 19);

    final foreground = bridge.handleForeground(
      _payload('foreground-1'),
      occurredAt: time,
    );
    final opened = bridge.handleOpened(
      _payload('open-1'),
      occurredAt: time.add(const Duration(seconds: 1)),
    )!;
    final duplicateOpen = bridge.handleOpened(_payload('open-1'));
    final initial = bridge.recordInitialOpen(
      _payload('initial-1'),
      occurredAt: time.add(const Duration(seconds: 2)),
    );
    final duplicateInitial = bridge.handleOpened(_payload('initial-1'));

    expect(foreground.type, FxPushNotificationEventType.foregroundReceived);
    expect(opened.type, FxPushNotificationEventType.opened);
    expect(duplicateOpen, isNull);
    expect(initial?.type, FxPushNotificationEventType.initialOpen);
    expect(duplicateInitial, isNull);
    expect(emitted, <FxPushNotificationEvent>[foreground, opened]);
    expect(bridge.takeInitialOpen(), same(initial));
    expect(bridge.takeInitialOpen(), isNull);

    await subscription.cancel();
    await bridge.dispose();
    expect(
      () => bridge.handleForeground(_payload('after-dispose')),
      throwsStateError,
    );
  });

  test('normalizes FCM foreground, background open, and initial open',
      () async {
    final bridge = FxPushNotificationBridge(
      codec: FxPushMessageCodec(
        deeplinkValidator: (uri) => uri.scheme == 'fxtest',
      ),
    );
    final emitted = <FxPushNotificationEvent>[];
    final subscription = bridge.events.listen(emitted.add);

    final foreground = bridge.handleForeground(_fcmPayload('foreground-fcm'));
    final opened = bridge.handleOpened(_fcmPayload('background-fcm'));
    final initial = bridge.recordInitialOpen(_fcmPayload('initial-fcm'));

    expect(foreground.message.title, 'FCM title');
    expect(foreground.message.body, 'FCM body');
    expect(foreground.message.eventId, 'foreground-fcm');
    expect(opened?.type, FxPushNotificationEventType.opened);
    expect(initial?.type, FxPushNotificationEventType.initialOpen);
    expect(bridge.handleOpened(_fcmPayload('background-fcm')), isNull);
    expect(bridge.handleOpened(_fcmPayload('initial-fcm')), isNull);
    expect(emitted, <FxPushNotificationEvent>[foreground, opened!]);
    expect(bridge.takeInitialOpen(), same(initial));

    await subscription.cancel();
    await bridge.dispose();
  });
}

Map<Object?, Object?> _payload(String eventId) => <Object?, Object?>{
      'aps': <Object?, Object?>{
        'alert': <Object?, Object?>{
          'title': 'Title',
          'body': 'Body',
        },
      },
      'event_id': eventId,
      'launchUrl': 'fxtest://notification/$eventId',
    };

Map<Object?, Object?> _fcmPayload(String eventId) => <Object?, Object?>{
      'notification': <Object?, Object?>{
        'title': 'FCM title',
        'body': 'FCM body',
      },
      'data': <Object?, Object?>{
        'event_id': eventId,
        'launchUrl': 'fxtest://notification/$eventId',
      },
    };
