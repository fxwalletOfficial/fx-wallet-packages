## [1.1.0]

Provider requests gain an identity and can be cancelled. A wallet that
switches account, changes chain or tears down a document can now terminate
requests already queued behind a pending approval, instead of letting them
reach the signer under state they were never authorized against. Every change
below is additive — existing hosts compile and behave as before.

### Request identity and cancellation

* NEW: The in-page bridge mints an id per request (`fxw<random>-<counter>`)
  and the Dart queue tracks it, so a host can correlate a request with its
  in-page promise and address it by id. `JsCallBackData` gains an optional
  named `id`; `method` / `params` keep their positions and defaults. A payload
  without an id (a DApp calling `callHandler` directly, or an older injected
  bundle) runs under a synthetic `local:<n>` id and stays cancellable. An id
  the page replays while it is still in flight — and the empty string — is
  rejected in favour of a synthetic one, so `cancel(id)` cannot be misdirected.
* NEW: `Web3RequestController` — host-side handle onto the queue. Pass one to
  `Web3Webview(requestController: ...)` to inspect what is in flight
  (`requests` / `activeId` / `pendingLength`) and cancel by id (`cancel` /
  `cancelAll`). It exposes mechanism only; *when* to cancel stays a wallet
  policy decision. Safe no-op while unattached.
* NEW: Cancellation is cooperative, deliberately. A request that has not
  started is dropped and fails with `4900` without ever entering the host
  callback. A request already executing is only flagged — never
  force-completed, because completing it would let the queue advance while a
  signing or broadcast call is still running. Callbacks observe the flag via
  `Web3RequestContext.throwIfCancelled()`, which travels through a Zone, so no
  callback signature changed. **Consumers must place checkpoints before
  signing, not after**: a callback that never checks runs to completion.
* NEW: `4900` (disconnected) rather than `4001` for wallet-initiated
  cancellation — `4001` means the *user* rejected, which is a different fact.
* NEW: Queue depth is bounded by `Web3Webview(maxPendingRequests:)`, default
  32, rejecting overflow with `-32005`. A fail-closed finite value rather than
  unbounded, so a page cannot flood the bridge.
* NEW: Each queued request is tagged with its chain family
  (`Web3RequestFamily.evm` / `.solana`), derived from the same routing table
  the dispatcher uses. Hosts filtering by chain read
  `Web3RequestInfo.family` instead of re-parsing method names, so the
  classification cannot drift from the dispatcher's.

### API surface

* NEW: `Web3RpcError.unauthorized()` (`4100`),
  `Web3RpcError.requestUnavailable()` (`-32002`) and `Web3RpcError.internal()`
  (`-32603`), joining `cancelled()` (`4900`) and `limitExceeded()` (`-32005`).
  Wallet hosts were maintaining their own copy of this error type because the
  wallet-facing codes were missing; the sentinel and JSON wire format the
  injected bridge parses are unchanged.
* NEW: Export `SerialEventQueue` and the `SerialEvent` typedef. They are the
  parameter types of the already-exported `Web3RequestController.attach` /
  `detach`, so a host binding its own queue previously had to import
  `package:flutter_web3_webview/src/...` and silence
  `implementation_imports`.

### Build

* `provider.min.js` rebuilt with the dependency set the repo currently
  resolves (328,835 → 319,868 bytes). Sources unchanged; the diff is entirely
  minifier identifier renaming, isolated into its own commit so later bundle
  diffs show only their own delta.
* Provider spec directories get editor-only TypeScript projects (`noEmit`,
  `types: ["bun"]`) so the language service can resolve `bun:test`; the build
  projects keep their exclusions. `moduleResolution` renamed `node` →
  `node10` at the provider root, removing the `ignoreDeprecations` entries it
  had forced. Bundle byte-identical.

## [1.0.0]

First stable release. The injected Web3 provider is now built from vendored
TypeScript source (`provider/`) instead of a lost pre-compiled artifact, and
the EVM / Solana request pipeline has been hardened end-to-end.

### Provider

* NEW: `lib/js/provider.min.js` is generated from the vendored `provider/`
  source via `bun run build:flutter` (**321 KB**, down from the legacy
  ~1.46 MB bundle). Dropping the unreachable `MobileAdapter` from
  `EthereumProvider` / `SolanaProvider` cuts the `@metamask/eth-sig-util`
  dependency chain and fixes a latent issue where the adapter renamed EVM
  methods (`eth_sendTransaction → signTransaction`, etc.) that the Dart
  dispatcher doesn't recognise. DApp-facing surface is unchanged (verified
  against the legacy bundle).
