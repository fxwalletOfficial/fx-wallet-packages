import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/transaction/sc/sc_lib.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_go_ffi_bridge.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_isolate_bridge.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_run_bridge.dart';
import 'package:crypto_wallet_util/src/transaction/sc/tx_data.dart';

/// Loads the bundled SC WASM bytes.
///
/// Flutter callers can provide a loader backed by `rootBundle`, for example
/// `packages/crypto_wallet_util/src/transaction/sc/sc.wasm`, so runtime asset
/// loading does not depend on package URI resolution.
typedef ScWasmLoader = Future<Uint8List> Function();

/// Bridge for computing SC transaction signing digests.
///
/// The package provides three implementations:
/// - [ScWasmIsolateBridge] (default through [ScTransactionBuilder.create]):
///   runs the bundled `sc.wasm` in short-lived background isolates.
/// - [ScWasmRunBridge]: interprets the bundled `sc.wasm` with `package:wasd`
///   in the current isolate. It is used by the worker and remains available
///   for callers that explicitly need a direct bridge.
/// - [ScGoFfiBridge]: calls a native library through `dart:ffi`, much faster,
///   but the caller must supply a library built for their platform.
abstract class ScWasmBridge {
  Future<ScWasmResult> processUnsignedTransaction(
    ScUnsignedTransaction unsignedTx,
  );
}

/// Base [ScWasmBridge] that serializes the unsigned transaction to JSON and
/// delegates the actual digest computation to [processJson].
abstract class ScWasmBridgeBase implements ScWasmBridge {
  @override
  Future<ScWasmResult> processUnsignedTransaction(
    ScUnsignedTransaction unsignedTx,
  ) async {
    final jsonString = json.encode(unsignedTx.toJson());
    final resultJson = await processJson(jsonString);
    return ScWasmResult.fromJson(
      json.decode(resultJson) as Map<String, dynamic>,
    );
  }

  /// Implementation-specific: take the unsigned transaction JSON, compute the
  /// signing digests, and return the result transaction JSON string.
  Future<String> processJson(String jsonString);
}

/// Assembles an SC transaction through the signing-digest pipeline.
///
/// Two factories are available:
/// - [ScTransactionBuilder.create]: background-isolate WASM bridge
///   ([ScWasmIsolateBridge]), the default; loads the bundled `sc.wasm`, no
///   native library needed.
/// - [ScTransactionBuilder.createWithFfi]: native Go FFI bridge
///   ([ScGoFfiBridge]); much faster, but the caller passes the path to a
///   native library they built for their platform.
///
/// ```dart
/// final builder = await ScTransactionBuilder.create();
/// final txData = await builder.build(unsignedTx);
/// ```
class ScTransactionBuilder {
  final ScWasmBridge wasmBridge;
  final bool _ownsBridge;

  ScTransactionBuilder({required this.wasmBridge}) : _ownsBridge = false;

  ScTransactionBuilder._owned({required this.wasmBridge}) : _ownsBridge = true;

  /// Creates a builder backed by [ScWasmIsolateBridge], loading `sc.wasm` from
  /// the package bundle. WASM parsing and transaction processing run outside
  /// the caller's isolate. No native library is required.
  ///
  /// Flutter callers should pass a [wasmLoader] backed by `rootBundle` when
  /// package URI resolution is unavailable in their runtime.
  ///
  /// This is the default and matches the long-standing behaviour; existing
  /// callers keep running unchanged.
  static Future<ScTransactionBuilder> create({ScWasmLoader? wasmLoader}) async {
    final wasmBytes = await (wasmLoader ?? _loadPackageWasm)();
    return ScTransactionBuilder._owned(
      wasmBridge: ScWasmIsolateBridge(wasmBytes),
    );
  }

  /// Creates a builder backed by the native Go FFI bridge ([ScGoFfiBridge]),
  /// which is much faster. The caller supplies an already-loaded [library]
  /// (e.g. `DynamicLibrary.open(path)`) built for the current platform — see
  /// `lib/src/forked_lib/sia-wasi/build.sh`; this package does not bundle one.
  static ScTransactionBuilder createWithFfi(DynamicLibrary library) {
    return ScTransactionBuilder(wasmBridge: ScGoFfiBridge(library));
  }

  static Future<Uint8List> _loadPackageWasm() async {
    Uri? pkgUri;
    try {
      pkgUri = await Isolate.resolvePackageUri(
        Uri.parse('package:crypto_wallet_util/src/transaction/sc/sc.wasm'),
      );
    } catch (_) {
      // Flutter test/release runtimes may not implement package URI
      // resolution. Continue to the file fallback or a caller-provided
      // rootBundle loader instead of failing before the fallback is reached.
    }
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
    return ScTxData(transaction: result.transaction, toSign: result.toSign);
  }

  /// Releases resources owned by a bridge created by this builder.
  ///
  /// A builder constructed with the public constructor does not own its
  /// bridge, so disposing it cannot destroy a bridge shared by another
  /// builder.
  void dispose() {
    if (!_ownsBridge) return;
    if (wasmBridge case final ScWasmIsolateBridge bridge) {
      bridge.dispose();
    } else if (wasmBridge case final ScWasmRunBridge bridge) {
      bridge.dispose();
    }
  }
}
