# Releasing the aleo_rust native libraries (aleo_flutter)

The native libraries are built and published by CI
([`.github/workflows/release-aleo.yml`](../../.github/workflows/release-aleo.yml))
on a `aleo_ffi-v*` tag, then consumed at build time by the plugin's fetch step
(the Android Gradle `fetchAleoNative` task / the iOS podspec's
`download_artifact.sh`), which verifies them against the SHA-256 pinned in
[`lib/src/artifact_manifest.dart`](lib/src/artifact_manifest.dart).

## Version triple-binding (don't break it)

Three things must line up (PR6 spec §5):

1. the plugin version (`pubspec.yaml`),
2. the release tag it downloads (`aleoFfiReleaseTag` in the manifest), and
3. the `ffi_abi_version` baked into that native build (`aleoFfiAbiVersion`, asserted
   against `AleoLib.expectedAbiVersion` by the package test).

The manifest downloads a **pinned tag**, never "latest".

## Cutting a release

There is a deliberate two-step order: the binary is built from the tag first, then
its SHA-256 is pinned back into the manifest (a checksum can't be known before the
artifact exists).

1. **Prepare the manifest.** Bump `aleoFfiReleaseTag` (and `aleoFfiAbiVersion` if
   the Rust ABI changed) in `lib/src/artifact_manifest.dart`, and the plugin
   `version` in `pubspec.yaml`. Leave the SHA-256 fields as-is for now.
2. **Tag + push** `aleo_ffi-vX.Y.Z`. CI builds the Android `.so` (all ABIs,
   16k-aligned) and the iOS dynamic `AleoRust.xcframework`, generates
   `THIRD_PARTY_LICENSES`, and creates the GitHub Release with the assets
   (`libaleo_rust-android.zip`, `AleoRust.xcframework.zip`, `THIRD_PARTY_LICENSES`,
   `SHA256SUMS`). The SHA-256 are also in the release notes.
3. **Pin the SHA-256.** From the release notes / `SHA256SUMS`:
   ```
   tool/pin_artifact_sha.sh <android-sha256> <ios-sha256>
   ```
   (or edit `aleoAndroidArtifactSha256` / `aleoIosArtifactSha256` by hand), then
   `dart format .`, commit, and push.
4. **Consume.** The wallet app pins the plugin git dependency at that commit (the
   one whose manifest carries the real SHA-256). The plugin's fetch step (Android
   Gradle / iOS podspec) then fetches and verifies the assets at build time.

A re-tag is only needed if step 1/2 produced a wrong artifact; the SHA-256 commit
in step 3 rides the branch, not the tag.

## Notes

- The fetch step treats an all-zero SHA-256 as "unset" and requires a local build
  instead — so before step 3 a consumer must build locally (`rust/build_*.sh`) or
  the build fails closed (never silently unverified).
- Asset names and zip layout are a contract with the plugin's fetch step
  (`<abi>/libaleo_rust.so` at the zip top level for Android; `AleoRust.xcframework`
  at the top level for iOS). Don't rename without updating both.
- Runners are GitHub-hosted (free on a public repo): `ubuntu-latest` + NDK for
  Android, `macos-latest` + Xcode for iOS.
- Build-tool versions are **pinned** for reproducible release binaries: the Rust
  toolchain via `rust/rust-toolchain.toml`, `cargo-ndk 4.1.2`, and
  `cargo-about 0.9.0` (whose template fields `about.hbs` is written against — note
  the license body uses the triple-stash `{{{text}}}` so the asset is verbatim,
  not HTML-escaped). Bump any of these deliberately and re-verify the artifacts +
  the generated `THIRD_PARTY_LICENSES` before tagging.
