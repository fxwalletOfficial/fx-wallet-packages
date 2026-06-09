# FxWallet Web3 Provider (vendored)

This directory holds the TypeScript source for the JavaScript bundle that
`flutter_web3_webview` injects into every `InAppWebView`. The bundle exposes
the `window.fxwallet` global so DApps can talk to the wallet through
EIP-1193 and the Solana wallet standard.

## Layout

```
packages/
  core/       # base provider + the shared Flutter bridge (callFlutterHandler)
  ethereum/   # EIP-1193 EthereumProvider
  solana/     # SolanaProvider + wallet-standard adapter
bundle/
  index.ts    # aggregator entry — assigns the providers to window.fxwallet
  build.mjs   # esbuild bundle → ../lib/js/provider.min.js
scripts/
  build.ts    # iterate workspaces, run each per-package build
  packages.ts # list of allowed sub-packages
```

The source carries the FxWallet brand throughout (the `window.fxwallet`
global, the `'fxwallet:'` Solana wallet-standard namespace, the `isFxWallet`
feature flag, …). The chains we don't expose through the WebView, the native
wrappers, and the npm-publishing / chain-scaffolding tooling we don't use
have been removed. `MobileAdapter` is left vendored under `packages/ethereum`
/ `packages/solana` for reference, but is kept off the request hot path —
both providers forward requests straight through the bridge, so the Dart
`Web3RequestDispatcher` switches on the original EIP-1193 / `solana_*` method
names rather than the adapter's rewrites.

## Build workflow

```bash
bun install
bun run build:packages   # rollup each package's TS source into its dist/
bun run build:flutter    # esbuild-bundle the dist/ outputs into ../lib/js/provider.min.js
```

> ⚠️ Run `build:packages` **before** `build:flutter`. Each sub-package's
> `package.json` resolves to its rollup `dist/` output, and `bundle/index.ts`
> imports `EthereumProvider` / `SolanaProvider` through those package entry
> points — so `build:flutter` bundles the `dist/` artifacts, **not** the
> `.ts` sources directly. After editing any `.ts` file you must re-run
> `build:packages` first, otherwise the change won't reach
> `provider.min.js`.

`bundle/index.ts` is the aggregator entry point; it imports
`EthereumProvider` and `SolanaProvider` (via their package `dist/` builds)
and assigns them to `window.fxwallet`. `bundle/build.mjs` invokes esbuild
with Node-builtin polyfills (Buffer / events / crypto / http / https /
stream / url / util / zlib) and writes the IIFE bundle to the
`flutter_web3_webview` asset path, so a successful build refreshes the
Flutter package in place.

> `lib/js/provider.min.js` is built from this source tree — the ~321 KB
> bundle currently shipped was produced by `bun run build:flutter`. See
> [RECOVERY.md](./RECOVERY.md) for how the WebView bridge was recovered from
> the now-lost fork and how the regenerated bundle was verified against the
> legacy artifact.

## Requirements

* [Bun](https://bun.sh) for the per-package rollup build.
* Node ≥ 18 for the esbuild bundle (`bundle/build.mjs`).
