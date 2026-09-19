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
  void updateIosApnsToken(
    String token,
    FxApnsEnvironment environment,
  ) {
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
  FxPushNotificationEvent onForeground(
    Map<Object?, Object?> payload,
  ) =>
      notifications.handleForeground(payload);

  /// Forwards a normalized notification-open payload.
  FxPushNotificationEvent? onOpened(
    Map<Object?, Object?> payload,
  ) =>
      notifications.handleOpened(payload);

  /// Records a notification that cold-started the application.
  FxPushNotificationEvent? onInitialOpen(
    Map<Object?, Object?> payload,
  ) =>
      notifications.recordInitialOpen(payload);

  /// Releases host-owned resources.
  Future<void> dispose() async {
    await notifications.dispose();
    await client.dispose();
    await endpoints.dispose();
  }
}
