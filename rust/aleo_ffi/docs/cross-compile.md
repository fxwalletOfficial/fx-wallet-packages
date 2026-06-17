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
| `cdylib` | `libaleo_rust.{so,dylib,dll}` | Android (.so) + desktop, `DynamicLibrary.open` |
| `staticlib` | `libaleo_rust.a` | iOS (xcframework), `DynamicLibrary.process()` |
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

Statically linked. Requirements (macOS + Xcode):

```
rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
```

`rust/build_ios.sh` builds the device slice (`aarch64-apple-ios`) + a fat simulator
slice (`aarch64-apple-ios-sim` + `x86_64-apple-ios` via `lipo`) and packages
`rust/ios_lib/AleoRust.xcframework`.

**Dead-strip retention (done in the app repo).** A static linker drops the
`#[no_mangle]` exports that nothing in the app references directly, and
`DynamicLibrary.process()` lookups would then fail at runtime. The app target must
either `-force_load` the archive or supply an `-exported_symbols_list`, then verify
on the **final app binary** (not just the `.a`):

```
nm -gU <app-binary> | grep -E 'ffi_abi_version|execute_proof_checked'
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
