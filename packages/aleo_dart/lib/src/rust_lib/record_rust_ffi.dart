import 'dart:ffi' as ffi;
// import 'package:ffi/ffi.dart';

final ffi.DynamicLibrary dyLib =
    ffi.DynamicLibrary.open('./aleo_rust/target/debug/libaleo_wasm.so');

class RecordRustFFI {}
