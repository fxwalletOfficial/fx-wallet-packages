# bc_ur_dart Demo

Debug & development tool App. **All data is mock — no real on-chain transactions.**

## Quick Start

### 1. Structure

```
fx-wallet-packages/
├── packages/
│   └── bc_ur_dart/          # UR encoding/decoding package
├── examples/
│   └── bc_ur_dart_demo/    # This demo app
│       ├── lib/             # Source code
│       └── pubspec.yaml     # path: ../../packages/bc_ur_dart
```

### 2. Install Dependencies

```bash
cd examples/bc_ur_dart_demo
flutter pub get
```

### 3. iOS Camera Permission

Add to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for UR QR scanning</string>
```

### 4. Run

```bash
flutter run
```

## Features

| Module | Sprint | Status |
|--------|--------|--------|
| Scan UR QR + multi-frame progress | 1 | ✅ |
| Parse result + copy each field | 1 | ✅ |
| Dynamic form + generate QR | 2 | ✅ |
| Two-step signing flow | 3 | 📅 |

## Supported UR Types

- **Sign Requests**: ETH, Cosmos, Solana, Tron, Alephium, PSBT, GSPL
- **Signatures**: ETH, Cosmos, Solana, Tron, Alephium, PSBT, GSPL
- **Accounts**: CryptoHDKey, CryptoMultiAccounts

## UR API

```dart
// ── Decode (scan direction) ────────────────────────────────

final ur = UR();                    // Create empty receiver
final done = ur.read(qrFrame);      // Feed one frame, true = complete

// Progress calculation (UR class has no progress property)
final total = ur.seq.length;        // Total frames, 0 = single frame
final received = ur.receivedPartIndexes.length;
final progress = total > 0 ? received / total : (ur.isComplete ? 1.0 : 0.0);

// Decode specific types
if (ur.isComplete) {
  final type = ur.type;   // e.g. 'eth-sign-request' (lowercase)
  final req = EthSignRequestUR.fromUR(ur: ur);
}

// ── Encode (generate direction) ──────────────────────────

final req = EthSignRequestUR.fromMessage(
  dataType: EthSignDataType.ETH_TRANSACTION_DATA,
  address: '0x...',
  path: "m/44'/60'/0'/0/0",
  origin: 'demo',
  xfp: '12345678',
  signData: '0xabcd...',
  chainId: 1,
);

// req IS-A UR subclass, call next() directly to generate frames
final frame = req.next();
// Use Timer to loop next(), render with qr_flutter

// ── New-style classes (RegistryItem subclasses) ────────────

// Cosmos / Sol / Tron / Alph use different build/parse methods:
final tronUR = TronSignRequest.generateSignRequest(
  signData: '0xabcd...',
  path: "m/44'/195'/0'/0/0",
  xfp: '12345678',
);

final tronReq = TronSignRequest.fromCBOR(ur.payload);
```

## Class Reference

| Function | Class Name |
|----------|------------|
| ETH Sign Request | `EthSignRequestUR` |
| ETH Signature | `EthSignatureUR` |
| PSBT Sign Request | `PsbtSignRequestUR` |
| GSPL Sign Request | `GsplSignRequestUR` |
| GSPL Signature | `GsplSignatureUR` |
| HD Key | `CryptoHDKeyUR` |
| Multi Accounts | `CryptoMultiAccountsUR` |
| Cosmos/Sol/Tron/Alph | `CosmosSignRequest` / `SolSignRequest` / `TronSignRequest` / `AlphSignRequest` |
