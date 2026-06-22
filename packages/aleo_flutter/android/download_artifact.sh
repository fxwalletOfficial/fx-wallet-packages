#!/usr/bin/env bash
#
# Stages the prebuilt per-ABI libaleo_rust.so for the Android plugin's jniLibs.
#
# Resolution order:
#   1. LOCAL build (dev/CI before a release exists): $ALEO_FFI_ANDROID_JNILIBS, or
#      the rust/build_android.sh default output (rust/android_lib/jniLibs).
#   2. DOWNLOAD the pinned GitHub Release asset and verify its SHA-256 against the
#      in-package manifest (lib/src/artifact_manifest.dart).
#
# Usage (from android/build.gradle's fetchAleoNative task):
#   download_artifact.sh <out_dir>      # populates <out_dir>/<abi>/libaleo_rust.so
set -euo pipefail
cd "$(dirname "$0")"

OUT="${1:?output dir required}"
MANIFEST="../lib/src/artifact_manifest.dart"
ABIS="arm64-v8a armeabi-v7a x86_64"
UNSET="0000000000000000000000000000000000000000000000000000000000000000"

# Pull a `const String NAME = '...'` literal out of the Dart manifest, tolerating
# the line wrap dart format may insert between `=` and the string. perl is present
# on macOS and the GitHub ubuntu/macos runners.
mfval() { ALEO_KEY="$1" perl -0777 -ne 'print $1 if /const String \Q$ENV{ALEO_KEY}\E\s*=\s*'\''([^'\'']*)'\''/' "$MANIFEST"; }

# SHA-256 of a file: prefer sha256sum (canonical on Linux, where this runs); fall
# back to `shasum -a 256` (macOS). One of the two is always present on dev + CI.
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}';
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}
URL="$(mfval aleoAndroidArtifactUrl)"
SHA="$(mfval aleoAndroidArtifactSha256)"

rm -rf "$OUT"
mkdir -p "$OUT"

# 1) Local build. Any present ABI is copied; a PARTIAL local build (e.g. only
# arm64-v8a, to speed up iteration) is accepted on purpose — but then an
# emulator/device on a missing ABI fails at runtime (dlopen) rather than at build
# time. Release builds (the download path) always carry all three ABIs.
LOCAL="${ALEO_FFI_ANDROID_JNILIBS:-../../../rust/android_lib/jniLibs}"
if [ -d "$LOCAL" ]; then
  echo "aleo_flutter[android]: using local jniLibs $LOCAL"
  found=0
  for abi in $ABIS; do
    if [ -f "$LOCAL/$abi/libaleo_rust.so" ]; then
      mkdir -p "$OUT/$abi"
      cp "$LOCAL/$abi/libaleo_rust.so" "$OUT/$abi/"
      found=1
    fi
  done
  [ "$found" = 1 ] || { echo "ERROR: $LOCAL has no <abi>/libaleo_rust.so" >&2; exit 1; }
  exit 0
fi

# 2) Download + verify.
if [ "$SHA" = "$UNSET" ]; then
  echo "ERROR: no local jniLibs ($LOCAL) and the manifest SHA-256 is unset." >&2
  echo "       Build them (rust/build_android.sh), set ALEO_FFI_ANDROID_JNILIBS," >&2
  echo "       or pin the release hash in lib/src/artifact_manifest.dart." >&2
  exit 1
fi
ZIP="$OUT/android.zip"
echo "aleo_flutter[android]: downloading $URL"
curl -fSL "$URL" -o "$ZIP"
ACTUAL="$(sha256_of "$ZIP")"
if [ "$ACTUAL" != "$SHA" ]; then
  echo "ERROR: SHA-256 mismatch for $URL (got $ACTUAL, want $SHA)" >&2
  exit 1
fi
# The release zip contains <abi>/libaleo_rust.so at its top level.
unzip -q -o "$ZIP" -d "$OUT"
rm -f "$ZIP"
# A release artifact MUST carry every ABI (unlike the lenient local-build path):
# a partial zip would otherwise pass and leave some devices failing dlopen at
# runtime instead of failing the build here.
for abi in $ABIS; do
  [ -f "$OUT/$abi/libaleo_rust.so" ] || {
    echo "ERROR: $URL is missing $abi/libaleo_rust.so (release must carry all ABIs: $ABIS)" >&2
    exit 1; }
done
