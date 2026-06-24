#!/bin/bash
#
# Builds aleo_ffi as an iOS DYNAMIC framework and packages it as an xcframework
# (device + simulator).
#
# v2 ships a DYNAMIC framework, not a static lib. The embedded framework is loaded
# at app launch, so its exported symbols stay intact and are reachable via
# DynamicLibrary.process()/open() with NO dead-strip and NO -force_load. The
# static approach could not make the #[no_mangle] exports survive a clean
# CocoaPods build (the linker dropped unreferenced archive members, and the
# -force_load workaround referenced a build-time intermediate that broke clean
# builds). See packages/aleo_flutter and rust/aleo_ffi/docs/pr6a-impl-notes.md.
#
# No OpenSSL: workstreams A (curl) and B (ureq) removed the HTTP/TLS stack.
#
# Requirements (macOS + Xcode):
#   rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
#
# Usage: rust/build_ios.sh   (output: rust/ios_lib/AleoRust.xcframework)

set -euo pipefail

cd "$(dirname "$0")/aleo_ffi"

OUT="../ios_lib"
DYLIB="libaleo_rust.dylib"          # cargo's cdylib output filename
FW="AleoRust"                       # framework bundle + binary name
INSTALL_NAME="@rpath/$FW.framework/$FW"

# iOS deployment target. Matches the fx-wallet app (ios/Podfile platform :ios,
# '15.5'); set explicitly so every slice's Mach-O minos is intentional (not
# rustc's default ~10) and consistent with the podspec + framework Info.plist.
# The arm64 simulator slice is intrinsically >= 14, so 15.5 is fully consistent.
MIN_IOS="15.5"
export IPHONEOS_DEPLOYMENT_TARGET="$MIN_IOS"

# cargo does NOT track IPHONEOS_DEPLOYMENT_TARGET, so a cached build keeps its old
# Mach-O minos even after MIN_IOS changes — which would wrap a stale-minos binary
# in a framework that DECLARES MIN_IOS. Force a clean rebuild of the iOS targets
# whenever MIN_IOS differs from the last successful build (tracked by a stamp). The
# post-build check is the backstop that fails the build if any slice still differs.
STAMP="target/.aleo_ios_minos"
if [ "$(cat "$STAMP" 2>/dev/null || true)" != "$MIN_IOS" ]; then
  echo "iOS target is $MIN_IOS (stamp: '$(cat "$STAMP" 2>/dev/null || true)') — cleaning iOS target dirs so the new minos is stamped ..."
  rm -rf target/aarch64-apple-ios/release \
         target/aarch64-apple-ios-sim/release \
         target/x86_64-apple-ios/release
  rm -f "$STAMP"
fi

echo "Building iOS dynamic library (device + simulator slices) for iOS $MIN_IOS ..."
cargo build --release --target aarch64-apple-ios      # device   (arm64)
cargo build --release --target aarch64-apple-ios-sim  # simulator (arm64)
cargo build --release --target x86_64-apple-ios       # simulator (x86_64)

rm -rf "$OUT"
mkdir -p "$OUT"

# Assemble a flat iOS .framework bundle ($dir/AleoRust.framework) from a dylib.
# iOS frameworks are flat (no Versions/), so: the binary at <fw>/AleoRust plus a
# minimal Info.plist. The dylib's install name is rewritten to @rpath so the app's
# runpath (@executable_path/Frameworks) resolves the embedded copy.
make_framework() {
  local dylib="$1" dir="$2" platform="$3"
  local fwdir="$dir/$FW.framework"
  rm -rf "$fwdir"; mkdir -p "$fwdir"
  cp "$dylib" "$fwdir/$FW"
  install_name_tool -id "$INSTALL_NAME" "$fwdir/$FW"
  cat > "$fwdir/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>$FW</string>
  <key>CFBundleIdentifier</key><string>com.fxwallet.AleoRust</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundleName</key><string>$FW</string>
  <key>CFBundlePackageType</key><string>FMWK</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>MinimumOSVersion</key><string>$MIN_IOS</string>
  <key>CFBundleSupportedPlatforms</key><array><string>$platform</string></array>
</dict>
</plist>
PLIST
}

# Device framework (arm64).
make_framework "target/aarch64-apple-ios/release/$DYLIB" "$OUT/device" "iPhoneOS"

# Simulator framework: a fat arm64 + x86_64 dylib.
SIMTMP="$OUT/.sim-tmp"; mkdir -p "$SIMTMP"
lipo -create \
  "target/aarch64-apple-ios-sim/release/$DYLIB" \
  "target/x86_64-apple-ios/release/$DYLIB" \
  -output "$SIMTMP/$DYLIB"
make_framework "$SIMTMP/$DYLIB" "$OUT/sim" "iPhoneSimulator"

XCF="$OUT/AleoRust.xcframework"
rm -rf "$XCF"
xcodebuild -create-xcframework \
  -framework "$OUT/device/$FW.framework" \
  -framework "$OUT/sim/$FW.framework" \
  -output "$XCF"

rm -rf "$SIMTMP" "$OUT/device" "$OUT/sim"

# Backstop for the cargo-cache gotcha above: verify EVERY slice's Mach-O minos
# actually equals $MIN_IOS, so we never ship a stale-minos binary inside a
# framework that declares $MIN_IOS. (Same fail-loudly spirit as build_android.sh's
# 16k-alignment check.)
slice_minos() {  # $1 = mach-o, $2 = arch — handles LC_BUILD_VERSION + LC_VERSION_MIN_IPHONEOS
  otool -arch "$2" -l "$1" 2>/dev/null | awk '
    /^ *cmd LC_BUILD_VERSION/        {bv=1; vm=0}
    /^ *cmd LC_VERSION_MIN_IPHONEOS/ {vm=1; bv=0}
    bv && /^ *minos /   {print $2; exit}
    vm && /^ *version / {print $2; exit}'
}
minos_fail=0
check_minos() {  # $1 = framework binary, $2... = archs
  local bin="$1"; shift
  local arch got
  for arch in "$@"; do
    got="$(slice_minos "$bin" "$arch")"
    [ "$got" = "$MIN_IOS" ] || { echo "ERROR: $bin [$arch] minos=${got:-none}, expected $MIN_IOS" >&2; minos_fail=1; }
  done
}
check_minos "$XCF/ios-arm64/$FW.framework/$FW" arm64
check_minos "$XCF/ios-arm64_x86_64-simulator/$FW.framework/$FW" arm64 x86_64
if [ "$minos_fail" != 0 ]; then
  echo "minos mismatch — cargo reused a stale build. Clean and rerun:" >&2
  echo "  rm -rf rust/aleo_ffi/target/{aarch64-apple-ios,aarch64-apple-ios-sim,x86_64-apple-ios}/release && rust/build_ios.sh" >&2
  exit 1
fi

# Record the deployment target only after a verified-correct build.
mkdir -p target && printf '%s' "$MIN_IOS" > "$STAMP"

echo
echo "Built $XCF (dynamic frameworks: device arm64 + simulator arm64/x86_64; minos $MIN_IOS)"
echo
echo "Symbols are intact in the dynamic binary (no dead-strip); verify with:"
echo "  nm -gU \"$XCF\"/ios-arm64*/$FW.framework/$FW | grep -E 'ffi_abi_version|execute_proof_checked'"
