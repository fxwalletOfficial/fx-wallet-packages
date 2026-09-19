import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:fx_push_client/fx_push_client.dart';

const _appId = '11111111-2222-4333-8444-555555555555';
final _serviceUrl = Uri.parse('https://notify.example.com');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'creates stable installation identity and 32-byte lowercase credential',
    () async {
      final storage = MemorySecureStorage();
      final endpointSource = FxPushEndpointSource(_apns('aa11'));
      final firstTransport = RecordingTransport();
      final first = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: storage,
        endpointSource: endpointSource,
        transport: firstTransport,
        retryDelays: _noDelay,
      );

      await first.start();
      final firstRequest = firstTransport.requests.single;
      expect(
        firstRequest.body['installation_id'],
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(firstRequest.registrationKey, matches(RegExp(r'^[0-9a-f]{64}$')));
      await first.dispose();

      final secondTransport = RecordingTransport();
      final second = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: storage,
        endpointSource: endpointSource,
        transport: secondTransport,
        retryDelays: _noDelay,
      );
      await second.start();

      expect(
        secondTransport.requests.single.body['installation_id'],
        firstRequest.body['installation_id'],
      );
      expect(
        secondTransport.requests.single.registrationKey,
        firstRequest.registrationKey,
      );
      await second.dispose();
      await endpointSource.dispose();
    },
  );

  test(
    'sends full APNs state and exposes the server subscription state',
    () async {
      final transport = RecordingTransport();
      final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: MemorySecureStorage(),
        endpointSource: endpointSource,
        transport: transport,
        retryDelays: _noDelay,
      );

      await client.start();

      expect(transport.requests.single.body, containsPair('app_id', _appId));
      expect(transport.requests.single.body, containsPair('active', true));
      expect(transport.requests.single.body, containsPair('provider', 'apns'));
      expect(transport.requests.single.body, containsPair('platform', 'ios'));
      expect(
        transport.requests.single.body,
        containsPair('token', 'aabbccdd'),
      );
      expect(
        transport.requests.single.body,
        containsPair('apns_environment', 'sandbox'),
      );
      expect(
        client.state.value.subscriptionId,
        RecordingTransport.subscriptionId,
      );
      expect(client.state.value.revision, '1');
      expect(client.state.value.phase, FxPushSyncPhase.synchronized);
      await client.dispose();
      await endpointSource.dispose();
    },
  );

  test('rejects an invalid persisted desired active state', () async {
    final storage = MemorySecureStorage();
    storage.values['fx_push_client.v1.$_appId.desired_active'] = 'enabled';
    final transport = RecordingTransport();
    final endpointSource = FxPushEndpointSource(_apns('aabb'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: storage,
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );

    await expectLater(
      client.start(),
      throwsA(
        isA<FxPushStoredStateException>().having(
          (error) => error.field,
          'field',
          'desired_active',
        ),
      ),
    );
    expect(client.state.value.phase, FxPushSyncPhase.failed);
    expect(transport.requests, isEmpty);

    await client.dispose();
    await endpointSource.dispose();
  });

  test('sends FCM state without an APNs environment', () async {
    final transport = RecordingTransport();
    final endpointSource = FxPushEndpointSource(
      FxPushEndpoint(
        provider: FxPushProvider.fcm,
        platform: FxPushPlatform.android,
        token: 'fcm-token',
      ),
    );
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );

    await client.start();

    expect(transport.requests.single.body, containsPair('provider', 'fcm'));
    expect(transport.requests.single.body, containsPair('platform', 'android'));
    expect(transport.requests.single.body, containsPair('token', 'fcm-token'));
    expect(
      transport.requests.single.body,
      isNot(contains('apns_environment')),
    );
    await client.dispose();
    await endpointSource.dispose();
  });

  test('rejects provider and platform combinations that cannot be delivered',
      () {
    expect(
      () => FxPushEndpoint(
        provider: FxPushProvider.fcm,
        platform: FxPushPlatform.ios,
        token: 'fcm-token',
      ),
      throwsArgumentError,
    );
    expect(() => _apns('not-hex'), throwsArgumentError);
    expect(
      () => FxPushEndpoint(
        provider: FxPushProvider.apns,
        platform: FxPushPlatform.android,
        token: 'aabb',
        apnsEnvironment: FxApnsEnvironment.sandbox,
      ),
      throwsArgumentError,
    );
  });

  test('FCM token rotation resynchronizes the same installation', () async {
    final transport = RecordingTransport();
    final endpointSource = FxPushEndpointSource(
      FxPushEndpoint(
        provider: FxPushProvider.fcm,
        platform: FxPushPlatform.android,
        token: 'fcm-token-old',
      ),
    );
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );
    await client.start();

    endpointSource.update(
      FxPushEndpoint(
        provider: FxPushProvider.fcm,
        platform: FxPushPlatform.android,
        token: 'fcm-token-new',
      ),
    );
    for (var i = 0; i < 10 && transport.requests.length < 2; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(transport.requests, hasLength(2));
    expect(transport.requests.first.body['token'], 'fcm-token-old');
    expect(transport.requests.last.body['token'], 'fcm-token-new');
    expect(
      transport.requests.last.body['installation_id'],
      transport.requests.first.body['installation_id'],
    );
    expect(
      transport.requests.last.registrationKey,
      transport.requests.first.registrationKey,
    );
    await client.dispose();
    await endpointSource.dispose();
  });

  test('persists disable first and sends the minimal disabled body', () async {
    final storage = MemorySecureStorage();
    final transport = RecordingTransport(disabledSubscriptionId: null);
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: storage,
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );
    await client.start();

    await client.setActive(false);

    final request = transport.requests.last;
    expect(request.body.keys, <String>{'app_id', 'installation_id', 'active'});
    expect(request.body['active'], false);
    expect(
      storage.values.values,
      contains('false'),
      reason: 'desired state must be durable before the request is sent',
    );
    expect(client.state.value.subscriptionId, isNull);
    await client.dispose();
    await endpointSource.dispose();
  });

  test(
    'serializes concurrent changes and sends the latest desired state',
    () async {
      final transport = BlockingTransport();
      final endpointSource = FxPushEndpointSource(_apns('0011'));
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: MemorySecureStorage(),
        endpointSource: endpointSource,
        transport: transport,
        retryDelays: _noDelay,
      );

      final start = client.start();
      await transport.firstStarted.future;
      endpointSource.update(_apns('2233'));
      final disable = client.setActive(false);
      transport.releaseFirst.complete();
      await Future.wait(<Future<void>>[start, disable]);

      expect(transport.maxConcurrent, 1);
      expect(transport.requests.first.body['active'], true);
      expect(transport.requests.last.body, <String, Object>{
        'app_id': _appId,
        'installation_id': transport.requests.last.body['installation_id']!,
        'active': false,
      });
      await client.dispose();
      await endpointSource.dispose();
    },
  );

  test(
    'retry wakes for a state change and rebuilds a disabled request',
    () async {
      final transport = FailOnceTransport();
      final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
      final client = FxPushClient(
        serviceUrl: _serviceUrl,
        appId: _appId,
        secureStorage: MemorySecureStorage(),
        endpointSource: endpointSource,
        transport: transport,
        retryDelays: const <Duration>[
          Duration(minutes: 1),
          Duration.zero,
          Duration.zero,
        ],
      );

      final start = client.start();
      await transport.failed.future;
      await client.setActive(false);
      await start;

      expect(transport.requests, hasLength(2));
      expect(transport.requests.first.body['active'], true);
      expect(transport.requests.last.body['active'], false);
      await client.dispose();
      await endpointSource.dispose();
    },
  );

  test('resumed lifecycle queues another synchronization', () async {
    final transport = RecordingTransport();
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );
    await client.start();

    client.didChangeAppLifecycleState(AppLifecycleState.resumed);
    for (var i = 0; i < 10 && transport.requests.length < 2; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(transport.requests, hasLength(2));
    await client.dispose();
    await endpointSource.dispose();
  });

  test('does not retry a non-retryable enrollment error', () async {
    final transport = AlwaysFailTransport(
      const FxPushHttpException(statusCode: 401, code: 'UNAUTHORIZED'),
    );
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );

    await client.start();

    expect(transport.calls, 1);
    expect(client.state.value.phase, FxPushSyncPhase.failed);
    await client.dispose();
    await endpointSource.dispose();
  });

  test('stops after three retries for a retryable error', () async {
    final transport = AlwaysFailTransport(
      const FxPushHttpException(statusCode: 503),
    );
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );

    await client.start();

    expect(transport.calls, 4);
    expect(client.state.value.phase, FxPushSyncPhase.failed);
    await client.dispose();
    await endpointSource.dispose();
  });

  test('rejects an active response without a subscription ID', () async {
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: MemorySecureStorage(),
      endpointSource: endpointSource,
      transport: NullActiveSubscriptionTransport(),
      retryDelays: _noDelay,
    );

    await client.start();

    expect(client.state.value.phase, FxPushSyncPhase.failed);
    expect(client.state.value.lastError, isA<FxPushProtocolException>());
    expect(client.state.value.subscriptionId, isNull);
    await client.dispose();
    await endpointSource.dispose();
  });

  test('does not attach observers when disposed during initialization',
      () async {
    final storage = BlockingReadStorage();
    final transport = RecordingTransport();
    final endpointSource = FxPushEndpointSource(_apns('aabbccdd'));
    final client = FxPushClient(
      serviceUrl: _serviceUrl,
      appId: _appId,
      secureStorage: storage,
      endpointSource: endpointSource,
      transport: transport,
      retryDelays: _noDelay,
    );

    final start = client.start();
    await storage.readStarted.future;
    await client.dispose();
    storage.releaseRead.complete();

    await expectLater(start, throwsStateError);
    endpointSource.update(_apns('eeff'));
    await Future<void>.delayed(Duration.zero);
    expect(transport.requests, isEmpty);
    await endpointSource.dispose();
  });
}

