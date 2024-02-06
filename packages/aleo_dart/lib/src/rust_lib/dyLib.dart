import 'dart:ffi' as ffi;
import 'dart:io';

const DEFAULT_RUST_LIB_CARGO_SO = './aleo_rust/target/release/libaleo_rust.so';
const DEFAULT_RUST_LIB_CARGO_DLL =
    'aleo_rust/target/i686-pc-windows-gnu/release/aleo_rust.dll';
const DEFAULT_RUST_LIB_CARGO_LIB = './aleo_rust/target/release/libaleo_rust.so';

const DEFAULT_RUST_LIB_GIT_SO = '.dart_tool/dart_aleo/libaleo_rust.so';
const DEFAULT_RUST_LIB_GIT_DLL = '.dart_tool/dart_aleo/libaleo_rust.so';
const DEFAULT_RUST_LIB_GIT_LIB = '.dart_tool/dart_aleo/libaleo_rust.so';

class DyLib {
  static ffi.DynamicLibrary getDyLibByPosition(String position) {
    return ffi.DynamicLibrary.open(position);
  }

  static ffi.DynamicLibrary getDyLibFromCargo() {
    if (Platform.isLinux) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_CARGO_SO);
    } else if (Platform.isIOS) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_CARGO_LIB);
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_CARGO_DLL);
    } else {
      throw Exception("error platform");
    }
  }

  static ffi.DynamicLibrary getDyLibFromGit() {
    if (Platform.isLinux) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_GIT_SO);
    } else if (Platform.isIOS) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_GIT_LIB);
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_GIT_DLL);
    } else {
      throw Exception("error platform");
    }
  }
}
