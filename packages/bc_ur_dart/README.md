# bc_ur_dart

A Dart implementation of the Uniform Resources (UR) protocol for encoding and decoding. UR is a CBOR-based, segmentable QR protocol developed by Blockchain Commons, suitable for cold wallets, signing, and secure data transfer.

## Features

- Encode and decode UR strings
- Support for fragment encoding and reading
- Compatible with mainstream cold wallets and signing protocols

## Installation

```yaml
dependencies:
  bc_ur_dart: ^0.1.15
```

## Quick Start

```dart
// Decode a UR string
final ur = UR.decode('ur:bytes/hdeymejtswhhylkepmykhhtsytsnoyoyaxaedsuttydmmhhpktpmsrjtgwdpfnsboxgwlbaawzuefywkdplrsrjynbvygabwjldapfcsdwkbrkch');

// Encode to string
ur.encode();

// Encode to fragment string
ur.next();

// Read fragment UR
final ur = UR();
ur.read(fragment);
```

## Example

For a complete usage example, see the relevant demo in the `examples/` directory of this repository.

## Contributing

Issues and PRs are welcome!

## License

MIT