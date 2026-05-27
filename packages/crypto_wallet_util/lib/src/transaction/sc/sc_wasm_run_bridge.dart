import 'dart:convert';
import 'dart:typed_data';

import 'package:wasm_run/wasm_run.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_bridge.dart';

/// Concrete WASM bridge backed by [wasm_run](https://pub.dev/packages/wasm_run).
///
/// Uses [wasmtime](https://wasmtime.dev/) (native) or [wasmi](https://github.com/paritytech/wasmi)
/// to execute [sc.wasm] for processing unsigned transactions with signing
/// digests.
///
/// Construction:
/// ```dart
/// final wasmBytes = await rootBundle.load('assets/sc.wasm');
/// final bridge = ScWasmRunBridge(wasmBytes.buffer.asUint8List());
/// final builder = ScTransactionBuilder(wasmBridge: bridge);
/// ```
class ScWasmRunBridge extends ScWasmBridgeBase {
  final Uint8List _wasmBytes;

  /// Cached WASM instance; lazily compiled & instantiated on first use.
  WasmInstance? _instance;
  WasmMemory? _memory;

  ScWasmRunBridge(this._wasmBytes);

  Future<void> _ensureInitialized() async {
    if (_instance != null) return;

    final module = await compileWasmModule(_wasmBytes);
    final builder = module.builder(
      wasiConfig: WasiConfig(
        preopenedDirs: const [],
        webBrowserFileSystem: const {},
      ),
    );
    _instance = await builder.build();
    _memory = _instance!.getMemory('memory');

    if (_memory == null) {
      throw StateError('WASM module does not export a "memory" instance');
    }
  }

  @override
  Future<String> processJson(String jsonString) async {
    await _ensureInitialized();
    final instance = _instance!;
    final memory = _memory!;

    final bytes = utf8.encode(jsonString);

    // 1. Allocate WASM memory and write the input JSON
    final alloc = instance.getFunction('alloc')!;
    final ptr = alloc.inner(bytes.length) as int;
    memory.view.setRange(ptr, ptr + bytes.length, bytes);

    try {
      // 2. Call the main processing function
      final getUnsignedV2 = instance.getFunction('getUnsignedV2Transaction')!;
      final packedResult = getUnsignedV2.inner(ptr, bytes.length) as int;

      // 3. Extract the result pointer and length
      final resultPtrFn = instance.getFunction('resultPtr')!;
      final resultLenFn = instance.getFunction('resultLen')!;
      final resultPtr = resultPtrFn.inner(packedResult) as int;
      final resultLen = resultLenFn.inner(packedResult) as int;

      // 4. Read the result bytes, decode, and release the result memory
      final resultBytes = memory.view.sublist(resultPtr, resultPtr + resultLen);
      instance.getFunction('release')!.inner(resultPtr);

      return utf8.decode(resultBytes);
    } finally {
      // 5. Always release the input memory
      instance.getFunction('release')!.inner(ptr);
    }
  }

  /// Release the underlying WASM instance resources.
  /// Call when the bridge is no longer needed.
  void dispose() {
    _instance?.dispose();
    _instance = null;
    _memory = null;
  }
}
