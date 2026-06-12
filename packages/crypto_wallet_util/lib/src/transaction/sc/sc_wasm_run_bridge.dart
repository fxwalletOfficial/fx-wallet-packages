import 'dart:convert';
import 'dart:typed_data';

import 'package:wasd/wasd.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_bridge.dart';

class ScWasmRunBridge extends ScWasmBridgeBase {
  final Uint8List _wasmBytes;

  Instance? _instance;
  Memory? _memory;

  ScWasmRunBridge(this._wasmBytes);

  void _ensureInitialized() {
    if (_instance != null) return;

    final module = Module(_wasmBytes.buffer);
    final wasi = WASI(preopens: {});
    final instance = Instance(module, wasi.imports);
    wasi.initialize(instance);
    _instance = instance;

    final memExport = _instance!.exports['memory']! as MemoryImportExportValue;
    _memory = memExport.ref;
  }

  WasmFunction _getFunc(String name) =>
      (_instance!.exports[name]! as FunctionImportExportValue).ref;

  int _toInt(Object? value) {
    return switch (value) {
      int v => v,
      BigInt v => v.toInt(),
      num v => v.toInt(),
      _ =>
        throw StateError(
          'Expected WASM integer result, got ${value.runtimeType}.',
        ),
    };
  }

  @override
  Future<String> processJson(String jsonString) async {
    _ensureInitialized();
    final memory = _memory!;
    final bytes = utf8.encode(jsonString);

    final alloc = _getFunc('alloc');
    final ptr = _toInt(alloc([bytes.length]));
    memory.buffer.asUint8List().setRange(ptr, ptr + bytes.length, bytes);

    try {
      final packed = _toInt(
        _getFunc('getUnsignedV2Transaction')([ptr, bytes.length]),
      );
      final resultPtr = _toInt(_getFunc('resultPtr')([packed]));
      final resultLen = _toInt(_getFunc('resultLen')([packed]));

      final resultBytes = memory.buffer.asUint8List().sublist(
        resultPtr,
        resultPtr + resultLen,
      );
      _getFunc('release')([resultPtr]);

      return utf8.decode(resultBytes);
    } finally {
      _getFunc('release')([ptr]);
    }
  }

  void dispose() {
    _instance = null;
    _memory = null;
  }
}
