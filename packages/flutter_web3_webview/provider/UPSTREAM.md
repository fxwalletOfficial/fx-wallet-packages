# Upstream provenance

<!--
  This file documents the source of the vendored provider. It is intentionally
  excluded from `scripts/brand-rename.mjs` so the upstream repository URL and
  the description of what was renamed survive future rebases.
-->

The `provider/` tree was imported from
[`trustwallet/trust-web3-provider`](https://github.com/trustwallet/trust-web3-provider).

## Local divergences from upstream

| Area | Change |
|------|--------|
| Branding | `trustwallet → fxwallet`, `TrustWallet → FxWallet`, `Trust → FxWallet`, `isTrustWallet / isTrust → isFxWallet` |
| Solana wallet-standard | `TrustNamespace ('trust:') → FxNamespace ('fxwallet:')`, `TrustFeature → FxFeature`, inner `trust` identifier → `fx` |
| Author metadata | `Trust <support@trustwallet.com> → fxwalletOfficial <noreply@fxwallet.io>` |
| Chains shipped | only `core` + `ethereum` + `solana` (upstream's `aptos`, `bitcoin`, `cosmos`, `ton`, `tron` removed) |
| Native wrappers | upstream `android/` and `ios-web3-provider/` removed |
| Tooling | upstream `scripts/{generate,link,publish,rename}.ts`, `templates/`, semantic-release config, `.gitattributes` LFS rule removed |

The branding row is fully encoded in [`scripts/brand-rename.mjs`](./scripts/brand-rename.mjs)
and can be re-applied with `bun run brand:apply` after pulling upstream.

## How to refresh from upstream

1. Clone or `git fetch` upstream into a sibling directory.
2. Diff against this tree and copy across the files you want to update.
3. Run `bun run brand:apply` (or `node ./scripts/brand-rename.mjs`).
4. Run `bun run brand:check` to confirm no residual brand strings.
5. Re-run the bundle build (Phase 2 onward) and compare the produced
   `../lib/js/provider.min.js` against the previous one.
