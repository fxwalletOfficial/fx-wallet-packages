# fx_push_client

`fx_push_client` synchronizes one mobile installation with
`fx-push-service` through `POST /device/v1/subscriptions` and normalizes
host-forwarded notification payloads and open events.

The package supports Flutter on Android and iOS. It deliberately stays outside
provider SDK ownership: the host app supplies its APNs or FCM token and forwards
the provider callbacks it already receives.

## Installation

```sh
flutter pub add fx_push_client
```

```dart
import 'package:fx_push_client/fx_push_client.dart';
```

Requirements:

- Dart 3.3.4 or later;
- Flutter 3.22.0 or later;
- an Android or iOS host with its notification provider configured;
- a compatible `fx-push-service` HTTPS origin and public App ID;
- host-provided Keychain/Keystore-backed secure storage.

See the
[`example/main.dart`](https://github.com/fxwalletOfficial/fx-wallet-packages/blob/main/packages/fx_push_client/example/main.dart)
integration skeleton. It is analyzable and does not embed an endpoint, App ID,
token, or credential.

## Features and boundaries

`FxPushClient` owns the client-side subscription state machine:

- reuses a host-supplied installation ID or creates a UUID, and creates a
  32-byte random enrollment credential;
- persists identity, credential, desired active state, subscription ID, and
  revision through a host-provided secure-storage adapter;
- sends the complete current APNs or FCM state over HTTPS;
- serializes startup, foreground, token-change, environment-change, and manual
  synchronization;
- retries network errors, HTTP 429, and HTTP 5xx at most three times (2, 5,
  and 15 seconds), rebuilding every retry from the latest desired state;
- exposes the stable `subscriptionId`, revision, desired state, and sync phase;
- provides binding credentials only through an explicit `getBindingData()` call
  after a successful active synchronization, outside observable state.

`FxPushMessageCodec` and `FxPushNotificationBridge` provide a separate,
provider-independent message boundary. They validate APNs/FCM payload shapes,
extract notification text, string data, event IDs, and deeplinks, normalize
foreground/open/cold-start events, and suppress duplicate open events when an
event ID is present.

The package does **not** request notification permission, install a provider
SDK, replace native notification delegates, display notifications, open URLs,
navigate, send notifications, authorize business actions, or bind a
subscription to a business user.

## Configure

Use the service HTTPS origin and the product's public App ID. Never put backend
HMAC secrets, APNs `.p8` keys, Firebase service accounts, or SSM permissions in
the app.

Implement `FxPushSecureStorage` with Keychain on iOS and encrypted,
Keystore-backed storage on Android. Do not use SharedPreferences: the generated
registration key is a bearer credential.

For a host that already depends on `flutter_secure_storage`, the adapter is
only a key/value bridge (keep the host's reviewed Android/iOS options):

```dart
final class PushSecureStorageAdapter implements FxPushSecureStorage {
  const PushSecureStorageAdapter(this.storage);

  final FlutterSecureStorage storage;

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => storage.delete(key: key);
}
```

```dart
final endpointSource = FxPushEndpointSource();

final pushClient = FxPushClient(
  // Both values come from the host's reviewed environment configuration.
  serviceUrl: appConfig.pushServiceUrl,
  appId: appConfig.pushAppId,
  installationId: appInstallationId, // Optional: omit to generate a UUID.
  secureStorage: PushSecureStorageAdapter(walletSecureStorage),
  endpointSource: endpointSource,
);

// Do not block first paint while an unavailable network is being retried.
unawaited(pushClient.start());
```

`start()` registers a Flutter lifecycle observer and synchronizes on startup.
Every transition to `AppLifecycleState.resumed` synchronizes again.

The service URL must be an HTTPS origin without credentials, a path, query, or
fragment. The App ID must be a UUID. Invalid configuration fails before the
first network request.

If the app already owns a stable installation ID, pass it as `installationId`.
It must contain 1-128 ASCII letters, digits, underscores, or hyphens. The client
preserves it exactly, including case, and uses it for subscription requests,
observable state, and `getBindingData()`. An invalid argument throws
`ArgumentError` in the constructor before any storage or network work.

On first initialization, the supplied ID is persisted alongside a newly
generated `registration_key`. Restarts, provider-token refreshes, and retries
reuse that ID and key. Omitting the argument keeps the existing behavior:
reuse the cached ID, or generate a UUID when none is stored. A previously
supplied ID is also reused when a later client omits the argument.

If a supplied ID differs from the cached ID for this App ID, initialization
throws `StateError` and records it in `state.lastError` with phase `failed`.
The conflict is checked before any storage write or subscription request;
the cached identity, key, subscription, and desired active state are preserved.
Await `start()` and handle this error in the host's installation/migration flow.
The client does not replace an existing identity or migrate its subscription.
Reusing the App's ID does not authenticate the installation: installation
authentication and business binding remain host-app responsibilities.

## Supply the provider endpoint

The host remains responsible for notification permission and provider SDK or
native registration. Update the source after the current raw token and its
actual environment are known. APNs tokens must use their raw, even-length
hexadecimal representation:

```dart
endpointSource.update(
  FxPushEndpoint(
    provider: FxPushProvider.apns,
    platform: FxPushPlatform.ios,
    token: rawApnsToken,
    apnsEnvironment: FxApnsEnvironment.sandbox,
  ),
);
```

For Android FCM:

```dart
endpointSource.update(
  FxPushEndpoint(
    provider: FxPushProvider.fcm,
    platform: FxPushPlatform.android,
    token: fcmRegistrationToken,
  ),
);
```

Call `update` from the existing APNs registration callback or FCM token-refresh
listener. An APNs environment must come from the signed app/provisioning
context: simulator and development signing use `sandbox`; TestFlight and App
Store use `production`. Flutter build mode is not an APNs environment signal.

### Existing notification SDK boundary

Keep the host's existing notification SDK initialization, permission flow,
foreground display listener, click listener, and subscription observer. This
package does not call provider SDK APIs or change those handlers. Supply the raw
APNs/FCM token from the platform registration path; do not pass a third-party
subscription ID as the provider token. The same host callbacks may forward
their payloads to `FxPushNotificationBridge` as described below.

An FCM token must belong to the same Firebase project as the service-side
credential configured for this product. Merely obtaining a token from an SDK
does not verify that project/credential match.

The product backend must choose one delivery route for each business event.
Enabling this client does not authorize dual delivery, fall back to the other
route after an unknown result, or provide cross-channel deduplication.

## Parse messages and open events

Create one bridge at the same process-level composition boundary as the
subscription client. Configure an app-specific deeplink validator; parsing a
URI does not authorize navigation.

```dart
final notificationBridge = FxPushNotificationBridge(
  codec: FxPushMessageCodec(
    eventIdKey: 'event_id',
    deeplinkKey: 'launchUrl',
    deeplinkValidator: (uri) =>
        uri.scheme == appConfig.deeplinkScheme &&
        uri.host == 'notification' &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        uri.pathSegments.length == 1,
  ),
);
```

Forward the host's existing callbacks. Do not replace a native notification
delegate or provider SDK listener just to use this API:

```dart
notificationBridge.handleForeground(rawProviderPayload);
notificationBridge.handleOpened(rawProviderPayload);

// Record this before the Flutter router is ready. It is retained until taken.
notificationBridge.recordInitialOpen(coldStartPayload);
```

APNs custom data may be passed at the payload root alongside `aps`. For FCM,
pass a normalized map containing an optional `notification` object and a
string-to-string `data` object. Do not pass an entire SDK object containing
timestamps, platform objects, or other non-string metadata.

For example, normalize a Firebase Messaging `RemoteMessage` at the host
callback boundary:

```dart
Map<Object?, Object?> fxPushPayload(RemoteMessage message) =>
    <Object?, Object?>{
      if (message.notification case final notification?)
        'notification': <Object?, Object?>{
          'title': notification.title,
          'body': notification.body,
        },
      'data': message.data,
    };

FirebaseMessaging.onMessage.listen((message) {
  notificationBridge.handleForeground(fxPushPayload(message));
});
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  notificationBridge.handleOpened(fxPushPayload(message));
});

final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null) {
  notificationBridge.recordInitialOpen(fxPushPayload(initialMessage));
}
```

Consume open events in the authenticated host routing layer:

```dart
final eventSubscription = notificationBridge.events.listen((event) {
  if (event.type != FxPushNotificationEventType.opened) return;
  final deeplink = event.message.deeplink;
  if (deeplink != null) authenticatedRouter.open(deeplink);
});

final initialOpen = notificationBridge.takeInitialOpen();
if (initialOpen?.message.deeplink case final deeplink?) {
  authenticatedRouter.open(deeplink);
}
```

The bridge deduplicates open events only when the payload contains a valid
event ID. It does not deduplicate foreground receipt against a later click,
because those are different lifecycle events. A deeplink is an untrusted route
hint: reauthenticate and load authoritative business state from the backend
before showing sensitive details or performing an action.

Deduplication is process-local and bounded. It prevents duplicate provider
callbacks within the current process; it is not a durable cross-installation or
cross-channel business-event ledger.

## Enable, disable, and observe

```dart
await pushClient.setActive(false); // Persisted before the HTTP request.
await pushClient.setActive(true);

pushClient.state.addListener(() {
  final state = pushClient.state.value;
  updatePushStatus(state.phase, state.desiredActive); // Non-secret UI status.
});
```

Disabling sends only `app_id`, `installation_id`, and `active=false`. A first
disable may return `subscriptionId == null`. A failed disable remains the
desired state and is retried on the next foreground/start; an older queued
`active=true` body is never replayed as a retry.

Account logout/switch must remove the business binding separately; disabling
the device subscription is not a replacement for session revocation.

## Hand off binding credentials explicitly

An opaque subscription ID alone does not prove installation ownership. After
login and a successful active synchronization, explicitly obtain one immutable
snapshot for transient submission to the host's trusted business backend:

```dart
await pushClient.start();
final bindingData = pushClient.getBindingData();
if (bindingData != null) {
  // Host-owned HTTPS client, authenticated as the current business user.
  // Disable request-body logging, analytics, and crash-report capture.
  await authenticatedBackend.verifyAndBindPushSubscription(bindingData.toJson());
}
```

`FxPushBindingData` contains `subscriptionId`, `installationId`, and
`registrationKey` from the same installation. `toJson()` explicitly produces
`subscription_id`, `installation_id`, and `registration_key`; that map contains
a bearer secret. The snapshot's ordinary `toString()` is redacted. Never log
the object fields, JSON, HTTP body, or credential, and do not copy the credential
into business storage. Keep it in memory only for the HTTPS handoff; the SDK's
existing platform-backed storage remains its source of truth.

`getBindingData()` is synchronous and performs no storage access, enrollment,
network request, synchronization, or retry. It returns `null` until this client
has received and persisted a valid active subscription response, including
after restart with saved IDs. It also returns `null` while synchronizing,
waiting for an endpoint, disabled, or failed. Calls after `dispose()` throw
`StateError`, consistently with other client operations. A `start()` or
`synchronize()` future completing does not by itself prove success: transport
failures are recorded in observable state, so check the nullable snapshot.

The backend must authenticate the caller, use its own HMAC identity with
`read` permission to call Push Service's
[`POST /api/v1/subscriptions:verify`](https://github.com/fxwalletOfficial/fx-push-service/blob/develop/docs/integration/subscriptions.md#backend-校验订阅归属),
and separately authorize user/wallet binding. The three JSON fields above are
the verification request body. Only `verified=true` plus successful business
authorization permits binding; `verified=false`, timeouts, or errors must fail
closed. The backend must not persist the registration key or capture request
bodies. HMAC secrets, SSM access, and provider credentials stay in the backend;
this SDK does not call that endpoint.

The credential can update or disable this installation's subscription. A
snapshot is local evidence at the time of retrieval and can become stale after
a disable, disposal, account switch, or server-side change. Previously returned
objects are not revoked or cleared by the SDK; discard them promptly. Backend
verification checks a same-product/environment active subscription and matching
installation/credential at verification time. It does not prove physical-device,
native-token, user, or wallet ownership and does not handle first-registration
claiming. See `PushIntegration.submitBindingData` in the example for the
host-owned handoff boundary.

## State and error handling

`pushClient.state` exposes the current phase and the most recent error:

The returned `ValueListenable` is read-only; its lifecycle remains owned by the
client. Subscription transport failures are recorded as `failed` state after
bounded retries, while configuration, secure-storage initialization, and calls
made after disposal complete with an error.

| Phase | Meaning |
| --- | --- |
| `initializing` | Secure identity and persisted state are being loaded. |
| `waitingForEndpoint` | Active synchronization is waiting for an APNs/FCM token. |
| `synchronizing` | One HTTPS synchronization is in flight. |
| `retryScheduled` | A retryable failure is waiting for its bounded delay. |
| `synchronized` | The latest desired state was accepted by the service. |
| `failed` | A non-retryable error occurred or retry attempts were exhausted. |
| `disposed` | The client no longer accepts work. |

Network errors, timeouts, HTTP 429, and HTTP 5xx responses are retried at most
three times. Other HTTP responses, invalid service responses, corrupted stored
state, and invalid message payloads fail without hidden retries. Inspect typed
errors rather than parsing `toString()`:

- `FxPushHttpException` for non-200 HTTP responses;
- `FxPushProtocolException` for invalid successful responses;
- `FxPushStoredStateException` for invalid persisted values;
- `FxPushMessageFormatException` for rejected notification payloads.

The client rebuilds every retry from the latest token and desired active state.
It does not retry notification sends; sending is a backend responsibility.

Dispose the client and endpoint source with the process-level composition that
owns them:

```dart
await pushClient.dispose();
await endpointSource.dispose();
await eventSubscription.cancel();
await notificationBridge.dispose();
```

## Security and privacy

- Treat the registration key as a bearer credential and keep it in
  platform-backed secure storage. Explicit binding snapshots and their JSON
  are secret-bearing; use them only for transient authenticated HTTPS handoff
  to the trusted business backend, with no body logging or persistent copies.
- Treat provider tokens and subscription IDs as sensitive delivery addresses;
  do not log or include them in crash reports.
- Keep subscription-service responses bounded; the default transport rejects
  response bodies larger than 64 KiB.
- Keep backend HMAC secrets, APNs signing keys, Firebase service accounts, and
  cloud credentials out of the app.
- Validate deeplinks with an application-specific allow-list, then authorize
  the destination again using authenticated business state.
- Bind subscription IDs to users only in an authenticated backend flow.

## Compatibility and versioning

The `0.x` line is pre-stable. Breaking API changes may be released in a minor
version until `1.0.0`; applications should use a compatible version constraint
and read the changelog before upgrading. The wire contract remains specific to
the compatible `fx-push-service` subscription endpoint.

## Verification boundary

Package tests use in-memory storage, fake transports, and synthetic payloads.
They do not prove Keychain/Keystore behavior, native callback forwarding,
coexistence with an existing notification SDK, APNs or FCM delivery,
TestFlight/production environment selection, business-user binding, host
routing, or backend sending. Those require host-app and real-device acceptance.

Before releasing an application integration, verify at least token rotation,
enable/disable persistence, provider acceptance, foreground receipt,
background notification open, terminated-app initial open, deeplink rejection,
account switching, and logout/unbinding with the real host and backend. Verify
binding handoff, backend HMAC/read configuration, accepted and rejected ownership
checks, and request-body redaction as well. Service deployment and package tests
alone do not establish successful App/Backend integration.
