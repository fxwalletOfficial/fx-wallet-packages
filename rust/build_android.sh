#!/bin/bash

# Android Cross-Compilation Script
# For building aleo_rust library for Android with 16k pages support

echo "Starting Android cross-compilation with 16k pages support..."

# Enter aleo_rust directory
# OpenSSL base path
OPENSSL_BASE_PATH="/home/zhun/openssl-3.1.5/android"

cd aleo_rust

# Create output directories
mkdir -p ../android_lib/arm64
mkdir -p ../android_lib/x86_64
mkdir -p ../android_lib/armv7

# Set 16k pages compatibility flags
export RUSTFLAGS="-C link-arg=-Wl,-z,max-page-size=16384 -C link-arg=-Wl,-z,common-page-size=16384"

echo "=========================================="
echo "Building ARM64 Architecture"
echo "=========================================="

export OPENSSL_INCLUDE_DIR=${OPENSSL_BASE_PATH}/arm64/include
export OPENSSL_LIB_DIR=${OPENSSL_BASE_PATH}/arm64/lib

echo "Using OpenSSL:"
echo "  Include: $OPENSSL_INCLUDE_DIR"
echo "  Lib: $OPENSSL_LIB_DIR"
echo "Using 16k pages flags: $RUSTFLAGS"

echo "Starting ARM64 build..."
if cargo ndk --target aarch64-linux-android build --release; then
    echo "✅ ARM64 build successful!"
    cp target/aarch64-linux-android/release/libaleo_rust.so ../android_lib/arm64/
    echo "📁 Copied to: ../android_lib/arm64/"
    
    # Verify 16k pages alignment
    echo "🔍 Verifying 16k pages alignment for ARM64..."
    readelf -l target/aarch64-linux-android/release/libaleo_rust.so | grep -E "LOAD.*0x[0-9a-f]+.*0x[0-9a-f]+.*0x[0-9a-f]+.*0x4000" && echo "✅ ARM64: 16k pages aligned" || echo "⚠️  ARM64: May not be fully 16k aligned"
else
    echo "❌ ARM64 build failed!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Building x86_64 Architecture"
echo "=========================================="

export OPENSSL_INCLUDE_DIR=${OPENSSL_BASE_PATH}/x86_64/include
export OPENSSL_LIB_DIR=${OPENSSL_BASE_PATH}/x86_64/lib

echo "Using OpenSSL:"
echo "  Include: $OPENSSL_INCLUDE_DIR"
echo "  Lib: $OPENSSL_LIB_DIR"
echo "Using 16k pages flags: $RUSTFLAGS"

echo "Starting x86_64 build..."
if cargo ndk --target x86_64-linux-android build --release; then
    echo "✅ x86_64 build successful!"
    cp target/x86_64-linux-android/release/libaleo_rust.so ../android_lib/x86_64/
    echo "📁 Copied to: ../android_lib/x86_64/"
    
    # Verify 16k pages alignment
    echo "🔍 Verifying 16k pages alignment for x86_64..."
    readelf -l target/x86_64-linux-android/release/libaleo_rust.so | grep -E "LOAD.*0x[0-9a-f]+.*0x[0-9a-f]+.*0x[0-9a-f]+.*0x4000" && echo "✅ x86_64: 16k pages aligned" || echo "⚠️  x86_64: May not be fully 16k aligned"
else
    echo "❌ x86_64 build failed!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Building ARMv7 Architecture"
echo "=========================================="

export OPENSSL_INCLUDE_DIR=${OPENSSL_BASE_PATH}/armv7/include
export OPENSSL_LIB_DIR=${OPENSSL_BASE_PATH}/armv7/lib

echo "Using OpenSSL:"
echo "  Include: $OPENSSL_INCLUDE_DIR"
echo "  Lib: $OPENSSL_LIB_DIR"
echo "Using 16k pages flags: $RUSTFLAGS"

echo "Starting ARMv7 build..."
if cargo ndk --target armv7-linux-androideabi build --release; then
    echo "✅ ARMv7 build successful!"
    cp target/armv7-linux-androideabi/release/libaleo_rust.so ../android_lib/armv7/
    echo "📁 Copied to: ../android_lib/armv7/"
    
    # Verify 16k pages alignment
    echo "🔍 Verifying 16k pages alignment for ARMv7..."
    readelf -l target/armv7-linux-androideabi/release/libaleo_rust.so | grep -E "LOAD.*0x[0-9a-f]+.*0x[0-9a-f]+.*0x[0-9a-f]+.*0x4000" && echo "✅ ARMv7: 16k pages aligned" || echo "⚠️  ARMv7: May not be fully 16k aligned"
else
    echo "❌ ARMv7 build failed!"
    exit 1
fi

echo ""
echo "=========================================="
echo "🎉 All architectures built successfully!"
echo "=========================================="

echo "Output file locations:"
echo "  ARM64:   android_lib/arm64/libaleo_rust.so"
echo "  x86_64:  android_lib/x86_64/libaleo_rust.so"
echo "  ARMv7:   android_lib/armv7/libaleo_rust.so"

echo ""
echo "📋 16k Pages Compatibility Summary:"
echo "All libraries have been built with 16k pages support flags:"
echo "  - max-page-size=16384"
echo "  - common-page-size=16384"
echo "This ensures compatibility with Android devices using 16k memory pages."