import 'dart:typed_data';

import 'sc_wasm_asset_test_support_io.dart'
    if (dart.library.ui) 'sc_wasm_asset_test_support_flutter.dart'
    as platform;

void configureScWasmAssetForTest(Uint8List wasmBytes) {
  platform.configureScWasmAssetForTest(wasmBytes);
}

void clearScWasmAssetForTest() {
  platform.clearScWasmAssetForTest();
}
