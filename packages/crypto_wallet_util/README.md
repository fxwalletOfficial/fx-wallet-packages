# crypto_wallet_util

Crypto &amp; Blockchain Toolkit

This package provides multi-chain address generation, transaction assembly,
signing, verification, and encoding utilities for wallet applications. SC
transaction support uses the bundled WebAssembly asset by default and also
offers a caller-supplied native FFI bridge.

## Features

### **Support wallet:**

- ALGO
- ALPH
- APTOS
- BCH
- BTC
- BTCB2
  - aliases: `btcb2`, `xbt`
- CKB
- COSMOS
- DOGE
- DOT
  - ED25519
  - SR25519

- ETH
- FIL
- HNS
- ICP
- KAS
  - KAS
  - KLS

- LTC
- NEAR
- SC (sia coin)
  - SCP
- SOL
- SUI
- TRX
- XRP

### **Support transaction :**  

- ALGO
- ALPH
- APTOS
- BTC
  - PSBT
  - GSPL
- BTCB2
  - UNIFIED
- CKB
- COSMOS
- ETH
  - EIP1559
  - LEGACY
- FIL
- HNS
- ICP
- KAS
- NEAR
- SOL
- SUI
- XRP
- SC
  - V2 transaction assembly
  - V2 semantic signing and cold-side inspection

### Support address check

- BASE32
  - ALGO
  - FIL
- ETH
- BTC
  - LTC
  - DOGE
  - BTC
  - BTCB2
  - BCH
  - BELL
- BECH32
  - COSMOS
    - ATOM
    - KAVA
    - SEI
  - CKB
  - HNS
- KAS
  - KAS
  - KLS
- BASE58 (not fully support)
  - ALPH
- regular
  - SOL
  - ALEO
  - TON
  - APTOS
  - DOT
  - NEAR
  - SC
  - SUI
  - TRX
  - XRP

### **Sign and Verification:**

- Ed25519
- Sr25519
- Secp256k1
- Schnorr

### **Encoding and Decoding:**

- Base32 Encoding/Decoding
- SS58 Encoding/Decoding
- Base58Check Encoding/Decoding
- Bech32 Encoding/Decoding
- Hex Encoding/Decoding
- BigInt Encoding/Decoding

## SC V2 semantic signing

`ScTransactionBuilder` can extract the exact Sia V2 transaction semantics that
are committed by `InputSigHash`, without forwarding Merkle proofs, parent
outputs, policies, signatures, or other witness data to the cold side.

```dart
import 'package:crypto_wallet_util/transaction.dart';

final builder = await ScTransactionBuilder.create();
try {
  final hotSide = await builder.extractV2TransactionSemantics(
    unsignedV2Transaction,
    changeAddresses: knownWalletAddresses,
  );

  // Transfer hotSide.bytes to the cold side. The cold side parses the bytes
  // again and recomputes the digest through the pinned Sia core implementation.
  final coldSide = await builder.inspectV2TransactionSemantics(
    hotSide.bytes,
    changeAddresses: knownWalletAddresses,
  );

  print(coldSide.inputSigHash);
  print(coldSide.externalOutputs);
  print(coldSide.changeOutputs);
  print(coldSide.minerFee);
} finally {
  builder.dispose();
}
```

The initial `sia-v2-siacoin-transfer-v1` profile accepts ordinary siacoin
transfers only. Unsupported V2 transaction categories, malformed or
non-canonical payloads, missing required fields, zero-value outputs, and
out-of-range input/output counts fail closed.

## Feature requests and bugs ##

Please file feature requests and bugs in the issue tracker.
