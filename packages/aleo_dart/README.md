# aleo_dart

A Dart SDK for the [Aleo](https://aleo.org) blockchain. Provides account, record and transaction APIs through FFI bindings to the `aleo_rust` native library (built from the `rust/aleo_ffi` crate in this monorepo).

## Features

- Mnemonic / seed / private key / view key / address derivation
- Encrypted record (ciphertext) decryption
- Transfer building and submission (`transfer_public`, `transfer_private`, ...)
- Native library loading: build-from-source (desktop) or build-time bundle (mobile), with a load-time ABI-version guard

## Installation

```yaml
dependencies:
  aleo_dart: ^1.0.0
```

The package depends on a platform-specific native library (`libaleo_rust.so` / `.dylib` / `.a`). It is **not downloaded at runtime** — you build it from source (desktop/CI) or bundle it at build time (mobile). See [Native library](#native-library) below.

The library's ABI is validated when you construct `AleoAccount` / `AleoRecord` / `AleoProgram` / `ParameterProvisioner`: an incompatible or stale library is rejected at load time with `IncompatibleNativeLibraryException` (rather than mis-binding a symbol).

## Quick Start

```dart
import 'package:aleo_dart/aleo.dart';

// Desktop: built by `cargo build --release` in rust/aleo_ffi (see below).
final dyLib = DyLib.getDyLibFromCargo();
final account = AleoAccount(dyLib);

final mnemonic = 'fly lecture gasp juice hover ice business census bless weapon polar upgrade';
final address    = account.mnemonicToAddress(mnemonic);
final privateKey = account.mnemonicToPrivateKey(mnemonic);
final viewKey    = account.privateKeyToViewKey(privateKey);
```

For record decryption and transaction building, see the demos under `test/`.

## Native library

### Desktop / CI — build from source

```bash
cd rust/aleo_ffi
cargo build --release
# library at: target/release/libaleo_rust.{so,dylib,dll}
```

```dart
final dyLib = DyLib.getDyLibFromCargo();                 // ../../rust/aleo_ffi/target/release
// or an explicit path:
final dyLib = DyLib.getDyLibByPosition('/abs/path/to/libaleo_rust.so');
```

### Mobile — bundle at build time

```bash
rust/build_android.sh   # → rust/android_lib/jniLibs/<abi>/libaleo_rust.so   (bundle in the app's jniLibs)
rust/build_ios.sh       # → rust/ios_lib/AleoRust.xcframework               (link into the app target)
```

```dart
final dyLib = DyLib.getMobileDyLib(); // Android: open('libaleo_rust.so'); iOS: process()
```

See [`rust/aleo_ffi/docs/cross-compile.md`](../../rust/aleo_ffi/docs/cross-compile.md) for the full per-platform build/distribution model (16k-page alignment on Android; the `-force_load` / `nm` dead-strip retention step iOS apps must apply).

> `dart run aleo_dart:setup` (runtime download) is **deprecated** and not used in this version: its pinned source is a stale, ABI-incompatible GPL-era artifact that the ABI guard would reject.

## License

MIT — see [LICENSE](./LICENSE).
