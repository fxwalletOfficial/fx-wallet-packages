# Changelog

## [1.0.0] - 2024-06-19

### Added

- Initial release version featuring fundamental functionalities:
  - support wallets: ALPH, APTOS, CKB, COSMOS, DOT, HNS, KAS, KLS, NEAR, SC, SOL,SUI, XRP.
  - support address check.


## [1.0.1] - 2024-07-11

### Update

- Update doc and optimize code.


## [1.0.2] - 2024-07-30

### Update

- Add wallets: FIL, SCP.
- Add function: F410 address conversion, evm address custom generate.

## [1.0.3] - 2024-08-01
### Doc

- Modify readme.


## [1.0.4] - 2024-08-12
### Refactor

- Modify filecoin export.

## [1.0.5] - 2024-09-05
### Update

- Add wallet: ETH.
- Support eth transaction type: EIP1559, LEGACY.
- Support eth signed typed data module.

## [1.0.6] - 2024-09-13
### Refactor

- Export eth transaction type: EIP1559, LEGACY.
- Modify EIP1559 and LEGACY transaction type.

## [1.0.7] - 2024-09-13
### Update

- Update eth transaction type: EIP1559, LEGACY.

## [1.0.8] - 2024-09-13
### Update

- Update eth EthTxData.

## [1.0.9] - 2024-09-25
### Update

- Update pinenacl to v0.6.0

## [1.0.10] - 2024-10-08
### Update

- Add wallet: icp.
- Modify eip1559 message.

## [1.0.11] - 2024-10-11
### Update

- Add transaction: icp.

## [1.0.12] - 2024-10-23
### Update

- Add wallet: icp stoic.

## [1.0.13] - 2024-11-26
### Update

- Add address check: aleo, ton, icp.

## [1.0.14] - 2024-11-26
### Update

- update btc type address check.

## [1.0.15] - 2024-11-27
### Update

- update bch type address check.

## [1.0.16] - 2024-11-27
### Update

- export scp dictionary.

## [1.0.17] - 2024-12-16
### Update

- Add wallet: algo.

## [1.0.18] - 2024-12-19
### Update

- Add psbt signer.

## [1.0.19] - 2024-12-20
### Update

- Add function: decompress public key.

## [1.0.20] - 2024-12-24
### Update

- Add wallet: trx.

## [1.0.21] - 2025-01-06
### Update

- Address utils update.

## [1.1.0] - 2025-01-14
### Update

- Forked library: bip32, bitcoin base, psbt.
- Refactor code.

## [1.1.1] - 2025-01-16
### Update

- Export package.

## [1.1.2] - 2025-02-08
### Update

- Export solana tx v2 package.

## [1.1.3] - 2025-02-21
### fix

- solana tx v2 message error.

## [1.1.4] - 2025-03-10
### Update

- Forked library: xrpl_dart.
- Fix xrp tx signer error.

## [1.1.5] - 2025-03-28
### Update

- Fix bells testnet config error.

## [1.1.6] - 2025-06-19
### Update

- Add btc wallet and psbt tx builder.

## [1.1.7] - 2025-06-23
### Update

- fix psbt signer error.

## [1.1.8] - 2025-07-28
### Update

- Add gspl signer.
- Add doge wallet
- Add ltc wallet
- Add bch wallet

## [1.1.9] - 2025-07-28
### Update

- Update gitignore file.

## [1.1.10] - 2025-08-06
### Update

- fix batch transfer error of psbt and gspl.

## [1.1.11] - 2025-08-14
### Update

- Update tweetnacl-dart.

## [1.1.12] - 2025-08-14
### Update

- Update cosmos_dart export.

## [1.1.13] - 2025-08-28
### Update

- add ethereum message sign.

## [1.1.14] - 2025-09-08
### Update

- Support EIP7702 transaction data.
- add authorization in eth data.

## [1.1.15] - 2025-09-26
### Update

- Add COW swap transaction ABI data parse.

## [1.1.16] - 2025-10-28
## Fix

- Fix address check method.

## [1.1.17] - 2025-11-04
## Update

- Update packages version.

## [1.2.0] - 2025-11-05
## Update

- Update BIP32 & BIP39.

## [1.2.1] - 2025-12-12
## Update

- Update GSPL Signer.

## [1.2.2] - 2025-12-30
## Update

- Add bridge tx parse.

## [1.2.3] - 2026-02-24
## Update

- Update: Update export.

## [1.2.4] - 2026-02-24
## Fix

- Add chain id in eth legacy tx unsigned serialized message.

## [1.2.5] - 2026-04-29
## Fix

- Fix xrpl transaction export.
- Fix fromTransferPsbt fingerPrint.


## [1.2.6] - 2026-05-27
## Update

- SC transaction assembly with WASM integration (`package:wasm_run`).
- SC transaction signer (Ed25519) and builder.
- SC send example.


## [2.0.0] - 2026-06-09
### BREAKING

- Upgrade `blockchain_utils` from `^1.4.1` to `^6.0.0`. Resolves the dependency
  conflict reported in #20 (consumers using `bitcoin_base 7.x` / `xrpl_dart 7.x`,
  which require `blockchain_utils ^6.0.0`).
- Minimum Dart SDK raised to `>=3.7.0` (required by `blockchain_utils 6.0.0`).

### Changed

- Migrated the vendored `bitcoin_base_hd` and `xrpl_dart` forks to the
  `blockchain_utils` 6.x API: relocated utility imports to the package barrel,
  `Tuple`/`item1,item2` → Dart records (`$1`,`$2`), `mask*`/`writeUintXLE` →
  `BinaryOps.*`, `bytesEqual`/`iterableIsEqual` → `BytesUtils`/`CompareUtils`,
  `Secp256k1*KeyEcdsa` → `Secp256k1*Key`, `BitcoinSigner`/`BitcoinVerifier` →
  `BitcoinKeySigner`/`BitcoinSignatureVerifier`, `BigintUtils.orderLen` →
  `BigintUtils.bitlengthInBytes`.
- ECDSA / Taproot / message signing outputs verified byte-for-byte identical to
  the pre-upgrade implementation; XRP secp256k1 family-seed derivation and
  classic/X-address conversion pinned with characterization tests.
- `Bech32Validations` / `SegwitValidations` declared as `mixin` (Dart 3 language
  level no longer permits using a plain class as a mixin).

### Notes

- No public API changes beyond the SDK floor; all 782 unit tests pass.


## [2.0.1] - 2026-06-12
### Added

- SC (Sia): native Go FFI transaction bridge (`ScGoFfiBridge`) as a faster,
  opt-in alternative to the WASM bridge. Select it via
  `ScTransactionBuilder.createWithFfi()`. The default `create()` is unchanged
  and still uses the WASM bridge (`ScWasmRunBridge`), so existing callers are
  unaffected. The native library is currently bundled for macOS/arm64 only.

### Removed

- Pruned dead code from the vendored `bitcoin_base_hd` fork that is never
  reached by this package (BTC/LTC/BCH only use `ECPrivate`):
  - the entire `provider/` subtree (Electrum/HTTP API providers and the
    `BitcoinTransactionBuilder` / BCH builder) and `utils/btc_utils.dart`
    (~2.2k lines).
  - `ECPublic.verifyTransactionSignature` and
    `ECPublic.verifySchnorrTransactionSignature` (unused; their post-upgrade
    bodies had latent argument-shape issues).