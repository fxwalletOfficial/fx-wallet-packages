#!/bin/bash
#
# Builds the aleo_ffi iOS staticlib and packages it as an xcframework (device +
# simulator). v1 links the library statically into the app and loads it via
# DynamicLibrary.process() — there is no runtime download.
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
NAME="libaleo_rust.a"

echo "Building iOS staticlib (device + simulator slices) ..."
cargo build --release --target aarch64-apple-ios      # device   (arm64)
cargo build --release --target aarch64-apple-ios-sim  # simulator (arm64)
cargo build --release --target x86_64-apple-ios       # simulator (x86_64)

mkdir -p "$OUT"

# A single fat simulator archive (arm64 + x86_64); device stays its own slice.
# Every xcframework slice MUST use the same library basename ($NAME, libaleo_rust.a)
# so the framework records one library name for all platforms. If the simulator
# slice were libaleo_rust-sim.a, Xcode/CocoaPods would emit -laleo_rust-sim for the
# simulator and the link would fail with "library 'aleo_rust' not found". Keep the
# fat archive in its own dir to avoid colliding with the device slice's $NAME.
SIM_DIR="$OUT/sim"
mkdir -p "$SIM_DIR"
SIM_FAT="$SIM_DIR/$NAME"
lipo -create \
  "target/aarch64-apple-ios-sim/release/$NAME" \
  "target/x86_64-apple-ios/release/$NAME" \
  -output "$SIM_FAT"

XCF="$OUT/AleoRust.xcframework"
rm -rf "$XCF"
xcodebuild -create-xcframework \
  -library "target/aarch64-apple-ios/release/$NAME" \
  -library "$SIM_FAT" \
  -output "$XCF"

echo
echo "Built $XCF"
echo
echo "App integration (performed in the app repo):"
echo "  1. Link AleoRust.xcframework into the app target."
echo "  2. RETAIN the FFI symbols through dead-strip — a static linker drops the"
echo "     #[no_mangle] exports that nothing in the app references directly, and"
echo "     DynamicLibrary.process() lookups would then fail at runtime. Add:"
echo "       -force_load <path>/AleoRust.xcframework/<slice>/libaleo_rust.a"
echo "     (or an -exported_symbols_list listing ffi_abi_version, execute_*_checked,"
echo "      parameter_preflight, the account/record/authorize exports, free_string)."
echo "  3. Verify on the FINAL app binary (not just the .a):"
echo "       nm -gU <app-binary> | grep -E 'ffi_abi_version|execute_proof_checked'"
echo "     Both must be present; if not, the -force_load/exported-symbols step is"
echo "     missing."
