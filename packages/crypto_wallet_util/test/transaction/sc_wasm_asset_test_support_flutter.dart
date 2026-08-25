import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _scWasmAssetKey =
    'packages/crypto_wallet_util/lib/src/transaction/sc/sc.wasm';

void configureScWasmAssetForTest(Uint8List wasmBytes) {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
        if (message == null) return null;
        final key = utf8.decode(
          message.buffer.asUint8List(
            message.offsetInBytes,
            message.lengthInBytes,
          ),
        );
        if (key != _scWasmAssetKey) return null;
        return ByteData.sublistView(wasmBytes);
      });
}

void clearScWasmAssetForTest() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', null);
}
