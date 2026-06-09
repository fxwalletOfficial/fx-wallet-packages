## Unreleased

* SECURITY: Deny WebView permission requests by default unless the caller provides an explicit permission handler.
* FIX: JSON-encode wallet metadata before injecting it into JavaScript.
* FIX: Share provider asset loading across concurrent initialization calls.
* FIX: Serialize user-confirmed EVM and Solana requests and safely encode chain change events.
* FIX: Respect `isWeb3` when injecting provider scripts and forward Ajax ready-state callbacks.
* FIX: Surface EIP-1193 `4001` (user rejected) instead of the invalid `4092` code when a chain switch is declined, and reject `wallet_switchEthereumChain` with `4902` for any chain id that is missing or is not a `0x`-prefixed hex string (previously `'1'`, `'0xzz'`, `' 0x1 '` and similar values still reached the wallet callback).
* FIX: Introduce `Web3RpcError` for structured Dart-side handling of provider failures. The `flutter_inappwebview` bridge still re-wraps the exception before it reaches the in-page DApp, so DApps continue to see a string; `Web3RpcError.toString()` now prefixes its JSON payload with the `Web3RpcError: ` sentinel so the provider JavaScript can extract the structured `{code,message}` once it is rebuilt from source (tracked separately).
* FIX: Back `JsTransactionObject` fields with the underlying raw map so setting a typed field to `null` actually clears the value (was leaking the original DApp value through `toJson()`), while still preserving DApp-provided fields like `nonce` / `maxFeePerGas` / numeric `gas`.
* FIX: Pass `overwriteMetamask` to the injected provider at the top level of the config object where the vendored `EthereumProvider` actually reads it. The previous `config.ethereum.isMetamask` field was never read (the rebuilt provider reads `config.overwriteMetamask`), so `window.ethereum.isMetaMask` was permanently `false` — breaking DApps that gate signing on it (e.g. the MetaMask test dapp). Add `Web3EthSettings.overwriteMetamask` (default `false`) so callers can opt into MetaMask impersonation.
* CHORE: Regenerate `lib/js/provider.min.js` from the vendored `provider/` source for the first time (it had remained the legacy fork artifact). The new esbuild bundle is **321 KB** vs the legacy ~1.46 MB: dropping the unreachable `MobileAdapter` from `EthereumProvider` / `SolanaProvider` cuts the `@metamask/eth-sig-util` dependency chain, and also fixes a latent P0 where `MobileAdapter` renamed EVM methods (`eth_sendTransaction → signTransaction`, etc.) that the Dart dispatcher doesn't recognise. DApp-facing surface is unchanged (verified against the legacy bundle).
* FEAT: Serialize Solana `signTransaction` inside the provider. Concurrent `signTransaction` calls (directly or via `signAllTransactions`) now run one at a time through an instance-level promise queue, so a DApp can't race the wallet's single approval UI. A rejected signature does not wedge the queue. This replaces the host-app userscript that previously monkey-patched the behaviour onto the provider at runtime.

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
