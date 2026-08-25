import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_bridge.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_run_bridge.dart';

/// Runs the SC WASM bridge on a dedicated isolate.
///
/// `wasd` parses and instantiates the module synchronously. Keeping that work
/// in a long-lived isolate prevents the first SC transaction from blocking the
/// Flutter UI isolate. The worker is started lazily and the same WASM instance
/// is reused for subsequent transactions.
class ScWasmIsolateBridge extends ScWasmBridgeBase {
  Uint8List? _wasmBytes;
  final Map<int, Completer<String>> _pending = <int, Completer<String>>{};

  Isolate? _isolate;
  ReceivePort? _messagePort;
  ReceivePort? _errorPort;
  ReceivePort? _exitPort;
  SendPort? _workerPort;
  Completer<SendPort>? _workerReady;
  Future<void>? _starting;
  int _nextRequestId = 0;
  bool _disposed = false;

  /// Creates a lazy bridge. The WASM module is not parsed until the first
  /// transaction is submitted, and that parsing happens in the worker.
  ScWasmIsolateBridge(Uint8List wasmBytes) : _wasmBytes = wasmBytes;

  @override
  Future<String> processJson(String jsonString) async {
    _checkNotDisposed();
    await _ensureStarted();
    _checkNotDisposed();

    final workerPort = _workerPort;
    if (workerPort == null) {
      throw StateError('SC WASM worker is not available');
    }

    final requestId = _nextRequestId++;
    final completer = Completer<String>();
    _pending[requestId] = completer;
    workerPort.send(<Object>[requestId, jsonString]);
    return completer.future;
  }

  /// Stops the worker and completes any in-flight requests with an error.
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    final error = StateError('SC WASM worker was disposed');
    final workerReady = _workerReady;
    if (workerReady != null && !workerReady.isCompleted) {
      workerReady.completeError(error);
    }
    _workerReady = null;
    _failPending(error);
    _isolate?.kill(priority: Isolate.immediate);
    _closePorts();
    _isolate = null;
    _workerPort = null;
  }

  Future<void> _ensureStarted() {
    if (_workerPort != null) return Future<void>.value();
    return _starting ??= _startWorker();
  }

  Future<void> _startWorker() async {
    final wasmBytes = _wasmBytes;
    if (wasmBytes == null) {
      throw StateError(
        'SC WASM worker cannot be restarted after its bytes were transferred',
      );
    }

    final messagePort = ReceivePort();
    final errorPort = ReceivePort();
    final exitPort = ReceivePort();
    final workerReady = Completer<SendPort>();

    _workerReady = workerReady;
    _messagePort = messagePort;
    _errorPort = errorPort;
    _exitPort = exitPort;

    messagePort.listen((dynamic message) {
      if (message is SendPort && !workerReady.isCompleted) {
        workerReady.complete(message);
        return;
      }
      _handleWorkerMessage(message);
    });
    errorPort.listen((dynamic message) {
      final error = _workerError(message);
      if (!workerReady.isCompleted) {
        workerReady.completeError(error);
      } else {
        _failPending(error);
      }
    });
    exitPort.listen((dynamic _) {
      final error = StateError('SC WASM worker exited unexpectedly');
      if (!workerReady.isCompleted) {
        workerReady.completeError(error);
      } else {
        _failPending(error);
      }
      _workerPort = null;
      _isolate = null;
    });

    try {
      _isolate = await Isolate.spawn<List<Object>>(
        _scWasmWorkerMain,
        <Object>[
          messagePort.sendPort,
          TransferableTypedData.fromList(<Uint8List>[wasmBytes]),
        ],
        errorsAreFatal: false,
        onError: errorPort.sendPort,
        onExit: exitPort.sendPort,
      );
      _workerPort = await workerReady.future;
      // The transferable has already been materialized before the worker
      // announces readiness. Do not retain another 4 MB copy in the caller.
      _wasmBytes = null;
      _checkNotDisposed();
    } catch (_) {
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _workerPort = null;
      rethrow;
    } finally {
      if (identical(_workerReady, workerReady)) _workerReady = null;
      _starting = null;
      if (_disposed || _workerPort == null) {
        _closePorts();
      }
    }
  }

  void _handleWorkerMessage(dynamic message) {
    if (message is! List || message.length < 3) return;

    final requestId = message[0];
    if (requestId is! int) return;
    final completer = _pending.remove(requestId);
    if (completer == null || completer.isCompleted) return;

    if (message[1] == true) {
      completer.complete(message[2] as String);
    } else {
      final detail = message[2]?.toString() ?? 'Unknown SC WASM error';
      final stack = message.length > 3 ? message[3]?.toString() : null;
      completer.completeError(
        StateError(stack == null || stack.isEmpty ? detail : '$detail\n$stack'),
      );
    }
  }

  StateError _workerError(dynamic message) {
    if (message is List && message.isNotEmpty) {
      final detail = message.first.toString();
      final stack = message.length > 1 ? message[1].toString() : '';
      return StateError(stack.isEmpty ? detail : '$detail\n$stack');
    }
    return StateError('SC WASM worker failed: $message');
  }

  void _failPending(Object error) {
    final pending = List<Completer<String>>.from(_pending.values);
    _pending.clear();
    for (final completer in pending) {
      if (!completer.isCompleted) completer.completeError(error);
    }
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('SC WASM bridge was disposed');
  }

  void _closePorts() {
    _messagePort?.close();
    _errorPort?.close();
    _exitPort?.close();
    _messagePort = null;
    _errorPort = null;
    _exitPort = null;
  }
}

/// Isolate entry point. All `wasd` objects stay inside this isolate.
void _scWasmWorkerMain(List<Object> args) {
  final parentPort = args[0] as SendPort;
  final wasmTransfer = args[1] as TransferableTypedData;
  final commandPort = ReceivePort();
  final wasmBytes = wasmTransfer.materialize().asUint8List();
  ScWasmRunBridge? bridge;
  Future<void> queue = Future<void>.value();

  parentPort.send(commandPort.sendPort);
  commandPort.listen((dynamic message) {
    queue = queue.then((_) async {
      if (message is! List || message.length < 2) return;
      final requestId = message[0];
      final jsonString = message[1];
      if (requestId is! int || jsonString is! String) return;

      try {
        bridge ??= ScWasmRunBridge(wasmBytes);
        final result = await bridge!.processJson(jsonString);
        parentPort.send(<Object>[requestId, true, result]);
      } catch (error, stackTrace) {
        parentPort.send(<Object>[
          requestId,
          false,
          error.toString(),
          stackTrace.toString(),
        ]);
      }
    });
  });
}
