import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

typedef TypeTestInRust = ffi.Int Function(ffi.Int, ffi.Int);

typedef TypeTestInDart = int Function(int, int);

typedef TypeU8listToString = ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Uint8>);

typedef TypeStringToString = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>);

final ffi.DynamicLibrary dyLib =
    ffi.DynamicLibrary.open('./aleo_rust/target/debug/libaleo_wasm.so');

class RustFFI {
  static int testRustFFi(int a, int b) {
    var numbers_add =
        dyLib.lookupFunction<TypeTestInRust, TypeTestInDart>('numbers_add');
    final result = numbers_add(a, b);
    return result;
  }

  static ffi.Pointer<Utf8> seedToPrivateKey(ffi.Pointer<ffi.Uint8> seed) {
    final seedToPrivateKey =
        dyLib.lookupFunction<TypeU8listToString, TypeU8listToString>(
            'seedToPrivateKey');
    return seedToPrivateKey(seed);
  }

  static ffi.Pointer<Utf8> privateKeyToAddress(ffi.Pointer<Utf8> privateKey) {
    final privateKeyToAddress =
        dyLib.lookupFunction<TypeStringToString, TypeStringToString>(
            'privateKeyToAddress');
    return privateKeyToAddress(privateKey);
  }
}
