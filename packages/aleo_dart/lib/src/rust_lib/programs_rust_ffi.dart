import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

final ffi.DynamicLibrary dyLib = ffi.DynamicLibrary.open(
    './aleo_rust/aleo-rust/target/debug/libaleo_rust.so');


typedef TypeTestInRust = ffi.Int Function(ffi.Int, ffi.Int);
typedef TypeTestInDart = int Function(int, int);

typedef TypeTransferInRust = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Int, ffi.Int, ffi.Pointer<Utf8>);

typedef TypeTransferInDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, int, int, ffi.Pointer<Utf8>);

class ProgramsRustFFI {

  static int testRustFFi(int a, int b) {
    var numbers_add =
        dyLib.lookupFunction<TypeTestInRust, TypeTestInDart>('numbers_add');
    final result = numbers_add(a, b);
    return result;
  }

  static ffi.Pointer<Utf8> transfer(
      ffi.Pointer<Utf8> private_key,
      ffi.Pointer<Utf8> recipient,
      ffi.Pointer<Utf8> transfer_type,
      int amount_credits,
      int fee_credits,
      ffi.Pointer<Utf8> url) {
    final tryTransfer = dyLib
        .lookupFunction<TypeTransferInRust, TypeTransferInDart>('try_transfer');

    return tryTransfer(private_key, recipient, transfer_type, amount_credits,
        fee_credits, url);
  }
}
