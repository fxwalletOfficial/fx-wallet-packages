# bc_ur_dart

A pure Dart implementation of the Uniform Resources (UR) protocol and common crypto-wallet UR registry models. UR is a CBOR-based, fragmentable QR protocol used by cold wallets for account export, transaction signing, and signature return flows.

## Features

- Encode and decode single-part and multipart UR strings.
- Decode and generate CBOR-backed signing/account models for:
  - BTC PSBT and GSPL signing
  - ETH signing requests and signatures
  - Solana, TRON, Cosmos, BCH, ALPH, SC, and Keystone-compatible chain payloads
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
  bc_ur_dart: ^0.1.26
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

## Error Handling

Use UR parsing as two separate validation layers:

- Transport validation: `UR.decode()` and `UR.read()` validate UR text, ByteWords, sequence, and fragments.
- Semantic validation: model factories such as `EthSignRequestUR.fromUR()` and `CryptoHDKeyUR.fromUR()` validate CBOR shape, required fields, and nested registry items.

Malformed model CBOR throws `URException` subclasses such as `InvalidCborURException`. Application scan flows should catch parse errors at the completed-UR boundary and stop the signing flow.

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
