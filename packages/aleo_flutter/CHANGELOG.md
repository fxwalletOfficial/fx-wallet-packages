## 0.0.1

* Initial skeleton. Flutter FFI plugin that bundles the prebuilt `aleo_rust`
  native library (Android per-ABI `.so`, iOS static `xcframework`) at build time
  and exposes the `aleo_dart` API via `AleoFlutter.load()`.
* Build-time fetch from a pinned GitHub Release with SHA-256 verification against
  an in-package manifest, plus a local-build override for development. No runtime
  download; runtime load is offline-safe.
* iOS static-library dead-strip retention via `-force_load` (see
  `rust/aleo_ffi/docs/pr6a-impl-notes.md`).
