import 'dart:async';
import 'dart:collection';

/// Applies host-specific allow-list rules to a parsed deeplink.
typedef FxPushDeeplinkValidator = bool Function(Uri deeplink);

/// The lifecycle point at which a notification payload was delivered.
enum FxPushNotificationEventType {
  /// The host received the notification while the app was in the foreground.
  foregroundReceived,

  /// The user opened a notification while the app process was available.
  opened,

  /// The user opened a notification that cold-started the app process.
  initialOpen,
}

/// A provider-independent notification message.
class FxPushMessage {
  /// Creates an immutable provider-independent message.
  FxPushMessage({
    required this.title,
    required this.body,
    required this.eventId,
    required this.deeplink,
    required Map<String, String> data,
  }) : data = Map<String, String>.unmodifiable(data);

  /// Provider display title, when present.
  final String? title;

  /// Provider display body, when present.
  final String? body;

  /// Stable business event identifier used for open-event deduplication.
  final String? eventId;

  /// Parsed but not authorized deeplink supplied by the payload.
  final Uri? deeplink;

  /// Immutable string data supplied by the provider payload.
  final Map<String, String> data;
}

/// Describes a rejected notification payload field.
class FxPushMessageFormatException implements Exception {
  /// Creates a bounded field validation error.
  const FxPushMessageFormatException(this.field, this.reason);

  /// Dot-separated field name or payload section.
  final String field;

  /// Bounded explanation that does not include the rejected value.
  final String reason;

  @override
  String toString() => 'FxPushMessageFormatException($field: $reason)';
}

/// Decodes provider payloads into a provider-independent message.
///
/// APNs custom fields may be supplied at the payload root. FCM custom fields
/// must be supplied in `data`. Notification text is read from `aps.alert` or
/// `notification`. The host remains responsible for deciding whether a valid
/// deeplink is authorized for the current user and navigation state.
class FxPushMessageCodec {
  /// Creates a codec with configurable custom-data keys and URI validation.
  FxPushMessageCodec({
    this.eventIdKey = 'event_id',
    this.deeplinkKey = 'launchUrl',
    this.deeplinkValidator,
  }) {
    _validateConfiguredKey(eventIdKey, 'eventIdKey');
    _validateConfiguredKey(deeplinkKey, 'deeplinkKey');
    if (eventIdKey == deeplinkKey) {
      throw ArgumentError('eventIdKey and deeplinkKey must be different');
    }
  }

  /// Custom data key containing the stable business event identifier.
  final String eventIdKey;

  /// Custom data key containing the deeplink string.
  final String deeplinkKey;

  /// Optional host allow-list applied after URI parsing.
  final FxPushDeeplinkValidator? deeplinkValidator;

  static void _validateConfiguredKey(String value, String name) {
    if (value.isEmpty || value.length > 128) {
      throw ArgumentError.value(value, name, 'must be 1..128 characters');
    }
  }

  /// Decodes one APNs or normalized FCM payload.
  FxPushMessage decode(Map<Object?, Object?> payload) {
    final root = _stringKeyedMap(payload, 'payload');
    String? title;
    String? body;

    final apsValue = root['aps'];
    if (apsValue != null) {
      final aps = _stringKeyedMap(apsValue, 'aps');
      final alertValue = aps['alert'];
      if (alertValue is String) {
        body = _messageText(alertValue, 'aps.alert');
      } else if (alertValue != null) {
        final alert = _stringKeyedMap(alertValue, 'aps.alert');
        title = _optionalMessageText(alert['title'], 'aps.alert.title');
        body = _optionalMessageText(alert['body'], 'aps.alert.body');
      }
    }

    final notificationValue = root['notification'];
    if (notificationValue != null) {
      final notification = _stringKeyedMap(
        notificationValue,
        'notification',
      );
      title = _mergeText(
        title,
        _optionalMessageText(notification['title'], 'notification.title'),
        'title',
      );
      body = _mergeText(
        body,
        _optionalMessageText(notification['body'], 'notification.body'),
        'body',
      );
    }

    final data = <String, String>{};
    final nestedData = root['data'];
    if (nestedData != null) {
      final values = _stringKeyedMap(nestedData, 'data');
      for (final entry in values.entries) {
        _addData(data, entry.key, entry.value, 'data.${entry.key}');
      }
    }
    for (final entry in root.entries) {
      if (const <String>{'aps', 'notification', 'data'}.contains(entry.key)) {
        continue;
      }
      _addData(data, entry.key, entry.value, entry.key);
    }

    if (title == null && body == null && data.isEmpty) {
      throw const FxPushMessageFormatException(
        'payload',
        'must contain notification text or string data',
      );
    }

    final eventId = data[eventIdKey];
    if (eventId != null &&
        !RegExp(r'^[A-Za-z0-9._:-]{1,128}$').hasMatch(eventId)) {
      throw FxPushMessageFormatException(
        eventIdKey,
        'must match [A-Za-z0-9._:-]{1,128}',
      );
    }

    Uri? deeplink;
    final rawDeeplink = data[deeplinkKey];
    if (rawDeeplink != null) {
      deeplink = Uri.tryParse(rawDeeplink);
      if (deeplink == null ||
          !deeplink.hasScheme ||
          deeplink.userInfo.isNotEmpty) {
        throw FxPushMessageFormatException(
          deeplinkKey,
          'must be an absolute URI without user information',
        );
      }
      if (deeplinkValidator != null && !deeplinkValidator!(deeplink)) {
        throw FxPushMessageFormatException(
          deeplinkKey,
          'is not allowed by the host validator',
        );
      }
    }

    return FxPushMessage(
      title: title,
      body: body,
      eventId: eventId,
      deeplink: deeplink,
      data: data,
    );
  }

