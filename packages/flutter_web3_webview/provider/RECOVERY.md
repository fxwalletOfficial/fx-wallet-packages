# Provider bundle recovery notes

`lib/js/provider.min.js` was originally generated from a previously-modified
provider fork whose source modifications were lost. This document records
what was inferred from the minified bundle and how the bridge layer was
ported back into `provider/packages/` so the asset can be rebuilt from
source.

> **Status: resolved.** `lib/js/provider.min.js` is now built from this
> source tree — `bun run build:flutter` produces the ~321 KB esbuild bundle
> that replaced the legacy ~1.46 MB fork artifact. The Flutter bridge layer
> lives in source (`packages/core/adapter/FlutterBridge.ts` plus the
> per-package overrides), the unreachable `MobileAdapter` is off the request
> hot path (so the `@metamask/eth-sig-util` chain is no longer pulled in),
> and Solana `signTransaction` is serialised through an instance-level queue.
> Re-run `bun run build:packages && bun run build:flutter` to refresh the
> asset after a source change — the esbuild step bundles each package's
> `dist/` build, so the rollup step must run first.

## What the legacy bundle did differently from upstream

These are the behaviours observed in the *legacy* minified bundle (the lost
fork). They explain why the vendored source carries custom bridge code on top
of upstream; the current source reproduces the same wire protocol except
where noted.

### 1. Direct `window.flutter_inappwebview.callHandler` bridge

The legacy bundle bypasses the upstream `Adapter` / `IHandler` abstraction
and calls the WebView's JS handler directly. The call sites visible in the
minified output:

| Caller | Payload |
|--------|---------|
| Ethereum (generic) | `callHandler("FxWalletHandler", args)` — `args` is the DApp's `{ method, params }`. In the legacy bundle the method name was whatever `MobileAdapter` had rewritten it to (`requestAccounts`, `signTransaction`, `signPersonalMessage`, …); **the current source skips that rewrite** and forwards the original `eth_*` / `personal_*` / `wallet_*` names (see "Restored bridge" below). |
| Solana connect | `callHandler("FxWalletHandler", { method: "solana_account" })` |
| Solana `signMessage` | `callHandler("FxWalletHandler", { method: "solana_signMessage", params: { raw: hex } })` |
| Solana `signTransaction` | `callHandler("FxWalletHandler", { method: "solana_signTransaction", params: { raw: hex, message: base64 } })` |

### 2. Solana method-name and parameter rewrites

Upstream `SolanaProvider.signMessage` sends
`{ method: "signMessage", params: { data, originalMethod: "signMessage" } }`.
The legacy bundle instead sends
`{ method: "solana_signMessage", params: { raw: hex } }` — both a `solana_`
prefix and a renamed `data → raw` parameter. The `signTransaction` path
serialises the transaction message twice (`hex` *and* `base64`), which is not
how upstream's adapter packs it. The current source reproduces this exactly.

### 3. Solana methods that were not bridged

`signIn` / `signAndSendTransaction` exist in the upstream API but the legacy
bundle did not bridge them through `FxWalletHandler`. The Dart dispatcher
(`lib/src/utils/request_dispatcher.dart`) only handles `solana_account`,
`solana_signTransaction`, `solana_signMessage`, so this gap is largely
informational. `signRawTransactionMulti` (upstream-only, never shipped in the
legacy bundle, no Dart case) was removed from the current source to keep the
typed API honest — batch signing composes from `signTransaction` via
`signAllTransactions`.

## Restored bridge (current source)

The bridge layer ported back into the vendored source:

1. **`packages/core/adapter/FlutterBridge.ts`** — single shared helper that
   guards `window.flutter_inappwebview` (throwing `Not init finished.` to
   match the legacy error message) and invokes
   `callHandler('FxWalletHandler', payload)`. Re-exported from
   `packages/core/index.ts` as `callFlutterHandler` so neither chain package
   re-declares the global.
