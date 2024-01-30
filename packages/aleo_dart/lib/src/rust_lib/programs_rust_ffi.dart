import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

final ffi.DynamicLibrary dyLib =
    ffi.DynamicLibrary.open('./aleo_rust/wasm/target/debug/libaleo_wasm.so');

typedef TypeBuildTransferTransactionInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Float,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Float,
    ffi.Pointer<Utf8>);

typedef TypeBuildTransferTransactionInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    double,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    double,
    ffi.Pointer<Utf8>);

typedef TypeTestInRust = ffi.Int Function(ffi.Int, ffi.Int);
typedef TypeTestInDart = int Function(int, int);

class ProgramsRustFFI {
  static ffi.Pointer<Utf8> buildTransferTransaction(
      ffi.Pointer<Utf8> private_key,
      double amount_credits,
      ffi.Pointer<Utf8> transfer_type,
      ffi.Pointer<Utf8> recipient,
      double fee_credits,
      ffi.Pointer<Utf8> url) {
    final buildTransferTransaction = dyLib.lookupFunction<
        TypeBuildTransferTransactionInRust,
        TypeBuildTransferTransactionInDart>('transfer_part');
    print(testRustFFi(1, 5));
    return buildTransferTransaction(private_key, amount_credits, transfer_type,
        recipient, fee_credits, url);
  }

  static int testRustFFi(int a, int b) {
    var numbers_add =
        dyLib.lookupFunction<TypeTestInRust, TypeTestInDart>('numbers_add');
    final result = numbers_add(a, b);
    return result;
  }
}
