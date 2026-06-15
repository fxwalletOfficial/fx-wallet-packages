# aleo_dart

A Dart SDK for the [Aleo](https://aleo.org) blockchain. Provides account, record and transaction APIs through FFI bindings to the `aleo_rust` native library (built from the `rust/aleo_rust` crate in this monorepo).

## Features

- Mnemonic / seed / private key / view key / address derivation
- Encrypted record (ciphertext) decryption
- Transfer building and submission (`transfer_public`, `transfer_private`, ...)
- Pluggable native library loading: prebuilt download, local cargo build, or arbitrary path

## Installation

```yaml
dependencies:
  aleo_dart: ^1.0.0
```

The package depends on a platform-specific dynamic library (`libaleo_rust.so` / `.dylib` / `.dll`). Fetch a prebuilt one with:

```bash
dart run aleo_dart:setup
```

This drops the library into `.dart_tool/dart_aleo/` and `DyLib.getDyLibFromGit()` will pick it up.

## Quick Start

```dart
import 'package:aleo_dart/aleo.dart';

final dyLib = DyLib.getDyLibFromGit();
final account = AleoAccount(dyLib);

final mnemonic = 'fly lecture gasp juice hover ice business census bless weapon polar upgrade';
final address    = account.mnemonicToAddress(mnemonic);
final privateKey = account.mnemonicToPrivateKey(mnemonic);
final viewKey    = account.privateKeyToViewKey(privateKey);
```

For record decryption and transaction building, see the demos under `test/`.

## Native library options

```dart
// Prebuilt, downloaded by `dart run aleo_dart:setup` (recommended).
final dyLib = DyLib.getDyLibFromGit();

// Local cargo build at rust/aleo_rust/target/release/.
final dyLib = DyLib.getDyLibFromCargo();

// Arbitrary path.
final dyLib = DyLib.getDyLibByPosition('/abs/path/to/libaleo_rust.so');
```

## Building the native library locally

The Rust source lives at [`rust/aleo_rust`](../../rust/aleo_rust) in this monorepo.

```bash
cd rust/aleo_rust
cargo build --release
# library at: target/release/libaleo_rust.{so,dylib,dll}
```

For Android cross-compilation see [`rust/build_android.sh`](../../rust/build_android.sh).

## License

MIT — see [LICENSE](./LICENSE).
