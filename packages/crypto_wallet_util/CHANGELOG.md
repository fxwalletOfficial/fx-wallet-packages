# Changelog

## [2.0.5] - 2026-08-25
### Changed

- The default SC WASM transaction builder now parses, instantiates and runs the
  WASM module in serialized short-lived background isolates, preventing the
  first SC transaction from blocking the UI isolate without requiring callers
  to manage a long-lived worker lifecycle.
- Flutter callers can provide a `rootBundle`-backed WASM loader; package asset
  metadata and fallback loading now cover runtimes where package URI
  resolution is unavailable.

## [2.0.4] - 2026-08-02
### Fixed

- Raw ECDSA signatures now encode `r` and `s` to a fixed 32 bytes instead of
  copying the shortest big-endian encoding into a fixed-width buffer. A low-S
  value that fitted in 31 bytes previously threw `Bad state: Too few elements`
  and aborted signing. Low-S normalisation reduces `s` into `[1, n/2]`, so this
  affected roughly 1 in 128 signatures; since a transaction signs once per
  input, multi-input DOGE/BTC/LTC/BCH transactions failed far more often than
  single-input sends.
- PSBT and GSPL LTC Taproot signing use a real BIP341 TapSighash instead of
  reusing the BIP143 SegWit v0 digest, and write the Schnorr signature to the
  witness stack with an empty `scriptSig` instead of compiling it into
  `scriptSig`. Verified against the official BIP341 `wallet-test-vectors.json`.
- PSBT Taproot re-signing preserves each input's original sequence instead of
  resetting it to `0xffffffff`, which silently dropped RBF and relative
  timelock semantics and invalidated the signature it had just produced.
- Local BIP340 Schnorr signing encodes `t`, `P.x`, `R.x`, `s` and the taproot
  tweak to a fixed 32 bytes, so a leading zero byte no longer corrupts the
  nonce/challenge hashes or yields a short signature or private key.
- DOGE/LTC/BCH GSPL signing threads one explicit hashType through both the
  digest computation and the final signature encoding, so a non-default sighash
  no longer commits to one type while declaring another.
- Taproot sighash construction rejects unsupported hash types and
  `SIGHASH_SINGLE` inputs without a corresponding output instead of producing
  a signature for an invalid BIP341 signing state.
- `EthTxSigner.verify()` interprets `v` as a bare y-parity for typed
  (EIP-1559/EIP-7702) transactions and as EIP-155 only for legacy, and recovers
  the signer's address rather than checking structural bounds alone.
- `isValidEthSignature()` accepts scalars whose shortest encoding is under 32
  bytes and rejects `r`/`s` equal to the curve order, instead of the reverse.
- `BtcCoin`/`LtcCoin`/`DogeCoin`/`BchCoin.verify()`, `PsbtTxSigner.verify()`,
  `GsplTxSigner.verify()` and `KasTxSigner.verify()` perform real cryptographic
  verification over every input, replacing stubs that returned `true`
  unconditionally or only checked that a signature field was present. Taproot
  verification checks against the tweaked output key, and non-Taproot
  verification parses DER plus the trailing sighash byte.
- Legacy PSBT verification and finalization bind the serialized sighash suffix
  to the digest being verified. Finalization also validates inputs backed by a
  full previous transaction instead of skipping signature verification when
  `witnessUtxo` is absent.
- PSBT DER-to-raw signature conversion re-encodes `r` and `s` to a fixed 32
  bytes each, so a legitimately short `r` no longer shifts `s` off offset 32.
  DER parsing now rejects negative or excessively padded integers, values over
  256 bits, inconsistent lengths and extra trailing data.
- `DotCoin.verify()` applies the same `0x9c` prefix stripping as `sign()`, and
  `processMessage()` no longer throws on an empty message.
- Schnorr aux randomness uses `Random.secure()` over a full 32 bytes instead of
  `Random()` over 16 bytes zero-padded by the dependency.
