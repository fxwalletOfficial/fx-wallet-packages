# Provider bundle recovery notes

The current `lib/js/provider.min.js` was generated from a previously-modified
fork of `trust-web3-provider`. Those source modifications were lost, so this
document tracks what we have inferred from the minified bundle and what still
needs to be ported back into `provider/packages/` before the esbuild bundle
becomes equivalent to the ship-asset.

The Phase 2 build infrastructure (`bundle/index.ts` + `bundle/build.mjs`)
already produces a working IIFE, but the output is missing the Flutter
bridge layer described below. Until that layer is restored, the build is
**not** yet a drop-in replacement and the legacy `provider.min.js` is the
asset of record.

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

## Phase 3 work to make the new bundle equivalent

The minimal changes required on top of the vendored source:

1. **EthereumProvider.internalRequest** — override to forward the args
   directly to the WebView bridge:
   ```ts
   internalRequest<T>(args: IRequestArguments): Promise<T> {
     return (window as Window & {
       flutter_inappwebview: {
         callHandler: (handler: string, ...args: unknown[]) => Promise<unknown>;
       };
     }).flutter_inappwebview.callHandler('FxWalletHandler', args) as Promise<T>;
   }
   ```
   The upstream `MobileAdapter` keeps doing the EIP-1193 → mobile method
   rewrites; the bridge just transports the rewritten request.

2. **SolanaProvider Flutter bridge** — replace the three call sites
   (`connect`, `signMessage`, `signTransaction`) so they call
   `callHandler('FxWalletHandler', { method: 'solana_*', params: ... })`
   with the `raw` / `raw + message` parameter shapes documented above.
   Match the upstream method bodies for everything else.

3. **Match the Dart dispatcher** — confirm every method the Dart side
   (`request_dispatcher.dart`) routes for has a matching bridge call in
   the JS source so nothing falls through to `_defaultCallback`.

4. **Verify behaviour against a real DApp** — load both bundles in a
   WebView side-by-side, intercept the `callHandler` arguments for the
   core flows (connect / personal_sign / signTypedData / sendTransaction /
   switchChain / Solana sign), and confirm the payloads match byte-for-byte.

After Phase 3 lands, the build script (`bun run build:flutter`) should
produce a bundle that can replace the legacy asset without breaking any
DApp the wallet supports today.

## Surface inventory

Tokens currently present in the legacy bundle but absent from the
freshly-built bundle (`bun run build:flutter` against the current source):

| Token | Legacy occurrences | New occurrences |
|-------|-------------------:|----------------:|
| `FxWalletHandler` | 5 | 0 |
| `registerWallet` | 10 | 0 |
| `emitChainChanged` | 2 | 0 |
| `solana_signTransaction` | 1 | 0 |
| `solana_signMessage` | 1 | 0 |
| `solana_account` | 1 | 0 |

`registerWallet = 0` deserves a closer look — the wallet-standard
`registerWallet` import in `solana/adapter/register.ts` should survive
tree-shaking because `SolanaProvider`'s constructor calls
`initialize(this)`, which in turn calls `registerWallet`. Confirm the
chain is intact in the new bundle (it might just be inlined under a
minified name).
