import 'package:fx_push_client/fx_push_client.dart';

/// Minimal host-owned composition for subscription and message events.
///
/// Supply environment configuration and platform-backed secure storage from
/// the application. This example intentionally does not own notification
/// permission, provider SDK initialization, display, or navigation.
final class PushIntegration {
  /// Creates a host-owned integration without starting network work.
  PushIntegration({
    required Uri serviceUrl,
    required String appId,
    required FxPushSecureStorage secureStorage,
    required FxPushDeeplinkValidator deeplinkValidator,
  }) {
    client = FxPushClient(
      serviceUrl: serviceUrl,
      appId: appId,
      secureStorage: secureStorage,
      endpointSource: endpoints,
    );
    notifications = FxPushNotificationBridge(
      codec: FxPushMessageCodec(deeplinkValidator: deeplinkValidator),
    );
  }

  /// Provider-token input owned by the host application.
  final FxPushEndpointSource endpoints = FxPushEndpointSource();

  /// Message bridge configured with the host application's URI allow-list.
  late final FxPushNotificationBridge notifications;

  /// Subscription state machine configured by the constructor.
  late final FxPushClient client;

  /// Starts subscription synchronization after host configuration is ready.
  Future<void> start() => client.start();

  /// Explicitly submits current binding credentials to the host's backend.
  ///
  /// Call only after login and an active synchronization. The supplied host
  /// callback must use HTTPS to the trusted business backend, disable request
  /// body logging/capture, and retain neither the snapshot nor its credential.
  /// The backend authenticates the caller, verifies with its own HMAC/read
  /// identity, and applies user/wallet authorization before storing a binding.
  /// Returns false when the client has no currently eligible snapshot. True
  /// means only that the host callback completed, not that binding is authorized.
  Future<bool> submitBindingData(
    Future<void> Function(FxPushBindingData data) submitToAuthenticatedBackend,
  ) async {
    final data = client.getBindingData();
    if (data == null) return false;
    await submitToAuthenticatedBackend(data);
    return true;
  }

  /// Supplies the latest Android FCM registration token.
  void updateAndroidFcmToken(String token) {
    endpoints.update(
      FxPushEndpoint(
        provider: FxPushProvider.fcm,
        platform: FxPushPlatform.android,
        token: token,
      ),
    );
  }

  /// Supplies the latest iOS APNs token and its signed environment.
  void updateIosApnsToken(String token, FxApnsEnvironment environment) {
    endpoints.update(
      FxPushEndpoint(
        provider: FxPushProvider.apns,
        platform: FxPushPlatform.ios,
        token: token,
        apnsEnvironment: environment,
      ),
    );
  }

  /// Forwards a normalized foreground provider payload.
  FxPushNotificationEvent onForeground(Map<Object?, Object?> payload) =>
      notifications.handleForeground(payload);

  /// Forwards a normalized notification-open payload.
  FxPushNotificationEvent? onOpened(Map<Object?, Object?> payload) =>
      notifications.handleOpened(payload);

  /// Records a notification that cold-started the application.
  FxPushNotificationEvent? onInitialOpen(Map<Object?, Object?> payload) =>
      notifications.recordInitialOpen(payload);

  /// Releases host-owned resources.
  Future<void> dispose() async {
    await notifications.dispose();
    await client.dispose();
    await endpoints.dispose();
  }
}
