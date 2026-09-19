import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'endpoint.dart';
import 'http_transport.dart';
import 'storage.dart';

/// Subscription synchronization lifecycle phases.
enum FxPushSyncPhase {
  /// Persisted identity and desired state are loading.
  initializing,

  /// An active subscription is waiting for a provider endpoint.
  waitingForEndpoint,

  /// A subscription request is in flight.
  synchronizing,

  /// A retryable failure is waiting for its next attempt.
  retryScheduled,

  /// The service accepted the latest complete desired state.
  synchronized,

  /// A terminal failure occurred or retry attempts were exhausted.
  failed,

  /// The client has been disposed.
  disposed,
}

/// Immutable observable state for one [FxPushClient].
class FxPushState {
  /// Creates an explicit state snapshot.
  const FxPushState({
    required this.phase,
    this.installationId,
    this.subscriptionId,
    this.revision,
    this.desiredActive = true,
    this.endpoint,
    this.lastError,
  });

  /// Creates the state used before secure initialization finishes.
  const FxPushState.initial() : this(phase: FxPushSyncPhase.initializing);

  /// Current synchronization phase.
  final FxPushSyncPhase phase;

  /// Stable installation identifier after initialization.
  final String? installationId;

  /// Stable service subscription identifier when one exists.
  final String? subscriptionId;

  /// Latest service revision.
  final String? revision;

  /// Persisted desired active state.
  final bool desiredActive;

  /// Most recently observed provider endpoint.
  final FxPushEndpoint? endpoint;

  /// Most recent synchronization or stored-state error.
  final Object? lastError;

  /// Returns a state snapshot with selected fields replaced or cleared.
  FxPushState _copyWith({
    FxPushSyncPhase? phase,
    String? installationId,
    String? subscriptionId,
    bool clearSubscriptionId = false,
    String? revision,
    bool? desiredActive,
    FxPushEndpoint? endpoint,
    bool clearEndpoint = false,
    Object? lastError,
    bool clearLastError = false,
  }) =>
      FxPushState(
        phase: phase ?? this.phase,
        installationId: installationId ?? this.installationId,
        subscriptionId:
            clearSubscriptionId ? null : subscriptionId ?? this.subscriptionId,
        revision: revision ?? this.revision,
        desiredActive: desiredActive ?? this.desiredActive,
        endpoint: clearEndpoint ? null : endpoint ?? this.endpoint,
        lastError: clearLastError ? null : lastError ?? this.lastError,
      );
}

/// Indicates that a persisted client field failed validation.
class FxPushStoredStateException implements Exception {
  /// Creates an error naming only the invalid field.
  const FxPushStoredStateException(this.field);

  /// Invalid persisted field name; the rejected value is not retained.
  final String field;

  @override
  String toString() => 'FxPushStoredStateException(invalid $field)';
}

