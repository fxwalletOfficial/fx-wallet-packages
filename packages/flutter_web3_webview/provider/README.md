# FxWallet Web3 Provider (vendored)

This directory holds the TypeScript source for the JavaScript bundle that
`flutter_web3_webview` injects into every `InAppWebView`. The bundle exposes
the `window.fxwallet` global so DApps can talk to the wallet through
EIP-1193 and the Solana wallet standard.

See [UPSTREAM.md](./UPSTREAM.md) for where the source originated and a
complete list of local divergences.

## Layout

```
packages/
  core/       # base provider + adapter strategies
  ethereum/   # EIP-1193 EthereumProvider + MobileAdapter
  solana/     # SolanaProvider + wallet-standard adapter
scripts/
  build.ts             # iterate workspaces, run each `bun run build:source`
  packages.ts          # list of allowed sub-packages
```

The source is already rebranded to FxWallet in place (the `window.fxwallet`
global, the `'fxwallet:'` Solana wallet-standard namespace, the `isFxWallet`
feature flag, …). The chains we don't expose through the WebView, the native
wrappers, and the upstream npm-publishing / chain-scaffolding tooling have
been removed. See [UPSTREAM.md](./UPSTREAM.md) for the full inventory of
local divergences from upstream.

## Build workflow

```bash
bun install
bun run build:packages   # validate the upstream per-package rollup builds
bun run build:flutter    # generate ../lib/js/provider.min.js via esbuild
```

`bundle/index.ts` is the aggregator entry point; it imports
`EthereumProvider` and `SolanaProvider` straight from the workspace source
and assigns them to `window.fxwallet`. `bundle/build.mjs` invokes esbuild
with Node-builtin polyfills (Buffer / events / crypto / http / https /
stream / url / util / zlib) and writes the IIFE bundle to the
`flutter_web3_webview` asset path so a successful build refreshes the
Flutter package in place.

> ⚠️ The build pipeline is wired up, but the resulting bundle is **not yet
> functionally equivalent** to the legacy `provider.min.js`. The legacy
> asset was produced by a now-lost fork that added a custom WebView bridge
> on top of the upstream source. See [RECOVERY.md](./RECOVERY.md) for the
> complete inventory of what still needs to be ported back into the
> vendored packages before the build can replace the legacy artifact.

## Requirements

* [Bun](https://bun.sh) for the upstream rollup-based per-package build.
* Node ≥ 18 for the esbuild bundle (`bundle/build.mjs`).
