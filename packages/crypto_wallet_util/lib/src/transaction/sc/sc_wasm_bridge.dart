import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/transaction/sc/sc_lib.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_run_bridge.dart';
import 'package:crypto_wallet_util/src/transaction/sc/tx_data.dart';

/// Bridge for calling the SC WASM module (`sc.wasm`).
///
/// The built-in [ScWasmRunBridge] uses `package:wasm_run` (wasmtime / wasmi).
/// Web platforms can implement this with `package:wasm_interop`.
abstract class ScWasmBridge {
  Future<ScWasmResult> processUnsignedTransaction(
    ScUnsignedTransaction unsignedTx,
  );
}

/// Base [ScWasmBridge] that serializes the unsigned transaction to JSON and
/// delegates the actual WASM call to [processJson].
abstract class ScWasmBridgeBase implements ScWasmBridge {
  @override
  Future<ScWasmResult> processUnsignedTransaction(
      ScUnsignedTransaction unsignedTx) async {
    final jsonString = json.encode(unsignedTx.toJson());
    final resultJson = await processJson(jsonString);
    return ScWasmResult.fromJson(
        json.decode(resultJson) as Map<String, dynamic>);
  }

  /// Platform-specific: pass the unsigned transaction JSON, call the WASM
  /// module, and return the result JSON string.
  ///
  /// WASM exports used: `alloc`, `getUnsignedV2Transaction`, `resultPtr`,
  /// `resultLen`, `release`.
  Future<String> processJson(String jsonString);
}

/// Assembles an SC transaction through the WASM pipeline.
///
/// The default factory [ScTransactionBuilder.create] auto-loads `sc.wasm`
/// from the package bundle and uses [ScWasmRunBridge] under the hood.
///
/// ```dart
/// final txData = await ScTransactionBuilder.create().build(unsignedTx);
/// ```
class ScTransactionBuilder {
  final ScWasmBridge wasmBridge;

  ScTransactionBuilder({required this.wasmBridge});

  /// Creates a builder with `sc.wasm` auto-loaded from the package bundle.
  static Future<ScTransactionBuilder> create() async {
    final wasmBytes = await _loadPackageWasm();
    return ScTransactionBuilder(wasmBridge: ScWasmRunBridge(wasmBytes));
  }

  static Future<Uint8List> _loadPackageWasm() async {
    final pkgUri = await Isolate.resolvePackageUri(
      Uri.parse('package:crypto_wallet_util/src/transaction/sc/sc.wasm'),
    );
    if (pkgUri != null && pkgUri.scheme == 'file') {
      return File.fromUri(pkgUri).readAsBytes();
    }

    // Fallback: walk relative paths.
    for (final path in [
      'lib/src/transaction/sc/sc.wasm',
      'packages/crypto_wallet_util/lib/src/transaction/sc/sc.wasm',
    ]) {
      final file = File(path);
      if (file.existsSync()) return file.readAsBytesSync();
    }

    throw StateError('Cannot locate sc.wasm in the package bundle.');
  }

  Future<ScTxData> build(ScUnsignedTransaction unsignedTx) async {
    final result = await wasmBridge.processUnsignedTransaction(unsignedTx);
    return ScTxData(
      transaction: result.transaction,
      toSign: result.toSign,
    );
  }
}
