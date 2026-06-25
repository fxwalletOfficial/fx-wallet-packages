# aleo_flutter

A Flutter FFI plugin that **bundles the prebuilt `aleo_rust` native library** and
exposes the [`aleo_dart`](../aleo_dart) API on **Android and iOS** — no `cargo`
build per consumer, no runtime download, offline at runtime.

`aleo_dart` stays a pure-Dart package (desktop dev keeps building from source via
`DyLib.getDyLibFromCargo()`). `aleo_flutter` is the thin mobile distribution
layer on top of it.

> **Status — released (v1):** the
> [`aleo_ffi-v1.0.0`](https://github.com/fxwalletOfficial/fx-wallet-packages/releases/tag/aleo_ffi-v1.0.0)
> GitHub Release is published and the SHA-256 values in
> [`lib/src/artifact_manifest.dart`](lib/src/artifact_manifest.dart) are pinned to
> it, so the build-time download path is **active**: a consumer app just runs
> `flutter build` and the right `libaleo_rust` is fetched once, verified against
> the pinned SHA-256, and bundled. To build the library locally instead (or to
> develop without the release), run `rust/build_ios.sh` / `rust/build_android.sh`
> or set `ALEO_FFI_IOS_XCFRAMEWORK` / `ALEO_FFI_ANDROID_JNILIBS` (see
> [Local development](#local-development-before--instead-of-a-release)).

## Why

The native library is ~35 MB per platform and slow to cross-compile (it links
snarkVM). `aleo_flutter` removes that pain: the consumer app just runs
`flutter build` and the right `libaleo_rust` is bundled automatically, verified
against the pinned SHA-256 (see **Status** above; to build without the release,
use a local build or an `ALEO_FFI_*` override).

## Usage

```dart
import 'package:aleo_flutter/aleo_flutter.dart';

// Loads the bundled native library (validates ffi_abi_version). No I/O beyond
// dlopen — the library is already inside the app.
final lib = AleoFlutter.load();

// Use the re-exported aleo_dart API:
final account = AleoAccount(lib, 'mainnet');
final address = account.mnemonicToAddress(mnemonic);
```

See [`example/`](example) for a runnable app (the simulator/emulator/device
acceptance harness).

## How distribution works (build-time fetch, NOT runtime)

| Phase | Where | What happens |
|---|---|---|
| **Build time** | dev/CI, during `flutter build` / `pod install` / Gradle | the prebuilt `libaleo_rust` is fetched **once** from a pinned GitHub Release, verified against the SHA-256 in [`lib/src/artifact_manifest.dart`](lib/src/artifact_manifest.dart), and bundled into the app (Android `jniLibs`; iOS embedded as a dynamic `AleoRust.framework` via xcframework). |
| **Run time** | end-user device | `AleoFlutter.load()` = `DynamicLibrary.open` (`libaleo_rust.so` on Android, `AleoRust.framework/AleoRust` on iOS) + ABI validation. Local, instant, offline. |

The end user never downloads the native library.

## Local development (before / instead of a release)

Both platform scripts try a **local build first**, then fall back to downloading
the pinned release. Build the library once and the example/app will bundle it:

```bash
rust/build_ios.sh       # -> rust/ios_lib/AleoRust.xcframework
rust/build_android.sh   # -> rust/android_lib/jniLibs/<abi>/libaleo_rust.so
```

Override the location with `ALEO_FFI_IOS_XCFRAMEWORK` / `ALEO_FFI_ANDROID_JNILIBS`.

## Proving

Proving is **server-delegated** in the wallet, so the ~1.15 GB proving keys are
**not** bundled. This plugin ships only the ~35 MB library for the cheap offline
ops (account / record / authorize / fee-auth / broadcast).

## License

`aleo_flutter` is **Apache-2.0** (see [LICENSE](LICENSE)), matching the binary it
ships. See [NOTICE](NOTICE) and [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## See also

- **As-built design (authoritative):** `rust/aleo_ffi/docs/pr6a-impl-notes.md`
  (iOS dynamic framework, local override, version binding).
- Original distribution plan (partly superseded — iOS is now a dynamic framework,
  not the static lib it describes): `rust/aleo_ffi/docs/pr6-distribution-spec.md`