const _noDelay = <Duration>[Duration.zero, Duration.zero, Duration.zero];

FxPushEndpoint _apns(String token) => FxPushEndpoint(
      provider: FxPushProvider.apns,
      platform: FxPushPlatform.ios,
      token: token,
      apnsEnvironment: FxApnsEnvironment.sandbox,
    );

class MemorySecureStorage implements FxPushSecureStorage {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class BlockingReadStorage extends MemorySecureStorage {
  final Completer<void> readStarted = Completer<void>();
  final Completer<void> releaseRead = Completer<void>();
  var _blocked = false;

  @override
  Future<String?> read(String key) async {
    if (!_blocked) {
      _blocked = true;
      readStarted.complete();
      await releaseRead.future;
    }
    return super.read(key);
  }
}

class RecordingTransport implements FxPushSubscriptionTransport {
  RecordingTransport({this.disabledSubscriptionId = subscriptionId});

  static const subscriptionId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
  final String? disabledSubscriptionId;
  final List<FxPushSubscriptionRequest> requests =
      <FxPushSubscriptionRequest>[];

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async {
    requests.add(request);
    final active = request.body['active']! as bool;
    return FxPushSubscriptionResponse(
      subscriptionId: active ? subscriptionId : disabledSubscriptionId,
      revision: active
          ? '1'
          : disabledSubscriptionId == null
              ? '0'
              : '2',
      active: active,
    );
  }
}

class BlockingTransport extends RecordingTransport {
  final Completer<void> firstStarted = Completer<void>();
  final Completer<void> releaseFirst = Completer<void>();
  var concurrent = 0;
  var maxConcurrent = 0;

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async {
    concurrent++;
    if (concurrent > maxConcurrent) maxConcurrent = concurrent;
    if (!firstStarted.isCompleted) {
      firstStarted.complete();
      await releaseFirst.future;
    }
    final response = await super.synchronize(request);
    concurrent--;
    return response;
  }
}

class FailOnceTransport extends RecordingTransport {
  final Completer<void> failed = Completer<void>();
  var _shouldFail = true;

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async {
    requests.add(request);
    if (_shouldFail) {
      _shouldFail = false;
      failed.complete();
      throw const FxPushHttpException(statusCode: 503);
    }
    final active = request.body['active']! as bool;
    return FxPushSubscriptionResponse(
      subscriptionId: active ? RecordingTransport.subscriptionId : null,
      revision: active ? '1' : '0',
      active: active,
    );
  }
}

class AlwaysFailTransport implements FxPushSubscriptionTransport {
  AlwaysFailTransport(this.error);
  final Object error;
  int calls = 0;

  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async {
    calls++;
    throw error;
  }
}

class NullActiveSubscriptionTransport implements FxPushSubscriptionTransport {
  @override
  Future<FxPushSubscriptionResponse> synchronize(
    FxPushSubscriptionRequest request,
  ) async =>
      const FxPushSubscriptionResponse(
        subscriptionId: null,
        revision: '1',
        active: true,
      );
}
