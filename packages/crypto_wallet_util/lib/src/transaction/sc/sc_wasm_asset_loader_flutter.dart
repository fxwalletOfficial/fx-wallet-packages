import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'dart:ui' as ui;

const _scWasmAssetKeys = [
  // This is the key used when crypto_wallet_util is consumed by an app.
  'packages/crypto_wallet_util/lib/src/transaction/sc/sc.wasm',
  // Flutter's package-local test asset bundle uses the package-relative key.
  'lib/src/transaction/sc/sc.wasm',
];

Future<Uint8List?> loadBundledScWasm() async {
  for (final assetKey in _scWasmAssetKeys) {
    final response = Completer<ByteData?>();
    final encodedKey = utf8.encode(Uri(path: Uri.encodeFull(assetKey)).path);
    ui.PlatformDispatcher.instance.sendPlatformMessage(
      'flutter/assets',
      ByteData.sublistView(Uint8List.fromList(encodedKey)),
      response.complete,
    );
    final data = await response.future;
    if (data != null) return Uint8List.sublistView(data);
  }
  throw StateError('Flutter asset not found: ${_scWasmAssetKeys.first}');
}
