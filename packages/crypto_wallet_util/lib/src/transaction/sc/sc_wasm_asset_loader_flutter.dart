import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

const _scWasmAssetKey =
    'packages/crypto_wallet_util/lib/src/transaction/sc/sc.wasm';

Future<Uint8List?> loadBundledScWasm() async {
  final data = await rootBundle.load(_scWasmAssetKey);
  return Uint8List.sublistView(data);
}
