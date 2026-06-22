# aleo_ffi — cross-compile & distribution (Phase 4, PR4b)

How the native `libaleo_rust` library is produced and consumed per platform. v1
does **not** download the library at runtime: desktop/CI build it from source,
mobile bundles it at build time. (A runtime-download path with an in-package
integrity anchor may return in a later version.)

Since workstreams A (curl) and B (ureq) removed the HTTP/TLS stack, there is **no
OpenSSL** to cross-compile or carry — the old `OPENSSL_BASE_PATH` is gone.

## crate-type

`rust/aleo_ffi/Cargo.toml` builds three artifacts (`[lib] name = "aleo_rust"`):

| crate-type | artifact | used by |
|---|---|---|
| `cdylib` | `libaleo_rust.{so,dylib,dll}` | Android (.so) + desktop (`DynamicLibrary.open`); iOS dynamic `AleoRust.framework` |
| `staticlib` | `libaleo_rust.a` | not used by the mobile build (kept for apps that static-link the library themselves) |
| `rlib` | — | `cargo test` harness |

## Android — `rust/build_android.sh`

Build-time bundled into the app's `jniLibs`. Requirements:

```
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
cargo install cargo-ndk
export ANDROID_NDK_HOME=<your NDK>        # e.g. ~/Library/Android/sdk/ndk/28.2.13676358
```

`rust/build_android.sh` produces `rust/android_lib/jniLibs/<abi>/libaleo_rust.so`
for `arm64-v8a`, `armeabi-v7a`, `x86_64`, built with the 16k page-size link args
(mandatory on Android 15+) and **fails if any LOAD segment is not 16k-aligned**.
The app bundles `jniLibs/` and loads via `DynamicLibrary.open('libaleo_rust.so')`
(`DyLib.getMobileDyLib`).

## iOS — `rust/build_ios.sh`

A **dynamic framework** (v2; the earlier static-lib + `-force_load` approach was
dropped — see `pr6a-impl-notes.md`). Requirements (macOS + Xcode):

```
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```

`rust/build_ios.sh` builds the `cdylib` for the device slice (`aarch64-apple-ios`)
and a fat simulator slice (`aarch64-apple-ios-sim` + `x86_64-apple-ios` via `lipo`),
wraps each in a flat `AleoRust.framework` (install name
`@rpath/AleoRust.framework/AleoRust` + `Info.plist`), and packages a **dynamic**
`rust/ios_lib/AleoRust.xcframework`. It exports `IPHONEOS_DEPLOYMENT_TARGET=15.5`
(`MIN_IOS`, matching the fx-wallet app's `ios/Podfile`) so every slice's `minos`,
the framework `Info.plist`, and the podspec all agree. Note: changing only the env
does not bust cargo's cache — a clean rebuild is needed to re-stamp `minos`.

The `aleo_flutter` plugin vendors this xcframework; CocoaPods links, embeds and
signs the dynamic framework, so dyld loads it at app launch and its exports are
reachable at runtime — **no dead-strip and no `-force_load`** (a dynamic library's
exports are never stripped, unlike a static archive's unreferenced members).
`AleoFlutter.load()` dlopens it via `DynamicLibrary.open('AleoRust.framework/AleoRust')`.

Verify the exports survived into a built app:

```
nm -gU <App>.app/Frameworks/AleoRust.framework/AleoRust | grep -E 'ffi_abi_version|execute_proof_checked'
```

## Desktop / CI

Build from source: `cargo build --release` in `rust/aleo_ffi` →
`target/release/libaleo_rust.{so,dylib,dll}`. `DyLib.getDyLibFromCargo` points
there; tests use `ALEO_NEW_LIB=<built lib>`.

## ABI guard

Whatever the platform, the Dart layer validates the library's `ffi_abi_version`
when constructing `AleoAccount`/`AleoRecord`/`AleoProgram`/`ParameterProvisioner`
(`AleoLib.coerce`); an incompatible/stale library is rejected at load time
(`IncompatibleNativeLibraryException`). Build outputs (`android_lib/`, `ios_lib/`)
are git-ignored — they are produced on demand, not committed.
