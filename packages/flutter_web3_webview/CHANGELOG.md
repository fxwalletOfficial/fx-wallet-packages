## Unreleased

* SECURITY: Deny WebView permission requests by default unless the caller provides an explicit permission handler.
* FIX: JSON-encode wallet metadata before injecting it into JavaScript.
* FIX: Share provider asset loading across concurrent initialization calls.
* FIX: Serialize user-confirmed EVM and Solana requests and safely encode chain change events.
* FIX: Respect `isWeb3` when injecting provider scripts and forward Ajax ready-state callbacks.
* FIX: Surface EIP-1193 `4001` (user rejected) instead of the invalid `4092` code when a chain switch is declined, and reject `wallet_switchEthereumChain` with `4902` when no usable chain id is provided.
* FIX: Preserve raw DApp transaction fields in `JsTransactionObject.toJson` when values are non-string, so downstream wallets keep `nonce` / `maxFeePerGas` / numeric `gas` etc.

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