/// Coordinates this installation's subscription with fx-push-service.
///
/// This class owns neither notification permissions nor provider SDK lifecycle.
/// It does not display notifications, open URLs, navigate, send notifications,
/// or alter an existing notification SDK's state. The package's notification
/// bridge can normalize payloads forwarded by the host's existing callbacks.
class FxPushClient with WidgetsBindingObserver {
  /// Creates a subscription client for one public App ID and service origin.
  FxPushClient({
    required Uri serviceUrl,
    required String appId,
    required FxPushSecureStorage secureStorage,
    required FxPushEndpointSource endpointSource,
    FxPushSubscriptionTransport? transport,
    List<Duration> retryDelays = const <Duration>[
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 15),
    ],
  })  : _appId = _validateAppId(appId),
        _storage = secureStorage,
        _endpointSource = endpointSource,
        _transport = transport ?? FxPushHttpTransport(serviceUrl: serviceUrl),
        _retryDelays = List<Duration>.unmodifiable(retryDelays) {
    if (_retryDelays.length != 3 ||
        _retryDelays.any((delay) => delay.isNegative)) {
      throw ArgumentError.value(
        retryDelays,
        'retryDelays',
        'must contain exactly three non-negative delays',
      );
    }
  }

  final String _appId;
  final FxPushSecureStorage _storage;
  final FxPushEndpointSource _endpointSource;
  final FxPushSubscriptionTransport _transport;
  final List<Duration> _retryDelays;

  final ValueNotifier<FxPushState> _state = ValueNotifier<FxPushState>(
    const FxPushState.initial(),
  );

  /// Read-only observable latest state. It is disposed with this client.
  ValueListenable<FxPushState> get state => _state;

  Future<void>? _initialization;
  Future<void>? _drainFuture;
  StreamSubscription<FxPushEndpoint?>? _endpointSubscription;
  Completer<void>? _retryWake;
  late String _installationId;
  late String _registrationKey;
  bool _desiredActive = true;
  bool _started = false;
  bool _syncRequested = false;
  bool _disposed = false;

  static String _validateAppId(String value) {
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value)) {
      throw ArgumentError.value(value, 'appId', 'must be a UUID');
    }
    return value.toLowerCase();
  }

  String get _storagePrefix => 'fx_push_client.v1.$_appId.';
  String _key(String suffix) => '$_storagePrefix$suffix';

  /// Starts endpoint and app-lifecycle observation and performs the initial
  /// synchronization. Calling this more than once is safe.
  Future<void> start() async {
    _checkNotDisposed();
    await _initialize();
    _checkNotDisposed();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addObserver(this);
      _endpointSubscription = _endpointSource.changes.listen((endpoint) {
        _setState(
          _state.value._copyWith(
            endpoint: endpoint,
            clearEndpoint: endpoint == null,
          ),
        );
        _synchronizeInBackground();
      });
    }
    await synchronize();
  }

  /// Persists the desired state before attempting the network request.
  ///
  /// A failed disable therefore remains disabled across retries and restarts.
  Future<void> setActive(bool active) async {
    _checkNotDisposed();
    await _initialize();
    _checkNotDisposed();
    await _storage.write(_key('desired_active'), active.toString());
    _checkNotDisposed();
    _desiredActive = active;
    _setState(
      _state.value._copyWith(desiredActive: active, clearLastError: true),
    );
    if (!_started) {
      await start();
    } else {
      await synchronize();
    }
  }

  /// Queues a serialized synchronization using the latest desired state and
  /// endpoint. Concurrent calls share the same drain operation.
  Future<void> synchronize() async {
    _checkNotDisposed();
    await _initialize();
    _checkNotDisposed();
    _syncRequested = true;
    final wake = _retryWake;
    if (wake != null && !wake.isCompleted) wake.complete();
    final current = _drainFuture;
    if (current != null) return current;
    final drain = _drain();
    _drainFuture = drain;
    try {
      await drain;
    } finally {
      if (identical(_drainFuture, drain)) _drainFuture = null;
    }
  }

  Future<void> _initialize() => _initialization ??= _loadIdentityAndState();

  Future<void> _loadIdentityAndState() async {
    try {
      _installationId = await _readOrCreate(
        'installation_id',
        _newInstallationId,
      );
      _registrationKey = await _readOrCreate(
        'registration_key',
        () => _randomHex(32),
      );
      if (!RegExp(r'^[A-Za-z0-9_-]{1,128}$').hasMatch(_installationId)) {
        throw const FxPushStoredStateException('installation_id');
      }
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(_registrationKey)) {
        throw const FxPushStoredStateException('registration_key');
      }
      final savedActive = await _storage.read(_key('desired_active'));
      if (savedActive == null) {
        _desiredActive = true;
        await _storage.write(_key('desired_active'), 'true');
      } else if (savedActive == 'true') {
        _desiredActive = true;
      } else if (savedActive == 'false') {
        _desiredActive = false;
      } else {
        throw const FxPushStoredStateException('desired_active');
      }
      final subscriptionId = await _storage.read(_key('subscription_id'));
      final revision = await _storage.read(_key('revision'));
      if (subscriptionId != null && !_isUuid(subscriptionId)) {
        throw const FxPushStoredStateException('subscription_id');
      }
      if (revision != null &&
          !RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(revision)) {
        throw const FxPushStoredStateException('revision');
      }
      final endpoint = _endpointSource.current;
      _setState(
        FxPushState(
          phase: _desiredActive && endpoint == null
              ? FxPushSyncPhase.waitingForEndpoint
              : FxPushSyncPhase.initializing,
          installationId: _installationId,
          subscriptionId: subscriptionId,
          revision: revision,
          desiredActive: _desiredActive,
          endpoint: endpoint,
        ),
      );
    } catch (error) {
      _setState(
        _state.value._copyWith(
          phase: FxPushSyncPhase.failed,
          lastError: error,
        ),
      );
      rethrow;
    }
  }

  Future<String> _readOrCreate(String suffix, String Function() create) async {
    final key = _key(suffix);
    final saved = await _storage.read(key);
    if (saved != null && saved.isNotEmpty) return saved;
    final value = create();
    await _storage.write(key, value);
    return value;
  }

  Future<void> _drain() async {
    var retryIndex = 0;
    while (_syncRequested && !_disposed) {
      _syncRequested = false;
      final endpoint = _endpointSource.current;
      if (_desiredActive && endpoint == null) {
        retryIndex = 0;
        _setState(
          _state.value._copyWith(
            phase: FxPushSyncPhase.waitingForEndpoint,
            clearEndpoint: true,
            clearLastError: true,
          ),
        );
        continue;
      }

      final body = <String, Object>{
        'app_id': _appId,
        'installation_id': _installationId,
        'active': _desiredActive,
        if (_desiredActive) ...endpoint!.toJson(),
      };
      _setState(
        _state.value._copyWith(
          phase: FxPushSyncPhase.synchronizing,
          endpoint: endpoint,
          clearEndpoint: endpoint == null,
          clearLastError: true,
        ),
      );

      try {
        final response = await _transport.synchronize(
          FxPushSubscriptionRequest(
            registrationKey: _registrationKey,
            body: body,
          ),
        );
        if (response.subscriptionId != null &&
                !_isUuid(response.subscriptionId!) ||
            !RegExp(r'^(0|[1-9][0-9]*)$').hasMatch(response.revision)) {
          throw const FxPushProtocolException(
            'subscription response contains invalid fields',
          );
        }
        if (response.active != body['active']) {
          throw const FxPushProtocolException(
            'subscription response active state does not match the request',
          );
        }
        final revisionIsZero = response.revision == '0';
        if (response.subscriptionId == null
            ? response.active || !revisionIsZero
            : revisionIsZero) {
          throw const FxPushProtocolException(
            'subscription response ID and revision are inconsistent',
          );
        }
        if (response.subscriptionId == null) {
          await _storage.delete(_key('subscription_id'));
        } else {
          await _storage.write(
            _key('subscription_id'),
            response.subscriptionId!,
          );
        }
        await _storage.write(_key('revision'), response.revision);
        retryIndex = 0;
        _setState(
          _state.value._copyWith(
            phase: FxPushSyncPhase.synchronized,
            subscriptionId: response.subscriptionId,
            clearSubscriptionId: response.subscriptionId == null,
            revision: response.revision,
            clearLastError: true,
          ),
        );
      } catch (error) {
        if (_isRetryable(error) && retryIndex < _retryDelays.length) {
          if (_syncRequested) {
            // The in-flight request failed after a newer endpoint or desired
            // state arrived. Rebuild immediately instead of delaying the newer
            // state behind an obsolete retry body.
            retryIndex = 0;
            continue;
          }
          var delay = _retryDelays[retryIndex++];
          if (error is FxPushHttpException &&
              error.retryAfter != null &&
              error.retryAfter! > delay) {
            delay = error.retryAfter!;
          }
          _setState(
            _state.value._copyWith(
              phase: FxPushSyncPhase.retryScheduled,
              lastError: error,
            ),
          );
          _retryWake = Completer<void>();
          await Future.any<void>(<Future<void>>[
            Future<void>.delayed(delay),
            _retryWake!.future,
          ]);
          _retryWake = null;
          _syncRequested = true;
        } else {
          retryIndex = 0;
          _setState(
            _state.value._copyWith(
              phase: FxPushSyncPhase.failed,
              lastError: error,
            ),
          );
        }
      }
    }
  }

  static bool _isRetryable(Object error) =>
      error is IOException ||
      error is TimeoutException ||
      error is FxPushHttpException && error.isRetryable;

  static bool _isUuid(String value) => RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(value);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_disposed) {
      _synchronizeInBackground();
    }
  }

  void _synchronizeInBackground() {
    if (_disposed) return;
    unawaited(_synchronizeForLifecycle());
  }

  Future<void> _synchronizeForLifecycle() async {
    try {
      await synchronize();
    } catch (error, stackTrace) {
      if (!_disposed) Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _setState(FxPushState next) {
    if (!_disposed) _state.value = next;
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('FxPushClient is disposed');
  }

  static String _newInstallationId() {
    final bytes = _secureBytes(16);
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  static String _randomHex(int byteCount) => _secureBytes(byteCount)
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  static List<int> _secureBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  /// Stops lifecycle observation, cancels retries, and disposes [state].
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    if (_started) WidgetsBinding.instance.removeObserver(this);
    await _endpointSubscription?.cancel();
    final wake = _retryWake;
    if (wake != null && !wake.isCompleted) wake.complete();
    _state.value = _state.value._copyWith(phase: FxPushSyncPhase.disposed);
    _state.dispose();
  }
}
