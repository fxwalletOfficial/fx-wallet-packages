import 'dart:typed_data';

import 'sc_wasm_asset_loader_io.dart'
    if (dart.library.ui) 'sc_wasm_asset_loader_flutter.dart'
    as platform;

/// Loads the package asset when the current runtime provides a Flutter asset
/// bundle. Dart runtimes return `null` and use the file-based fallback instead.
Future<Uint8List?> loadBundledScWasm() {
  return platform.loadBundledScWasm();
}
