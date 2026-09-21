# bc_ur_dart

A pure Dart implementation of the Uniform Resources (UR) protocol and common crypto-wallet UR registry models. UR is a CBOR-based, fragmentable QR protocol used by cold wallets for account export, transaction signing, and signature return flows.

## Features

- Encode and decode single-part and multipart UR strings.
- Decode and generate CBOR-backed signing/account models for:
  - BTC PSBT and GSPL signing
  - ETH signing requests and signatures
  - Solana, TRON, Cosmos, BCH, ALPH, SC, and Keystone-compatible chain payloads
  - Strict SC V2 raw-byte sign requests and 64-byte Ed25519 signature responses
  - `crypto-hdkey`, `crypto-account`, and `crypto-multi-accounts`
- Explicit malformed UR/CBOR errors for model parsing. Invalid model payloads fail closed instead of relying on raw Dart cast errors.

## Examples

The monorepo contains a Flutter demo at:

```text
examples/bc_ur_dart_demo
```

This package itself is pure Dart, so package verification still uses `dart test`.

## Installation

```yaml
dependencies:
  bc_ur_dart: ^0.1.29
```

## Quick Start

```dart
import 'package:bc_ur_dart/bc_ur_dart.dart';

final ur = UR.decode(
  'ur:bytes/hdeymejtswhhylkepmykhhtsytsnoyoyaxaedsuttydmmhhpktpmsrjtgwdpfnsboxgwlbaawzuefywkdplrsrjynbvygabwjldapfcsdwkbrkch',
);

final encoded = ur.encode();
final fragment = ur.next();

final decoder = UR();
final complete = decoder.read(fragment);
```

### SC V2 cold-signing wire types

SC V2 uses independent `sc-v2-sign-request` and `sc-v2-signature` registry types. The package transports opaque canonical semantic transaction bytes; constructing or parsing Sia transactions, computing their signing hash, and verifying signatures remain the caller's responsibility.

```dart
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';

final canonicalSemanticTransactionBytes = Uint8List.fromList([0x01]);
final request = ScV2SignRequest.buildUR(
  requestId: '123e4567-e89b-12d3-a456-426614174000',
  profile: ScV2Profile.sc,
  masterFingerprint: Uint8List.fromList([0xa1, 0xb2, 0xc3, 0xd4]),
  signerCoreAddress: Uint8List(32),
  semanticTransaction: canonicalSemanticTransactionBytes,
);

final decodedRequest = ScV2SignRequest.fromUR(request);

final ed25519SignatureBytes = Uint8List(64);
final response = ScV2Signature.fromRequest(
  request: decodedRequest,
  signature: ed25519SignatureBytes,
);
```

Consumers must compare a decoded response UUID with the outstanding request before accepting the signature. SC V2 does not negotiate with or silently downgrade to the legacy `ScSignRequest` / `ScSignature` JSON formats.

## Error Handling

Use UR parsing as two separate validation layers:

- Transport validation: `UR.decode()` and `UR.read()` validate UR text, ByteWords, sequence, and fragments.
- Semantic validation: model factories such as `EthSignRequestUR.fromUR()` and `CryptoHDKeyUR.fromUR()` validate CBOR shape, required fields, and nested registry items.

Every chain model's decoder fails closed on malformed input, throwing `URException` subclasses — `InvalidTypeURException` for a wrong UR type and `InvalidCborURException` for bad CBOR shape / missing required fields — rather than raw `ArgumentError`, `RangeError`, or Dart cast errors. Application scan flows can therefore catch all parse failures via `on URException` at the completed-UR boundary and stop the signing flow. (Encode-side helpers that build requests still throw `ArgumentError` for programmer errors such as mismatched list lengths.)

## Development

This is a pure Dart package.

```bash
dart format path/to/changed_file.dart
dart analyze
dart test
```

Do not use `flutter test` for this package.
Avoid broad formatting; format only files you intentionally changed.

## License

MIT
