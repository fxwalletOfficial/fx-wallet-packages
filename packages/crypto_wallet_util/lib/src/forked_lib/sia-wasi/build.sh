#!/bin/bash
# Build script for SC transaction library as dynamic library

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building SC transaction dynamic library..."

# Detect host platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  darwin)
    OS="darwin"
    EXT="dylib"
    ;;
  linux)
    OS="linux"
    EXT="so"
    ;;
  mingw*|msys*|cygwin*)
    OS="windows"
    EXT="dll"
    ;;
  *)
    echo "Unsupported OS: $OS"
    exit 1
    ;;
esac

case "$ARCH" in
  x86_64)
    ARCH="amd64"
    ;;
  arm64|aarch64)
    ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# Output next to the Dart bridge so it resolves via the package URI at runtime.
OUTPUT_DIR="../../transaction/sc/native"
mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/libsc_transaction_${OS}_${ARCH}.${EXT}"

echo "Building for $OS/$ARCH -> $OUTPUT_FILE"

# Build the dynamic library
CGO_ENABLED=1 GOOS="$OS" GOARCH="$ARCH" go build \
  -buildmode=c-shared \
  -o "$OUTPUT_FILE" \
  -ldflags="-s -w" \
  .

echo "✓ Build complete: $OUTPUT_FILE"
echo ""
echo "File size: $(du -h "$OUTPUT_FILE" | cut -f1)"
