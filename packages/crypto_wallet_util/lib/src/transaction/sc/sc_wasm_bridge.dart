import 'dart:convert';

import 'package:crypto_wallet_util/src/transaction/sc/sc_lib.dart';
import 'package:crypto_wallet_util/src/transaction/sc/tx_data.dart';

/// Bridge for calling the SC WASM module (`sc.wasm`).
///
/// Platform implementations:
/// - **Native**: [ScWasmRunBridge] backed by `package:wasm_run` (wasmtime)
/// - **Web**: implement with `package:wasm_interop`
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

/// Assembles an SC transaction from raw UTXO data through the WASM pipeline.
///
/// Flow:
///   1. Build a [ScUnsignedTransaction] from utxo / recipient data
///   2. Call [build] to run it through the WASM bridge, producing [ScTxData]
///   3. Sign with [ScTxSigner]
///   4. Broadcast via [ScTxData.toBroadcast]
class ScTransactionBuilder {
  final ScWasmBridge wasmBridge;

  ScTransactionBuilder({required this.wasmBridge});

  Future<ScTxData> build(ScUnsignedTransaction unsignedTx) async {
    final result = await wasmBridge.processUnsignedTransaction(unsignedTx);
    return ScTxData(
      transaction: result.transaction,
      toSign: result.toSign,
    );
  }
}
