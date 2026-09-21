#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/../../transaction/sc/sc.wasm"

cd "$SCRIPT_DIR"
echo "Building SC WASI module -> $OUTPUT_FILE"
CGO_ENABLED=0 GOOS=wasip1 GOARCH=wasm go build \
  -buildmode=c-shared \
  -o "$OUTPUT_FILE" \
  -ldflags="-s -w" \
  .

echo "SC WASI build complete"