* NEW: Serialize Solana `signTransaction` inside the provider. Concurrent
  calls (directly or via `signAllTransactions`) run one at a time through an
  instance-level promise queue, so a DApp can't race the wallet's single
  approval UI; a rejected signature does not wedge the queue. This replaces
  the host-app userscript that previously monkey-patched the behaviour onto
  the provider at runtime.

### Fixes

* SECURITY: Deny WebView permission requests by default unless the caller
  provides an explicit permission handler.
* Handle `wallet_addEthereumChain` separately from
  `wallet_switchEthereumChain` via a new `walletAddEthereumChain` callback:
  per EIP-3085 it registers the chain and resolves with `null` without
  switching the active chain or emitting `chainChanged`. With no add handler
  it rejects with `4200` (unsupported method) rather than falling back to a
  switch, so an add request never silently changes the active network.
* Return `null` from a successful `wallet_switchEthereumChain` per EIP-3326
  (it previously resolved with the chain id, which strict DApps treat as a
  protocol mismatch).
* Stop advertising the Solana wallet-standard `signAndSendTransaction` and
  `signIn` features: the provider has no default broadcast RPC and SIWS isn't
  bridged, so advertising them led DApps into a guaranteed runtime failure
  (`signAndSendTransaction` threw on an uninitialised connection, `signIn`
  always threw `Method not implemented.`). DApps now fall back to
  `signTransaction` / `connect` + `signMessage`.
* Fix the legacy synchronous `_send`: `net_version` / `eth_chainId` no longer
  return the accounts array, and `getNetworkVersion`'s method name no longer
  carries a stray trailing space. The pass-through provider doesn't cache the
  chain id, so these synchronous calls now throw `4200` pointing callers at
  the async `request` API.
* Always emit the EIP-6963 `announceProvider` event, even when
  `window.ethereum` already exists — the previous early-return suppressed the
  announcement and broke multi-provider coexistence. The injected script now
  guards re-initialisation on `fxwallet.ethereum` and only claims
  `window.ethereum` when it is free.
* Default the EIP-6963 announcement metadata to valid values — a built-in
  data-URI `icon` and a reverse-DNS `rdns` (both overridable via
  `Web3EthSettings`) — instead of empty strings that strict DApps reject.
* Surface EIP-1193 `4001` (user rejected) instead of the invalid `4092` code
  when a chain switch is declined, and reject `wallet_switchEthereumChain`
  with `4902` for any chain id that is missing or is not a `0x`-prefixed hex
  string (previously `'1'`, `'0xzz'`, `' 0x1 '` and similar values still
  reached the wallet callback).
* Surface structured EIP-1193 errors to DApps. The Dart side throws
  `Web3RpcError`; the injected provider bridge parses its `Web3RpcError: `
  sentinel out of the wrapped rejection string and re-throws a real
  `ProviderRpcError` carrying `code` / `message` / `data`, so DApps can branch
  on `error.code` (e.g. `4902` → `wallet_addEthereumChain`).
* Add `Web3EthSettings.overwriteMetamask` (default `false`). Previously
  `window.ethereum.isMetaMask` was permanently `false` because the value was
  injected under a config field the provider never read — breaking DApps
  that gate signing on it (e.g. the MetaMask test dapp).
* Back `JsTransactionObject` fields with the underlying raw map so setting a
  typed field to `null` actually clears the value (was leaking the original
  DApp value through `toJson()`), while preserving DApp-provided fields like
  `nonce` / `maxFeePerGas` / numeric `gas`.
* JSON-encode wallet metadata before injecting it into JavaScript.
* Share provider asset loading across concurrent initialization calls.
* Serialize user-confirmed EVM and Solana requests and safely encode chain
  change events.
* Respect `isWeb3` when injecting provider scripts and forward Ajax
  ready-state callbacks.

## [0.1.0]

* NEW: Initial Release.

## [0.1.1]

* UPDATE: Inject provider at document start.

## [0.1.2]

* UPDATE: Init provider js before use.
* UPDATE: Update README.md for use.

## [0.1.3]

* FIX: Return full data for personal sign.

## [0.1.4]

* UPDATE: Add event queueing logic.

## [0.1.5]

* FIX: Optimized logic for error catching in events.
