import 'dart:ffi' as ffi;

import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_bridge.dart';
import 'package:ffi/ffi.dart';

/// FFI bridge over the native SC signing library.
///
/// The native library is **not** bundled with this package. The caller builds
/// it for their platform (see `lib/src/forked_lib/sia-wasi/build.sh`), loads it
/// however they like (e.g. `DynamicLibrary.open(path)`), and passes the result
/// in.
class ScGoFfiBridge extends ScWasmBridgeBase {
  final ffi.DynamicLibrary _lib;

  late final _processScTransaction = _lib
      .lookupFunction<
        ffi.Int32 Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Pointer<Utf8>>),
        int Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Pointer<Utf8>>)
      >('process_sc_transaction');

  late final _freeString = _lib
      .lookupFunction<
        ffi.Void Function(ffi.Pointer<Utf8>),
        void Function(ffi.Pointer<Utf8>)
      >('free_string');

  /// Wraps an already-loaded native SC library.
  ScGoFfiBridge(this._lib);

  @override
  Future<String> processJson(String jsonString) async {
    final inputPtr = jsonString.toNativeUtf8();
    final outputPtrPtr = malloc<ffi.Pointer<Utf8>>();

    try {
      final result = _processScTransaction(inputPtr, outputPtrPtr);
      final outputPtr = outputPtrPtr.value;

      if (result != 0) {
        // On failure Go still allocates an error-JSON string; read it for the
        // message and free it so it doesn't leak.
        var detail = '';
        if (outputPtr != ffi.nullptr) {
          detail = ': ${outputPtr.toDartString()}';
          _freeString(outputPtr);
        }
        throw StateError('Go library call failed with code $result$detail');
      }

      if (outputPtr == ffi.nullptr) {
        throw StateError('Go library returned null output');
      }

      final output = outputPtr.toDartString();
      _freeString(outputPtr);

      return output;
    } finally {
      malloc.free(inputPtr);
      malloc.free(outputPtrPtr);
    }
  }
}