2. **`packages/ethereum/EthereumProvider.ts`**
   * `request(args)` → `internalRequest(args)` → `callFlutterHandler(args)`
     is a single-step pass-through: the DApp's `{ method, params }` reaches
     the Dart side **unmodified**. `MobileAdapter` is *not* on this path, so
     the Dart `Web3RequestDispatcher` switches on the original
     `eth_sendTransaction` / `personal_sign` / `eth_signTypedData_v4` /
     `wallet_switchEthereumChain` / `wallet_addEthereumChain` names. (The
     upstream design routed everything through `MobileAdapter`, which renamed
     these to `signTransaction` / `signPersonalMessage` / … — those would
     fall through to `_defaultCallback`. Dropping the adapter also keeps the
     `@metamask/eth-sig-util` dependency chain out of the bundle.)
   * `emitChainChanged(chainId)` and `emitAccountsChanged(accounts)` are
     public so the Dart side can fire EIP-1193 events after
     `wallet_switchEthereumChain` or an account switch (matching the
     `window.ethereum.emitChainChanged(...)` injection in
     `lib/src/utils/request_dispatcher.dart`).
3. **`packages/solana/SolanaProvider.ts`**
   * `isConnected` boolean field so DApps can sniff connection state.
   * `connect()` bridges to `{ method: 'solana_account' }`, sets `publicKey`
     / `isConnected`, and emits `connect`.
   * `disconnect()` clears `publicKey` / `isConnected` and emits `disconnect`.
   * `signMessage(message)` bridges to
     `{ method: 'solana_signMessage', params: { raw: hex } }`.
   * `signTransaction(tx)` serialises the transaction message (both legacy
     `Transaction` and `VersionedTransaction`) and bridges to
     `{ method: 'solana_signTransaction', params: { raw, message } }`, then
     attaches the returned signature via `mapSignedTransaction`. Calls are
     serialised through an instance-level `#signTransactionQueue` so a DApp
     issuing several at once (directly or via `signAllTransactions`) gets them
     approved one at a time instead of racing the single approval UI.
   * `emitAccountChanged()` exposed for the wallet-standard adapter and DApp
     listeners.
   * `internalRequest(args)` forwards any future un-bridged Solana request
     through the bridge unchanged.

### Surface verification (regenerated bundle vs legacy)

| Token | Legacy | New |
|-------|-------:|----:|
| `window.fxwallet` | ✓ | ✓ |
| `FxWalletHandler` | 5 | 1 (minifier dedupes) |
| `isFxWallet` | 8 | 8 |
| `'fxwallet:'` (wallet-standard namespace) | ✓ | ✓ |
| `wallet-standard:register-wallet` | ✓ | 3 |
| `emitChainChanged` | 2 | 1 |
| `emitAccountsChanged` | — | 1 (new) |
| `solana_account` | 1 | 1 |
| `solana_signTransaction` | 1 | 1 |
| `solana_signMessage` | 1 | 1 |
| `Not init finished` guard | 5 | 1 (minifier dedupes) |

`registerWallet` does not appear by name in the regenerated bundle because
esbuild's minifier renamed the local symbol — the dispatched event names
(`wallet-standard:register-wallet`, `wallet-standard:app-ready`) are present,
and that is the contract DApps observe.

The regenerated bundle was additionally smoke-tested on-device (Magic Eden
SIWS login over the Solana path). If you change the source again, re-verify
the wire payloads for `eth_accounts`, `eth_chainId`, `eth_requestAccounts`,
`personal_sign`, `eth_signTypedData_v4`, `eth_sendTransaction`,
`wallet_switchEthereumChain`, `wallet_addEthereumChain`, `solana_account`,
`solana_signMessage`, and `solana_signTransaction` against a representative
DApp set before shipping.

## Known gaps (deferred)

The legacy bundle added a few niceties that are **not** ported back because
they aren't required for the wire protocol:

* `EthereumProvider.setAddress` in the legacy fork lower-cased the address,
  set `provider.ready`, and mirrored state into `window.frames[*].ethereum`
  for iframes branded with `isFxWallet`. The vendored source keeps the
  upstream stub that just stores the private `#address`.
* The legacy `isConnected()` stub always returned `true`; the vendored source
  exposes a `connected` getter that does the same.
* `EthereumProvider.setConfig(config)` aggregate setter — not present.

These can be ported in a follow-up once a DApp is observed to depend on them.
