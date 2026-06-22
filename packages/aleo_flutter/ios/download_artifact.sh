#!/usr/bin/env bash
#
# Provides ios/Frameworks/AleoRust.xcframework for the podspec's
# vendored_frameworks. Runs from the pod root (packages/aleo_flutter/ios) via the
# podspec's prepare_command.
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
URL="$(mfval aleoIosArtifactUrl)"
SHA="$(mfval aleoIosArtifactSha256)"

mkdir -p "$DEST"
rm -rf "$XCF"

# 1) Local build.
LOCAL="${ALEO_FFI_IOS_XCFRAMEWORK:-../../../rust/ios_lib/AleoRust.xcframework}"
if [ -d "$LOCAL" ]; then
  echo "aleo_flutter[ios]: using local xcframework $LOCAL"
  cp -R "$LOCAL" "$XCF"
  exit 0
fi

# 2) Download + verify.
if [ "$SHA" = "$UNSET" ]; then
  echo "ERROR: no local xcframework ($LOCAL) and the manifest SHA-256 is unset." >&2
  echo "       Build it (rust/build_ios.sh), set ALEO_FFI_IOS_XCFRAMEWORK, or pin" >&2
  echo "       the release hash in lib/src/artifact_manifest.dart." >&2
  exit 1
fi
ZIP="$DEST/AleoRust.xcframework.zip"
echo "aleo_flutter[ios]: downloading $URL"
curl -fSL "$URL" -o "$ZIP"
ACTUAL="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
if [ "$ACTUAL" != "$SHA" ]; then
  echo "ERROR: SHA-256 mismatch for $URL (got $ACTUAL, want $SHA)" >&2
  exit 1
fi
unzip -q -o "$ZIP" -d "$DEST"
rm -f "$ZIP"