  static Map<String, Object?> _stringKeyedMap(Object value, String field) {
    if (value is! Map) {
      throw FxPushMessageFormatException(field, 'must be an object');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw FxPushMessageFormatException(
          field,
          'must use string keys',
        );
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  static String? _optionalMessageText(Object? value, String field) {
    if (value == null) return null;
    if (value is! String) {
      throw FxPushMessageFormatException(field, 'must be a string');
    }
    return _messageText(value, field);
  }

  static String _messageText(String value, String field) {
    if (value.isEmpty || value.length > 4096) {
      throw FxPushMessageFormatException(
        field,
        'must be 1..4096 characters',
      );
    }
    return value;
  }

  static String? _mergeText(
    String? current,
    String? incoming,
    String field,
  ) {
    if (current != null && incoming != null && current != incoming) {
      throw FxPushMessageFormatException(
        field,
        'conflicts between provider payload sections',
      );
    }
    return current ?? incoming;
  }

  static void _addData(
    Map<String, String> data,
    String key,
    Object? value,
    String field,
  ) {
    if (key.isEmpty || key.length > 128) {
      throw FxPushMessageFormatException(
        field,
        'key must be 1..128 characters',
      );
    }
    if (value is! String || value.length > 4096) {
      throw FxPushMessageFormatException(
        field,
        'must be a string of at most 4096 characters',
      );
    }
    final previous = data[key];
    if (previous != null && previous != value) {
      throw FxPushMessageFormatException(
        field,
        'conflicts with another payload section',
      );
    }
    data[key] = value;
  }
}

/// One normalized notification lifecycle event.
class FxPushNotificationEvent {
  /// Creates one normalized lifecycle event.
  const FxPushNotificationEvent({
    required this.type,
    required this.message,
    required this.occurredAt,
  });

  /// Where in the app lifecycle the payload was observed.
  final FxPushNotificationEventType type;

  /// Validated provider-independent message.
  final FxPushMessage message;

  /// Host observation time, stored without modification.
  final DateTime occurredAt;
}

/// Normalizes host-forwarded foreground, open, and cold-start events.
///
/// It does not register native callbacks, display notifications, open URLs, or
/// navigate. The host must forward its existing native/provider callbacks and
/// consume the resulting events in its own authenticated routing layer.
class FxPushNotificationBridge {
  /// Creates a bridge with a bounded process-local open-event history.
  FxPushNotificationBridge({
    FxPushMessageCodec? codec,
    this.openedEventHistoryLimit = 100,
  }) : codec = codec ?? FxPushMessageCodec() {
    if (openedEventHistoryLimit <= 0) {
      throw ArgumentError.value(
        openedEventHistoryLimit,
        'openedEventHistoryLimit',
        'must be positive',
      );
    }
  }

  /// Codec used for every forwarded payload.
  final FxPushMessageCodec codec;

  /// Maximum number of event IDs retained for open-event deduplication.
  final int openedEventHistoryLimit;
  final StreamController<FxPushNotificationEvent> _events =
      StreamController<FxPushNotificationEvent>.broadcast(sync: true);
  final LinkedHashSet<String> _openedEventIds = LinkedHashSet<String>();
  FxPushNotificationEvent? _initialOpen;
  bool _disposed = false;

  /// Foreground and non-initial open events forwarded by the host.
  Stream<FxPushNotificationEvent> get events => _events.stream;

  /// Decodes and emits a foreground receipt event.
  FxPushNotificationEvent handleForeground(
    Map<Object?, Object?> payload, {
    DateTime? occurredAt,
  }) {
    final event = _event(
      FxPushNotificationEventType.foregroundReceived,
      payload,
      occurredAt,
    );
    _events.add(event);
    return event;
  }

  /// Decodes and emits an open event unless its event ID was already opened.
  FxPushNotificationEvent? handleOpened(
    Map<Object?, Object?> payload, {
    DateTime? occurredAt,
  }) {
    final event = _event(
      FxPushNotificationEventType.opened,
      payload,
      occurredAt,
    );
    if (!_markOpened(event.message.eventId)) return null;
    _events.add(event);
    return event;
  }

  /// Stores the first cold-start event until [takeInitialOpen] is called.
  ///
  /// A duplicate event ID already recorded as opened is ignored. When no event
  /// ID is supplied, only the first initial event is retained.
  FxPushNotificationEvent? recordInitialOpen(
    Map<Object?, Object?> payload, {
    DateTime? occurredAt,
  }) {
    _checkNotDisposed();
    if (_initialOpen != null) return null;
    final event = _event(
      FxPushNotificationEventType.initialOpen,
      payload,
      occurredAt,
    );
    if (!_markOpened(event.message.eventId)) return null;
    _initialOpen = event;
    return event;
  }

  /// Removes and returns the retained cold-start event, if any.
  FxPushNotificationEvent? takeInitialOpen() {
    _checkNotDisposed();
    final event = _initialOpen;
    _initialOpen = null;
    return event;
  }

  FxPushNotificationEvent _event(
    FxPushNotificationEventType type,
    Map<Object?, Object?> payload,
    DateTime? occurredAt,
  ) {
    _checkNotDisposed();
    return FxPushNotificationEvent(
      type: type,
      message: codec.decode(payload),
      occurredAt: occurredAt ?? DateTime.now().toUtc(),
    );
  }

  bool _markOpened(String? eventId) {
    if (eventId == null) return true;
    if (!_openedEventIds.add(eventId)) return false;
    while (_openedEventIds.length > openedEventHistoryLimit) {
      _openedEventIds.remove(_openedEventIds.first);
    }
    return true;
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('FxPushNotificationBridge is disposed');
  }

  /// Releases event listeners and retained deduplication state.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _initialOpen = null;
    _openedEventIds.clear();
    await _events.close();
  }
}
