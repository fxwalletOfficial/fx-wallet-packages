import 'dart:async';

/// Supported push delivery providers.
enum FxPushProvider {
  /// Apple Push Notification service.
  apns('apns'),

  /// Firebase Cloud Messaging.
  fcm('fcm');

  const FxPushProvider(this.wireName);

  /// Provider name used by the subscription wire protocol.
  final String wireName;
}

/// Supported mobile platforms.
enum FxPushPlatform {
  /// Apple iOS.
  ios('ios'),

  /// Google Android.
  android('android');

  const FxPushPlatform(this.wireName);

  /// Platform name used by the subscription wire protocol.
  final String wireName;
}

/// APNs delivery environments derived from the signed application.
enum FxApnsEnvironment {
  /// Development and simulator delivery.
  sandbox('sandbox'),

  /// TestFlight and App Store delivery.
  production('production');

  const FxApnsEnvironment(this.wireName);

  /// Environment name used by the subscription wire protocol.
  final String wireName;
}

/// The current provider address for this installation.
///
/// For APNs, [token] must be the raw APNs device token, not a third-party
/// subscription ID. The host is responsible for obtaining the token without
/// replacing its existing notification delegate or click/display handlers.
class FxPushEndpoint {
  /// Creates and validates one current provider endpoint.
  FxPushEndpoint({
    required this.provider,
    required this.platform,
    required this.token,
    this.apnsEnvironment,
  }) {
    if (token.isEmpty || token.length > 4096 || RegExp(r'\s').hasMatch(token)) {
      throw ArgumentError.value(
        token,
        'token',
        'must be 1..4096 non-whitespace characters',
      );
    }
    if (provider == FxPushProvider.apns) {
      if (platform != FxPushPlatform.ios || apnsEnvironment == null) {
        throw ArgumentError(
          'APNs requires platform=ios and an APNs environment',
        );
      }
      if (!RegExp(r'^(?:[a-fA-F0-9]{2})+$').hasMatch(token)) {
        throw ArgumentError.value(
          token,
          'token',
          'APNs tokens must be even-length hexadecimal strings',
        );
      }
    } else {
      if (platform != FxPushPlatform.android) {
        throw ArgumentError('FCM requires platform=android');
      }
      if (apnsEnvironment != null) {
        throw ArgumentError('FCM must not include an APNs environment');
      }
    }
  }

  /// Delivery provider.
  final FxPushProvider provider;

  /// Mobile platform paired with [provider].
  final FxPushPlatform platform;

  /// Raw provider registration token.
  final String token;

  /// Required APNs environment; absent for FCM.
  final FxApnsEnvironment? apnsEnvironment;

  /// Encodes the endpoint fields expected by the subscription service.
  Map<String, Object> toJson() => <String, Object>{
        'provider': provider.wireName,
        'platform': platform.wireName,
        'token': token,
        if (apnsEnvironment != null)
          'apns_environment': apnsEnvironment!.wireName,
      };

  @override
  bool operator ==(Object other) =>
      other is FxPushEndpoint &&
      other.provider == provider &&
      other.platform == platform &&
      other.token == token &&
      other.apnsEnvironment == apnsEnvironment;

  @override
  int get hashCode => Object.hash(provider, platform, token, apnsEnvironment);
}

/// Mutable bridge between a provider SDK/native hook and the client.
///
/// The host may update this from an APNs native registration callback or
/// Firebase Messaging's token refresh callback. It deliberately does not
/// initialize or dispose any provider SDK.
class FxPushEndpointSource {
  /// Creates a source with an optional already-known endpoint.
  FxPushEndpointSource([FxPushEndpoint? initialEndpoint])
      : _endpoint = initialEndpoint;

  FxPushEndpoint? _endpoint;
  final StreamController<FxPushEndpoint?> _changes =
      StreamController<FxPushEndpoint?>.broadcast(sync: true);

  /// Most recently supplied endpoint, or `null` while unavailable.
  FxPushEndpoint? get current => _endpoint;

  /// Endpoint changes after duplicate suppression.
  Stream<FxPushEndpoint?> get changes => _changes.stream;

  /// Replaces the current endpoint and emits it when it changed.
  void update(FxPushEndpoint? endpoint) {
    if (_endpoint == endpoint) return;
    _endpoint = endpoint;
    _changes.add(endpoint);
  }

  /// Closes the change stream.
  Future<void> dispose() => _changes.close();
}
