import 'dart:ffi' as ffi;

const DEFAULT_RUST_LIB = './aleo_rust/target/debug/libaleo_rust.so';

class DyLib {
  static ffi.DynamicLibrary getDyLibByPosition(String position) {
    return ffi.DynamicLibrary.open(position);
  }

  static ffi.DynamicLibrary getDyLib() {
    return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB);
  }
}
