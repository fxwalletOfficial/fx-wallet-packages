#!/usr/bin/env bash
#
# Pin the released artifacts' SHA-256 into lib/src/artifact_manifest.dart after a
# release. Read the two values from the GitHub Release notes / SHA256SUMS produced
# by .github/workflows/release-aleo.yml (see RELEASING.md).
#
# Usage: tool/pin_artifact_sha.sh <android-sha256> <ios-sha256>
#   <android-sha256> = sha256 of libaleo_rust-android.zip
#   <ios-sha256>     = sha256 of AleoRust.xcframework.zip
set -euo pipefail

cd "$(dirname "$0")/.."          # packages/aleo_flutter
MANIFEST="lib/src/artifact_manifest.dart"

ANDROID="${1:-}"; IOS="${2:-}"
hex64='^[0-9a-f]{64}$'
[[ "$ANDROID" =~ $hex64 ]] || { echo "ERROR: android sha must be 64 lowercase hex, got '$ANDROID'" >&2; exit 1; }
[[ "$IOS"     =~ $hex64 ]] || { echo "ERROR: ios sha must be 64 lowercase hex, got '$IOS'" >&2; exit 1; }

# Replace the 64-hex value after each const (perl -0777 tolerates the line wrap
# dart format inserts between `=` and the string literal).
perl -0777 -i -pe "s/(const String aleoAndroidArtifactSha256\\s*=\\s*')[0-9a-f]{64}(')/\${1}${ANDROID}\${2}/" "$MANIFEST"
perl -0777 -i -pe "s/(const String aleoIosArtifactSha256\\s*=\\s*')[0-9a-f]{64}(')/\${1}${IOS}\${2}/" "$MANIFEST"

echo "Pinned in $MANIFEST:"
echo "  aleoAndroidArtifactSha256 = $ANDROID"
echo "  aleoIosArtifactSha256     = $IOS"
echo "Now: dart format . && commit. (See RELEASING.md.)"
