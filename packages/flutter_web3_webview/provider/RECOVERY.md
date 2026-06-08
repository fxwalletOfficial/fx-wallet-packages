# Provider bundle recovery notes

The current `lib/js/provider.min.js` was generated from a previously-modified
fork of `trust-web3-provider`. Those source modifications were lost, so this
document tracks what was inferred from the minified bundle and what has /
has not been ported back into `provider/packages/`.

> **Status update (Phase 3 in progress):** the Flutter bridge layer described
> below has now been restored in source (`packages/core/adapter/FlutterBridge.ts`
> plus the per-package overrides). `bun run build:flutter` produces a bundle
> that contains every legacy surface token (`FxWalletHandler`,
> `emitChainChanged`, `solana_account`, `solana_signTransaction`,
> `solana_signMessage`, `Not init finished`, the `wallet-standard:register-wallet`
> events, …). The asset of record is still the legacy `provider.min.js`
> until **Phase 5** signs off the regenerated bundle against a real DApp
> regression set. Run `bun run build:flutter` locally to refresh
> `lib/js/provider.min.js` when you are ready to swap.

## What's in the legacy bundle but not in upstream source

### 1. Direct `window.flutter_inappwebview.callHandler` bridge

The legacy bundle bypasses the upstream `Adapter` / `IHandler` abstraction
and instead calls the WebView's JS handler directly. Four distinct call
sites are visible in the minified output:

| Caller | Payload |
|--------|---------|
| Ethereum bridge (generic) | `callHandler("FxWalletHandler", payload)` — `payload` is the `args` object from `internalRequest`, so the method name is whatever `MobileAdapter` rewrote it to (`requestAccounts`, `signTransaction`, `signPersonalMessage`, `signTypedMessage`, `ecRecover`, `watchAsset`, `addEthereumChain`, `switchEthereumChain`, …). |
| Solana connect | `callHandler("FxWalletHandler", { method: "solana_account" })` |
| Solana `signMessage` | `callHandler("FxWalletHandler", { method: "solana_signMessage", params: { raw: hex } })` |
| Solana `signTransaction` | `callHandler("FxWalletHandler", { method: "solana_signTransaction", params: { raw: message.toString("hex"), message: message.toString("base64") } })` |

### 2. Solana method-name and parameter rewrites

Upstream `SolanaProvider.signMessage` sends
`{ method: "signMessage", params: { data, originalMethod: "signMessage" } }`.
The legacy bundle instead sends
`{ method: "solana_signMessage", params: { raw: hex } }`. The fork therefore
introduced both a `solana_` prefix and a renamed `data → raw` parameter
shape. The `signTransaction` path serialises the transaction message twice
(`hex` *and* `base64`), which is not how upstream's adapter packs it.

### 3. Lost Solana methods

Methods like `signAllTransactions`, `signRawTransactionMulti`, `signIn`,
`signAndSendTransaction` exist in the upstream source but the legacy bundle
either does not bridge them or routes them through a different code path
that we have not yet traced. The Dart dispatcher
(`lib/src/utils/request_dispatcher.dart`) currently only handles
`solana_account`, `solana_signTransaction`, `solana_signMessage`, so the
gap is largely informational.

## Phase 3 — restored bridge

The bridge layer has been ported back into the vendored source:

1. **`packages/core/adapter/FlutterBridge.ts`** — single shared helper that
   guards `window.flutter_inappwebview` (throwing `Not init finished.` to
   match the legacy error message) and invokes
   `callHandler('FxWalletHandler', payload)`. Re-exported from
   `packages/core/index.ts` as `callFlutterHandler` so neither chain
   package has to re-declare the global.
2. **`packages/ethereum/EthereumProvider.ts`**
   * `internalRequest(args)` now forwards `args` through the bridge
     verbatim. `MobileAdapter` still performs the EIP-1193 → mobile
     method rewrites first, so the Dart dispatcher sees `requestAccounts`,
     `signTransaction`, `signPersonalMessage`, `signTypedMessage`,
     `ecRecover`, `watchAsset`, `wallet_addEthereumChain`,
     `wallet_switchEthereumChain`, etc.
   * `emitChainChanged(chainId)` and `emitAccountsChanged(accounts)` are
     exposed publicly so the Dart side can fire EIP-1193 events after
     `wallet_switchEthereumChain` or an account switch (matching the
     `window.ethereum.emitChainChanged(...)` injection in
     `lib/src/utils/request_dispatcher.dart`).
3. **`packages/solana/SolanaProvider.ts`**
   * `isConnected` boolean field added so DApps can sniff the connection
     state directly (matching the legacy bundle).
   * `connect()` now bridges to `{ method: 'solana_account' }`, sets
     `publicKey` / `isConnected`, and emits `connect`.
   * `disconnect()` clears `publicKey` / `isConnected` and emits
     `disconnect`.
   * `signMessage(message)` bridges to
     `{ method: 'solana_signMessage', params: { raw: hex } }`.
   * `signTransaction(tx)` serialises the transaction message (handling
     both legacy `Transaction` and `VersionedTransaction`) and bridges to
     `{ method: 'solana_signTransaction', params: { raw, message } }`,
     then attaches the returned signature via `mapSignedTransaction`.
   * `emitAccountChanged()` exposed for the wallet-standard adapter and
     DApp listeners.
   * `internalRequest(args)` forwards generic Solana requests through the
     bridge unchanged so any future method that doesn't have a bespoke
     wrapper still works.

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

`registerWallet` itself does not appear by name in the regenerated bundle
because esbuild's minifier renamed the local symbol — the dispatched
event names (`wallet-standard:register-wallet`, `wallet-standard:app-ready`)
are present and that is the contract DApps observe.

## Phase 5 — outstanding regression verification

Before the regenerated bundle replaces `lib/js/provider.min.js`:

1. Run the wallet against a representative DApp set (Uniswap V3, OpenSea,
   Aave on EVM; Jupiter, Drift on Solana) using **both** bundles.
2. Intercept every `window.flutter_inappwebview.callHandler('FxWalletHandler',
   …)` invocation and confirm the new bundle emits payloads byte-for-byte
   identical to the legacy bundle for: `eth_accounts`, `eth_chainId`,
   `eth_requestAccounts`, `personal_sign`, `eth_signTypedData_v4`,
   `eth_sendTransaction`, `wallet_switchEthereumChain`,
   `wallet_addEthereumChain`, `solana_account`, `solana_signMessage`,
   `solana_signTransaction`.
3. Bundle size: regenerated ≈ 2.95 MB vs legacy ≈ 1.46 MB. The growth is
   driven by the newer Solana / wallet-standard dependency tree esbuild
   pulls in. Confirm WebView cold-start latency is acceptable before
   shipping.

## Known gaps (deferred)

The legacy bundle also added the following niceties that are **not yet**
ported back because they aren't required for the wire protocol:

* `EthereumProvider.setAddress` lower-cases the address, sets
  `provider.ready`, and walks `window.frames[*].ethereum` to mirror the
  state into iframes branded with `isFxWallet`. The vendored source still
  has the upstream stub that just stores the private `#address`.
* `EthereumProvider.isConnected()` always-returns-true legacy stub.
* `EthereumProvider.setConfig(config)` aggregate setter.

These can be ported in a follow-up once a DApp is observed to depend on
them.
