# Changelog

## [Unreleased]

### Fixed

- CI: `dart analyze` no longer fails the pipeline. Manual demo / integration
  scripts under `test/` (which depend on a live node and/or the gitignored
  `test/local/config.dart`) are excluded from static analysis.
- CI: FFI-backed tests now skip gracefully via `tryLoadAleoLib()` when the
  native `aleo_rust` library is unavailable (e.g. on CI), instead of failing at
  load time. Tests that broadcast real transactions are marked as manual
  integration tests.

### Added

- `AleoLib` + `IncompatibleNativeLibraryException`: the native library's
  `ffi_abi_version` is validated when constructing `AleoAccount`, `AleoRecord`,
  `AleoProgram`, or `ParameterProvisioner` (a bare `DynamicLibrary` or an `AleoLib`
  are both accepted). An incompatible or stale library now fails loudly at load
  time instead of mis-binding a renamed symbol or an argument slot.
- Mobile loading via `DyLib.getMobileDyLib`: Android opens the per-ABI
  `libaleo_rust.so` bundled in the app's `jniLibs`; iOS uses
  `DynamicLibrary.process()` for apps that link the library into their own process.
  Build them with `rust/build_android.sh` / `rust/build_ios.sh` (no runtime download
  in v1). (The `aleo_flutter` plugin instead bundles a dynamic `AleoRust.framework`
  and loads it via `AleoFlutter.load()`.)

### Changed

- The native FFI ABI is finalized and network-aware (Phase 4). Every network-typed
  export takes a `network` (`"mainnet"`/`"testnet"`); proving goes through
  `ParameterProvisioner` (preflight → download proving keys → the checked proving
  path), so a cold parameter cache is provisioned cleanly.
- **Custom-program proving is not supported in this version (credits-only).**
  `executeProgram`, `contractExecution`, `contractFeeExecution`, and
  `executeProgramProof` now reject a non-`credits.aleo` program with
  `unsupported_feature`, deterministically and before any node I/O. The methods are
  retained for API stability; arbitrary-program support is a future version.
- `DyLib`'s `getDyLibFromCargo` paths now point at the clean-room `aleo_ffi` crate's
  build output (`../../rust/aleo_ffi/target/release/`) instead of the GPL
  `aleo_rust` crate; the artifact filename is unchanged (`libaleo_rust`).

### Deprecated

- `setUpDynamicLibrary` (the runtime library downloader / `dart run aleo_dart:setup`):
  v1 does not download the native library at runtime. Build from source on desktop
  (`DyLib.getDyLibFromCargo`) or bundle at build time on mobile
  (`DyLib.getMobileDyLib`). Its pinned source is a stale GPL-era artifact.

## [1.0.0]

- Initial release in the fx-wallet-packages monorepo.
- Imported from the standalone aleo_dart repository with full git history.
- Aleo account / record / transaction APIs via FFI to the `aleo_rust` native library.
- `dart run aleo_dart:setup` fetches a prebuilt dynamic library for the host platform.
