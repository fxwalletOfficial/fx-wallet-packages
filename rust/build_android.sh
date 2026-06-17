#!/bin/bash
#
# Cross-compiles aleo_ffi to the Android per-ABI shared libraries for build-time
# bundling into an app's jniLibs. v1 does NOT download the native library at
# runtime — the app bundles these .so files and loads them with
# DynamicLibrary.open('libaleo_rust.so').
#
# No OpenSSL: workstreams A (curl) and B (ureq) removed the HTTP/TLS stack, so
# there is nothing to cross-compile or carry. The only flags needed are the 16k
# page-size link args (mandatory on Android 15+).
#
# Requirements:
#   rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
#   cargo install cargo-ndk
#   an Android NDK on ANDROID_NDK_HOME (or auto-detected by cargo-ndk)
#
# Usage: rust/build_android.sh   (output: rust/android_lib/jniLibs/<abi>/libaleo_rust.so)

set -euo pipefail

cd "$(dirname "$0")/aleo_ffi"

OUT="../android_lib/jniLibs"

# 16k page alignment for Android 15+ (applies to every target built below).
export RUSTFLAGS="-C link-arg=-Wl,-z,max-page-size=16384 -C link-arg=-Wl,-z,common-page-size=16384"

# Resolve an ELF reader: the NDK ships llvm-readelf; fall back to a system readelf
# (macOS has neither by default, so the NDK's is preferred).
readelf_bin() {
  if command -v llvm-readelf >/dev/null 2>&1; then echo llvm-readelf; return; fi
  if command -v readelf >/dev/null 2>&1; then echo readelf; return; fi
  local ndk="${ANDROID_NDK_HOME:-}"
  for f in "$ndk"/toolchains/llvm/prebuilt/*/bin/llvm-readelf; do
    [ -x "$f" ] && { echo "$f"; return; }
  done
  echo "ERROR: no readelf/llvm-readelf found (install binutils or set ANDROID_NDK_HOME)" >&2
  exit 1
}
READELF="$(readelf_bin)"

echo "Building Android ABIs (arm64-v8a, armeabi-v7a, x86_64) into $OUT ..."
cargo ndk \
  -t arm64-v8a -t armeabi-v7a -t x86_64 \
  --platform 21 \
  -o "$OUT" \
  build --release

# Every LOAD segment must be 16k-aligned (0x4000) or larger; fail the build
# otherwise. The previous script only printed a warning, so a 4k-aligned library
# (which Android 15+ rejects at load) would still "succeed".
fail=0
for so in "$OUT"/*/libaleo_rust.so; do
  bad=""
  # Each LOAD segment's Align is the last field (hex, e.g. 0x4000). Convert via
  # shell printf (portable: BSD awk on macOS lacks gawk's strtonum) and require
  # >= 16384.
  for a in $("$READELF" -lW "$so" | awk '$1=="LOAD"{print $NF}'); do
    dec=$(printf '%d' "$a" 2>/dev/null || echo 0)
    [ "$dec" -ge 16384 ] || bad="$bad $a"
  done
  if [ -n "$bad" ]; then
    echo "ERROR: $so has a LOAD segment aligned below 16k:$bad" >&2
    fail=1
  else
    echo "  OK: $so is 16k-aligned"
  fi
done
[ "$fail" -eq 0 ] || exit 1

echo "All Android ABIs built + 16k-verified. Bundle $OUT/<abi>/libaleo_rust.so into the app's jniLibs."
