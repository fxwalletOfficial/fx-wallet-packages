#!/bin/bash

# Android Cross-Compilation Script
# For building aleo_rust library for Android

echo "Starting Android cross-compilation..."

# Enter aleo_rust directory
cd aleo_rust

# Create output directories
mkdir -p ../android_lib/arm64
mkdir -p ../android_lib/x86_64
mkdir -p ../android_lib/armv7

echo "=========================================="
echo "Building ARM64 Architecture"
echo "=========================================="

export OPENSSL_INCLUDE_DIR=/home/zhun/openssl-3.1.5/android/arm64/include
export OPENSSL_LIB_DIR=/home/zhun/openssl-3.1.5/android/arm64/lib

echo "Using OpenSSL:"
echo "  Include: $OPENSSL_INCLUDE_DIR"
echo "  Lib: $OPENSSL_LIB_DIR"

echo "Starting ARM64 build..."
if cargo ndk --target aarch64-linux-android build --release; then
    echo "✅ ARM64 build successful!"
    cp target/aarch64-linux-android/release/libaleo_rust.so ../android_lib/arm64/
    echo "📁 Copied to: ../android_lib/arm64/"
else
    echo "❌ ARM64 build failed!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Building x86_64 Architecture"
echo "=========================================="

export OPENSSL_INCLUDE_DIR=/home/zhun/openssl-3.1.5/android/x86_64/include
export OPENSSL_LIB_DIR=/home/zhun/openssl-3.1.5/android/x86_64/lib

echo "Using OpenSSL:"
echo "  Include: $OPENSSL_INCLUDE_DIR"
echo "  Lib: $OPENSSL_LIB_DIR"

echo "Starting x86_64 build..."
if cargo ndk --target x86_64-linux-android build --release; then
    echo "✅ x86_64 build successful!"
    cp target/x86_64-linux-android/release/libaleo_rust.so ../android_lib/x86_64/
    echo "📁 Copied to: ../android_lib/x86_64/"
else
    echo "❌ x86_64 build failed!"
    exit 1
fi

echo ""
echo "=========================================="
echo "Building ARMv7 Architecture"
echo "=========================================="

export OPENSSL_INCLUDE_DIR=/home/zhun/openssl-3.1.5/android/armv7/include
export OPENSSL_LIB_DIR=/home/zhun/openssl-3.1.5/android/armv7/lib

echo "Using OpenSSL:"
echo "  Include: $OPENSSL_INCLUDE_DIR"
echo "  Lib: $OPENSSL_LIB_DIR"

echo "Starting ARMv7 build..."
if cargo ndk --target armv7-linux-androideabi build --release; then
    echo "✅ ARMv7 build successful!"
    cp target/armv7-linux-androideabi/release/libaleo_rust.so ../android_lib/armv7/
    echo "📁 Copied to: ../android_lib/armv7/"
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