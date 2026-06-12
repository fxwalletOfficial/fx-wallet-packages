import 'dart:ffi' as ffi;
import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:isolate';

import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_bridge.dart';
import 'package:ffi/ffi.dart';

/// FFI bridge using Go dynamic library for SC transaction processing.
class ScGoFfiBridge extends ScWasmBridgeBase {
  final ffi.DynamicLibrary _lib;

  late final _processScTransaction = _lib.lookupFunction<
    ffi.Int32 Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Pointer<Utf8>>),
    int Function(ffi.Pointer<Utf8>, ffi.Pointer<ffi.Pointer<Utf8>>)
  >('process_sc_transaction');

  late final _freeString = _lib.lookupFunction<
    ffi.Void Function(ffi.Pointer<Utf8>),
    void Function(ffi.Pointer<Utf8>)
  >('free_string');

  ScGoFfiBridge(this._lib);

  /// Auto-loads the Go dynamic library for the current platform.
  static Future<ScGoFfiBridge> create() async {
    final libPath = await _resolveLibraryPath();
    final lib = ffi.DynamicLibrary.open(libPath);
    return ScGoFfiBridge(lib);
  }

  /// Native library file name for the current platform/architecture.
  static String _libraryName() {
    if (Platform.isMacOS) {
      final arch = Abi.current() == Abi.macosArm64 ? 'arm64' : 'amd64';
      return 'libsc_transaction_darwin_$arch.dylib';
    } else if (Platform.isLinux) {
      final arch = Abi.current() == Abi.linuxArm64 ? 'arm64' : 'amd64';
      return 'libsc_transaction_linux_$arch.so';
    } else if (Platform.isWindows) {
      return 'sc_transaction_windows_amd64.dll';
    } else if (Platform.isAndroid) {
      if (Abi.current() == Abi.androidArm64) {
        return 'libsc_transaction_android_arm64.so';
      } else if (Abi.current() == Abi.androidArm) {
        return 'libsc_transaction_android_arm.so';
      }
      return 'libsc_transaction_android_x86_64.so';
    } else if (Platform.isIOS) {
      return 'libsc_transaction_ios_arm64.dylib';
    }
    throw UnsupportedError(
      'Platform ${Platform.operatingSystem} not supported',
    );
  }

  /// Resolves the native library, preferring the copy bundled in the package
  /// (located next to this file under `native/`, the same way `sc.wasm` is
  /// resolved). Falls back to relative paths for non-resolvable contexts.
  static Future<String> _resolveLibraryPath() async {
    final libName = _libraryName();

    final pkgUri = await Isolate.resolvePackageUri(
      Uri.parse(
        'package:crypto_wallet_util/src/transaction/sc/native/$libName',
      ),
    );
    if (pkgUri != null && pkgUri.scheme == 'file') {
      final file = File.fromUri(pkgUri);
      if (file.existsSync()) return file.path;
    }

    for (final path in [
      'lib/src/transaction/sc/native/$libName',
      'packages/crypto_wallet_util/lib/src/transaction/sc/native/$libName',
    ]) {
      if (File(path).existsSync()) return path;
    }

    throw StateError(
      'Could not find SC native library "$libName". Build it with '
      'lib/src/forked_lib/sia-wasi/build.sh',
    );
  }

  @override
  Future<String> processJson(String jsonString) async {
    final inputPtr = jsonString.toNativeUtf8();
    final outputPtrPtr = malloc<ffi.Pointer<Utf8>>();

    try {
      final result = _processScTransaction(inputPtr, outputPtrPtr);

      if (result != 0) {
        throw StateError('Go library call failed with code $result');
      }

      final outputPtr = outputPtrPtr.value;
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
