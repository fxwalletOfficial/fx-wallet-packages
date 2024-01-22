import 'dart:ffi' as ffi;
// import 'package:ffi/ffi.dart';

typedef TypeTestInRust = ffi.Int Function(ffi.Int, ffi.Int);

typedef TypeTestInDart = int Function(int, int);

final ffi.DynamicLibrary dyLib =
    ffi.DynamicLibrary.open('./aleo_rust/target/debug/libaleo_wasm.so');

class RustFFI {
  static int testRustFFi(int a, int b) {
    var test = dyLib.lookupFunction<TypeTestInRust, TypeTestInDart>('test');
    final result = test(a, b);
    return result;
  }
}