- secp256k1 private keys are validated (32 bytes, in `[1, n-1]`) at the
  `EcdaSignature.privateKeyToPublicKey` boundary shared by every secp256k1
  wallet.

### Changed

- HNS transaction signing rejects inputs, outputs, address lengths and covenant
  fields that would require multi-byte varint encoding, instead of silently
  misparsing them. The full varint encoding is still unimplemented.
- The CKB single-lock-script-group assumption is now documented as a known
  limitation: `CellInput` carries no lock-script data, so this class cannot
  detect or sign transactions spanning multiple script groups.

## [2.0.3] - 2026-07-17
### Fixed

- BTC address generation and validation now consistently honor the selected
  network, including legacy, SegWit v0, BIP86 Taproot, custom HRPs, and
  fail-closed handling for explicitly configured networks without a valid HRP.
- Taproot key tweaking now follows BIP341 `lift_x` semantics and is pinned to the
  official BIP86 address and scriptPubKey vector.
- Bech32, Bech32m, and CashAddr decoding now verifies checksum, network prefix,
  witness version and length, and canonical bit padding.
- BCH testnet uses `bchtest` plus testnet version bytes, and BCH validation
  requires a full network-matching CashAddr to avoid BTC/BCH legacy ambiguity.
- PSBT change detection infers the CashAddr network prefix from the input
  address instead of hard-coding `bitcoincash`, so BCH testnet CashAddr change
  outputs no longer abort transaction construction.
- `PSBT.fromTransferPsbt` selects the mainnet or testnet chain config from the
  extended key's BIP32 version bytes, so a standard testnet `tpub`
  (`0x043587cf`) parses and builds instead of being rejected by the mainnet
  config and crashing on a null wallet. BTC/BCH testnet BIP32 public version
  bytes were corrected to `0x043587cf`.
- BTC PSBT construction remains backward-compatible with the non-standard
  testnet extended public-key version (`0x04358a68`, `tpw...`) emitted by 2.0.2,
  while malformed keys and genuinely unknown versions now fail closed.
- Taproot wallets keep the caller's `WalletSetting` by reference and derive the
  BIP86 path at sign time, so switching the setting's network stays consistent
  across existing and freshly derived wallets.

## [2.0.2] - 2026-07-02
### Fixed

- PSBT: parse LTC P2SH / Nested SegWit addresses correctly by plumbing chain-aware
  version bytes and bech32 HRP through address encoding instead of hard-coding BTC
  mainnet values.
- GSPL: support LTC P2SH payment address parsing by detecting the script type
  (P2PKH vs P2SH) and resolving the correct network version bytes from the bip44
  path coin-type segment.
- BTC / LTC chain configs: fill in distinct testnet NetworkType values (previously
  shared mainnet settings).

## [2.0.1] - 2026-06-12
### Added

- SC (Sia): native Go FFI transaction bridge (`ScGoFfiBridge`) as a faster,
  opt-in alternative to the WASM bridge. The default `create()` is unchanged
  and still uses the WASM bridge (`ScWasmRunBridge`), so existing callers are
  unaffected. The native library is **not** bundled: the caller builds it for
  their platform (see `lib/src/forked_lib/sia-wasi/build.sh`), loads it, and
  passes it via `ScTransactionBuilder.createWithFfi(DynamicLibrary)`.

### Changed

- Minimum Dart SDK raised to `>=3.11.0` (required by the `wasd` WASM
  interpreter that backs the default SC bridge). Consumers on Dart 3.7–3.10
  must upgrade.

### Removed

- Pruned dead code from the vendored `bitcoin_base_hd` fork that is never
  reached by this package (BTC/LTC/BCH only use `ECPrivate`):
  - the entire `provider/` subtree (Electrum/HTTP API providers and the
    `BitcoinTransactionBuilder` / BCH builder) and `utils/btc_utils.dart`
    (~2.2k lines).
  - `ECPublic.verifyTransactionSignature` and
    `ECPublic.verifySchnorrTransactionSignature` (unused; their post-upgrade
    bodies had latent argument-shape issues).

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
