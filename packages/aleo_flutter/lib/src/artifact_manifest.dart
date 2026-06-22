/// Build-time artifact manifest: the prebuilt `aleo_rust` native-library assets
/// this plugin version bundles, pinned to a GitHub Release tag and verified by
/// SHA-256.
///
/// This file is the **integrity anchor** (PR6 spec §5): the Android Gradle task
/// (`android/build.gradle` → `download_artifact.sh`) and the iOS podspec
/// (`ios/download_artifact.sh`) read the URL/SHA-256 from here and verify the
/// downloaded asset against it before bundling. A same-origin checksum is not an
/// anchor — the hash must be pinned in the package, here.
///
/// The build scripts parse these as plain `const String NAME = '...'` literals
/// (no string interpolation), so keep them literal and flat.
///
/// VERSION TRIPLE-BINDING (spec §5, easy-to-miss #1): this plugin version ↔ the
/// [aleoFfiReleaseTag] it downloads ↔ the Rust `ffi_abi_version` baked into that
/// build must all line up. The scripts fetch a PINNED tag, never "latest";
/// [aleoFfiAbiVersion] is asserted against `AleoLib.expectedAbiVersion` in the
/// package test, and the native library's own `ffi_abi_version` is the runtime
/// backstop.
library;

/// The native ABI version the bundled library must report. Matches
/// `AleoLib.expectedAbiVersion` (aleo_dart) and the Rust `ffi_abi_version`.
const int aleoFfiAbiVersion = 1;

/// The GitHub Release tag the bundled artifacts come from. Namespaced with the
/// `aleo_ffi-` prefix so it does not collide with other monorepo packages'
/// future releases (spec §7.3).
const String aleoFfiReleaseTag = 'aleo_ffi-v1.0.0';

/// iOS: the static `AleoRust.xcframework` (device arm64 + simulator arm64/x86_64
/// fat), zipped.
const String aleoIosArtifactUrl =
    'https://github.com/fxwalletOfficial/fx-wallet-packages/releases/download/aleo_ffi-v1.0.0/AleoRust.xcframework.zip';

/// Android: the three per-ABI `<abi>/libaleo_rust.so` (arm64-v8a, armeabi-v7a,
/// x86_64), zipped.
const String aleoAndroidArtifactUrl =
    'https://github.com/fxwalletOfficial/fx-wallet-packages/releases/download/aleo_ffi-v1.0.0/libaleo_rust-android.zip';

/// SHA-256 (lowercase hex) the downloaded iOS asset must hash to.
///
/// Placeholder (all-zero) until the first release is built and uploaded — PR6b
/// wires the release pipeline and pins these. Until then the build scripts treat
/// an all-zero hash as "unset" and require a local build (the LOCAL-override
/// path; see `pr6a-impl-notes.md`).
const String aleoIosArtifactSha256 =
    '0000000000000000000000000000000000000000000000000000000000000000';

/// SHA-256 (lowercase hex) the downloaded Android asset must hash to. See
/// [aleoIosArtifactSha256].
const String aleoAndroidArtifactSha256 =
    '0000000000000000000000000000000000000000000000000000000000000000';
