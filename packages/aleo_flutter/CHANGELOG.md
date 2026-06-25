## 0.0.1

* Pinned the artifact manifest SHA-256 values to the published
  [`aleo_ffi-v1.0.0`](https://github.com/fxwalletOfficial/fx-wallet-packages/releases/tag/aleo_ffi-v1.0.0)
  GitHub Release (Android `libaleo_rust-android.zip`, iOS
  `AleoRust.xcframework.zip`), so the build-time download path is now active
  (was fail-closed with all-zero placeholders before the release existed).
* Initial skeleton. Flutter FFI plugin that bundles the prebuilt `aleo_rust`
  native library (Android per-ABI `.so`, iOS dynamic `AleoRust.framework`) at
  build time and exposes the `aleo_dart` API via `AleoFlutter.load()`.
* Build-time fetch from a pinned GitHub Release with SHA-256 verification against
  an in-package manifest, plus a local-build override for development. No runtime
  download; runtime load is offline-safe.
* iOS ships a dynamic `AleoRust.framework` (no static-lib dead-strip / `-force_load`);
  `AleoFlutter.load()` dlopens it. See `rust/aleo_ffi/docs/pr6a-impl-notes.md`.
