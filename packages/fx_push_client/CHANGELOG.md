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
