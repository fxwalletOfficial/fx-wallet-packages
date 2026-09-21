import 'dart:convert';
import 'dart:ffi' show DynamicLibrary;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/transaction/sc/sc_lib.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_go_ffi_bridge.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_asset_loader.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_isolate_bridge.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_run_bridge.dart';
import 'package:crypto_wallet_util/src/transaction/sc/sc_v2_semantics.dart';
import 'package:crypto_wallet_util/src/transaction/sc/tx_data.dart';
import 'package:convert/convert.dart';

/// Loads the bundled SC WASM bytes.
///
/// Flutter callers can provide a custom loader backed by `rootBundle` when
/// they need to override the package asset.
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

/// Optional semantic-signing capability implemented by the bundled SC
/// bridges. It is separate from [ScWasmBridge] so existing custom bridges that
/// only implement full transaction construction remain source-compatible.
abstract class ScV2SemanticBridge {
  Future<ScV2TransactionSemantics> extractV2TransactionSemantics(
    Map<String, dynamic> unsignedTransaction, {
    Iterable<String> changeAddresses = const [],
  });

  Future<ScV2TransactionSemantics> inspectV2TransactionSemantics(
    Uint8List semanticBytes, {
    Iterable<String> changeAddresses = const [],
  });
}

/// Base [ScWasmBridge] that serializes the unsigned transaction to JSON and
/// delegates the actual digest computation to [processJson].
abstract class ScWasmBridgeBase implements ScWasmBridge, ScV2SemanticBridge {
  @override
  Future<ScWasmResult> processUnsignedTransaction(
    ScUnsignedTransaction unsignedTx,
  ) async {
    final jsonString = json.encode(unsignedTx.toJson());
    final resultJson = await processJson(jsonString);
    return ScWasmResult.fromJson(_decodeResult(resultJson));
  }

  @override
  Future<ScV2TransactionSemantics> extractV2TransactionSemantics(
    Map<String, dynamic> unsignedTransaction, {
    Iterable<String> changeAddresses = const [],
  }) async {
    final resultJson = await extractV2TransactionSemanticsJson(
      json.encode({
        'transaction': unsignedTransaction,
        'changeAddresses': changeAddresses.toList(),
      }),
    );
    return ScV2TransactionSemantics.fromJson(_decodeResult(resultJson));
  }

  @override
  Future<ScV2TransactionSemantics> inspectV2TransactionSemantics(
    Uint8List semanticBytes, {
    Iterable<String> changeAddresses = const [],
  }) async {
    final resultJson = await inspectV2TransactionSemanticsJson(
      json.encode({
        'semantics': hex.encode(semanticBytes),
        'changeAddresses': changeAddresses.toList(),
      }),
    );
    return ScV2TransactionSemantics.fromJson(_decodeResult(resultJson));
  }

  Map<String, dynamic> _decodeResult(String resultJson) {
    final result = json.decode(resultJson);
    if (result is! Map) {
      throw const FormatException('SC bridge returned a non-object response');
    }
    final mapped = Map<String, dynamic>.from(result);
    final error = mapped['error'];
    if (error != null) {
      throw StateError('SC bridge rejected the request: $error');
    }
    return mapped;
  }

  /// Implementation-specific: take the unsigned transaction JSON, compute the
  /// signing digests, and return the result transaction JSON string.
  Future<String> processJson(String jsonString);

  Future<String> extractV2TransactionSemanticsJson(String jsonString) {
    throw UnsupportedError('SC V2 semantic extraction is not implemented');
  }

  Future<String> inspectV2TransactionSemanticsJson(String jsonString) {
    throw UnsupportedError('SC V2 semantic inspection is not implemented');
  }
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
  /// Flutter runtimes load the declared package asset automatically. A custom
  /// [wasmLoader] can be supplied when an application overrides that asset.
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
    return loadScWasm();
  }

  Future<ScTxData> build(ScUnsignedTransaction unsignedTx) async {
    final result = await wasmBridge.processUnsignedTransaction(unsignedTx);
    return ScTxData(transaction: result.transaction, toSign: result.toSign);
  }

  /// Extracts canonical signing semantics from the complete unsigned V2
  /// transaction map and computes its InputSigHash through Sia core.
  Future<ScV2TransactionSemantics> extractV2TransactionSemantics(
    Map<String, dynamic> unsignedTransaction, {
    Iterable<String> changeAddresses = const [],
  }) {
    final bridge = wasmBridge;
    if (bridge is! ScV2SemanticBridge) {
      throw UnsupportedError(
        'This custom SC bridge does not support V2 transaction semantics',
      );
    }
    return (bridge as ScV2SemanticBridge).extractV2TransactionSemantics(
      unsignedTransaction,
      changeAddresses: changeAddresses,
    );
  }

  /// Strictly parses canonical semantic bytes and recomputes InputSigHash
  /// through the same Sia core implementation used by the hot side.
  Future<ScV2TransactionSemantics> inspectV2TransactionSemantics(
    Uint8List semanticBytes, {
    Iterable<String> changeAddresses = const [],
  }) {
    final bridge = wasmBridge;
    if (bridge is! ScV2SemanticBridge) {
      throw UnsupportedError(
        'This custom SC bridge does not support V2 transaction semantics',
      );
    }
    return (bridge as ScV2SemanticBridge).inspectV2TransactionSemantics(
      semanticBytes,
      changeAddresses: changeAddresses,
    );
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
    }
  }
}

/// Loads SC WASM through the runtime asset, package URI and file fallbacks.
///
/// The optional callbacks are intentionally kept on this internal helper so
/// each fallback can be tested without changing the public Builder API.
Future<Uint8List> loadScWasm({
  Future<Uint8List?> Function()? assetLoader,
  Future<Uri?> Function(Uri uri)? packageUriResolver,
  bool Function(String path)? fileExists,
  Future<Uint8List> Function(String path)? fileReader,
}) async {
  final errors = <Object>[];
  final loadAsset = assetLoader ?? loadBundledScWasm;
  try {
    final assetBytes = await loadAsset();
    if (assetBytes != null) return assetBytes;
  } catch (error) {
    errors.add(error);
  }

  Uri? pkgUri;
  try {
    pkgUri = await (packageUriResolver ?? Isolate.resolvePackageUri)(
      Uri.parse('package:crypto_wallet_util/src/transaction/sc/sc.wasm'),
    );
  } catch (error) {
    errors.add(error);
  }

  final read = fileReader ?? (path) => File(path).readAsBytes();
  if (pkgUri != null && pkgUri.scheme == 'file') {
    try {
      return await read(pkgUri.toFilePath());
    } catch (error) {
      errors.add(error);
    }
  }

  final exists = fileExists ?? (path) => File(path).existsSync();
  for (final path in [
    'lib/src/transaction/sc/sc.wasm',
    'packages/crypto_wallet_util/lib/src/transaction/sc/sc.wasm',
  ]) {
    if (exists(path)) return read(path);
  }

  final detail = errors.isEmpty ? '' : ' Loader errors: ${errors.join(' | ')}';
  throw StateError('Cannot locate sc.wasm in the package bundle.$detail');
}
