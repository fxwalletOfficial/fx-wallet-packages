import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_bridge.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_run_bridge.dart';

/// Runs SC WASM work outside the caller's isolate.
///
/// Each request is serialized and runs in a short-lived isolate. The isolate
/// exits after the request completes, so callers do not need to know about a
/// worker port or call [dispose] merely to let a Dart process exit. This keeps
/// WASM parsing and instantiation off the Flutter UI isolate while preserving
/// the old no-cleanup lifecycle.
class ScWasmIsolateBridge extends ScWasmBridgeBase {
  Uint8List? _wasmBytes;
  Future<void> _queue = Future<void>.value();
  bool _disposed = false;

  ScWasmIsolateBridge(Uint8List wasmBytes) : _wasmBytes = wasmBytes;

  @override
  Future<String> processJson(String jsonString) {
    _checkNotDisposed();
    final wasmBytes = _wasmBytes;
    if (wasmBytes == null) {
      throw StateError('SC WASM bridge was disposed');
    }

    final wasmTransfer = TransferableTypedData.fromList(<Uint8List>[wasmBytes]);
    final task = _queue.then<String>((_) {
      return Isolate.run<String>(() => _runScWasm(wasmTransfer, jsonString));
    });

    // Keep the queue usable after a failed request while preserving the
    // original error for the caller awaiting [task].
    _queue = task.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return task;
  }

  /// Releases the caller-side WASM bytes.
  ///
  /// This is optional for process termination because request isolates are
  /// short-lived. Requests already submitted may finish; later requests fail.
  /// A builder created by [ScTransactionBuilder.create] owns its bridge and
  /// may call this during app teardown.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _wasmBytes = null;
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('SC WASM bridge was disposed');
  }
}

Future<String> _runScWasm(
  TransferableTypedData wasmTransfer,
  String jsonString,
) async {
  final bridge = ScWasmRunBridge(wasmTransfer.materialize().asUint8List());
  return bridge.processJson(jsonString);
}
