import 'package:aleo_dart/src/rust_lib/rust_ffi.dart';

int testRustFFi(int a,int b) {
  return RustFFI.testRustFFi(a, b);
}
