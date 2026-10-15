## Unreleased

### Added

- Optional `FxPushClient(installationId: ...)` to reuse the host application's
  stable installation ID in subscription requests and binding snapshots.
- Constructor validation and an initialization `StateError` for cached-ID
  conflicts, before any storage write or subscription request. Existing
  identity, credential, subscription, and desired state are preserved.
- Tests for restart compatibility, matching legacy IDs, token refresh, retry
  stability, invalid input, and conflicts without subscription changes.

Omitting the argument retains automatic identity generation and cached-ID
reuse. Installation authentication and business binding remain host-owned;
no business APIs or dependencies are added.

## 0.1.1

### Added

- Explicit, side-effect-free `FxPushClient.getBindingData()` returning an
  immutable `FxPushBindingData` with the subscription ID, installation ID, and
  registration key after a successful active synchronization.
- Returns no binding data before registration, during synchronization, while
  disabled, or after a failure; disposed calls throw the existing `StateError`.
- Redacted snapshot text output and explicit sensitive JSON encoding, with
  authenticated HTTPS backend handoff guidance and a host-owned example.

### Security and compatibility

- Credentials remain outside observable state and diagnostics. The trusted
  backend must verify the transient credential with its HMAC/read identity and
  separately authorize the business user or wallet before binding.
- Existing registration, synchronization, activation, state, and notification
  APIs are unchanged. No dependencies or backend verification calls are added.
- Snapshots can become stale; backend verification and real App/Backend
  integration remain required. First-registration claiming is unchanged.

## 0.1.0

Initial public release.

### Added

- Secure installation enrollment with stable installation and subscription
  identifiers through a host-provided Keychain/Keystore adapter.
- APNs and Android FCM endpoint synchronization over HTTPS, including token
  rotation, persisted enable/disable state, and startup/foreground refresh.
- Serialized latest-state retries for network failures, HTTP 429, and HTTP 5xx
  responses without replaying stale endpoint or activation state.
- Strict APNs and normalized FCM message decoding with immutable custom data,
  bounded fields, configurable event/deeplink keys, and host allow-listing.
- Provider-independent foreground, notification-open, and cold-start events
  with bounded event-ID deduplication.
- Typed synchronization phases and bounded protocol, HTTP, stored-state, and
  message-format errors.
- Read-only observable client state, strict persisted activation-state and APNs
  token validation, lifecycle-safe disposal during initialization, strict
  response invariants, and bounded subscription-service response bodies.
- Android and iOS package metadata, integration documentation, and a
  host-integration example.

### Security

- Registration credentials remain host-secured and are sent only as HTTPS
  bearer credentials to the configured service origin.
- The package never embeds backend HMAC secrets, provider service credentials,
  or navigation authority.
- Parsed deeplinks remain untrusted route hints; the host must authorize them
  against authenticated application state.
