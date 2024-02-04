import 'dart:ffi' as ffi;

const DEFAULT_RUST_LIB_CARGO = './aleo_rust/target/debug/libaleo_rust.so';
const DEFAULT_RUST_LIB_GIT = '.dart_tool/dart_aleo/libaleo_rust.so';

class DyLib {
  static ffi.DynamicLibrary getDyLibByPosition(String position) {
    return ffi.DynamicLibrary.open(position);
  }

  static ffi.DynamicLibrary getDyLibFromCargo() {
    return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_CARGO);
  }

  static ffi.DynamicLibrary getDyLibFromGit() {
    return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_GIT);
  }
}
