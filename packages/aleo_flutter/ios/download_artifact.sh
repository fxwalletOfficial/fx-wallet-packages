#!/usr/bin/env bash
#
# Provides ios/Frameworks/AleoRust.xcframework for the podspec's
# vendored_frameworks. Invoked from the podspec BODY during `pod install` (not
# prepare_command, which CocoaPods skips for Flutter's :path development pods).
#
# Resolution order:
#   1. LOCAL build (dev/CI before a release exists): $ALEO_FFI_IOS_XCFRAMEWORK, or
#      the rust/build_ios.sh default output (rust/ios_lib/AleoRust.xcframework).
#   2. DOWNLOAD the pinned GitHub Release asset and verify its SHA-256 against the
#      in-package manifest (lib/src/artifact_manifest.dart).
set -euo pipefail
cd "$(dirname "$0")"

DEST="Frameworks"
XCF="$DEST/AleoRust.xcframework"
MANIFEST="../lib/src/artifact_manifest.dart"
UNSET="0000000000000000000000000000000000000000000000000000000000000000"

# Pull a `const String NAME = '...'` literal out of the Dart manifest, tolerating
# the line wrap dart format may insert between `=` and the string. perl is present
# on macOS and the GitHub ubuntu/macos runners.
mfval() { ALEO_KEY="$1" perl -0777 -ne 'print $1 if /const String \Q$ENV{ALEO_KEY}\E\s*=\s*'\''([^'\'']*)'\''/' "$MANIFEST"; }

# SHA-256 of a file: prefer sha256sum (canonical on Linux); fall back to
# `shasum -a 256` (macOS). One of the two is always present on dev + CI.
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}';
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}
URL="$(mfval aleoIosArtifactUrl)"
SHA="$(mfval aleoIosArtifactSha256)"

mkdir -p "$DEST"
STAMP="$DEST/.provisioned-sha"

# 1) Local build.
LOCAL="${ALEO_FFI_IOS_XCFRAMEWORK:-../../../rust/ios_lib/AleoRust.xcframework}"
if [ -d "$LOCAL" ]; then
  # Validate it really is an xcframework (symmetry with the Android ABI check) so
  # a truncated local build fails here, not as an opaque link error in stage 2.
  [ -f "$LOCAL/Info.plist" ] || { echo "ERROR: $LOCAL is not a valid xcframework (no Info.plist)" >&2; exit 1; }
  echo "aleo_flutter[ios]: using local xcframework $LOCAL"
  rm -rf "$XCF"; cp -R "$LOCAL" "$XCF"
  rm -f "$STAMP"   # local builds aren't sha-pinned; don't let a stale stamp cache them
  exit 0
fi

# 2) Download + verify (cached across repeated pod-install evaluations by a stamp).
if [ "$SHA" = "$UNSET" ]; then
  echo "ERROR: no local xcframework ($LOCAL) and the manifest SHA-256 is unset." >&2
  echo "       Build it (rust/build_ios.sh), set ALEO_FFI_IOS_XCFRAMEWORK, or pin" >&2
  echo "       the release hash in lib/src/artifact_manifest.dart." >&2
  exit 1
fi
# The podspec body re-runs on every `pod install` (and CocoaPods may evaluate it
# more than once); skip the re-download when the provisioned framework already
# matches the pinned SHA.
if [ -d "$XCF" ] && [ "$(cat "$STAMP" 2>/dev/null)" = "$SHA" ]; then
  echo "aleo_flutter[ios]: xcframework already provisioned (sha matches), skipping"
  exit 0
fi
ZIP="$DEST/AleoRust.xcframework.zip"
echo "aleo_flutter[ios]: downloading $URL"
curl -fSL "$URL" -o "$ZIP"
ACTUAL="$(sha256_of "$ZIP")"
if [ "$ACTUAL" != "$SHA" ]; then
  echo "ERROR: SHA-256 mismatch for $URL (got $ACTUAL, want $SHA)" >&2
  rm -f "$ZIP"; exit 1
fi
rm -rf "$XCF"
unzip -q -o "$ZIP" -d "$DEST"
rm -f "$ZIP"
# The release zip must contain AleoRust.xcframework at its top level.
[ -d "$XCF" ] || { echo "ERROR: $URL did not contain AleoRust.xcframework at top level" >&2; exit 1; }
echo "$SHA" > "$STAMP"
