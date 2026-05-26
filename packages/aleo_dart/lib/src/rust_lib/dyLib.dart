import 'dart:ffi' as ffi;
import 'dart:io';

const DEFAULT_RUST_LIB_CARGO_SO =
    './aleo_rust/target/release/libaleo_rust.so'; // linux
const DEFAULT_RUST_LIB_CARGO_DLL =
    'aleo_rust/target/release/aleo_rust.dll'; // windows
const DEFAULT_RUST_LIB_CARGO_LIB =
    './aleo_rust/target/release/libaleo_rust.dylib'; // ios

const DEFAULT_RUST_LIB_GIT_SO = '.dart_tool/dart_aleo/libaleo_rust.so';
const DEFAULT_RUST_LIB_GIT_DLL = '.dart_tool/dart_aleo/aleo_rust.dll';
const DEFAULT_RUST_LIB_GIT_LIB = '.dart_tool/dart_aleo/libaleo_rust.dylib';

class DyLib {
  static ffi.DynamicLibrary getDyLibByPosition(String position) {
    return ffi.DynamicLibrary.open(position);
  }

  static ffi.DynamicLibrary getLocalDyLib() {
    return ffi.DynamicLibrary.open('./aleo_rust.dll');
  }

  static ffi.DynamicLibrary getDyLibFromCargo() {
    if (Platform.isLinux) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_CARGO_SO);
    } else if (Platform.isMacOS) {
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
    } else if (Platform.isMacOS) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_GIT_LIB);
    } else if (Platform.isWindows) {
      return ffi.DynamicLibrary.open(DEFAULT_RUST_LIB_GIT_DLL);
    } else {
      throw Exception("error platform");
    }
  }
}
