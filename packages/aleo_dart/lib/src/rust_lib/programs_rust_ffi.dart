import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

typedef TypeTestInRust = ffi.Int Function(ffi.Int, ffi.Int);
typedef TypeTestInDart = int Function(int, int);

typedef TypeTransferInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Int,
    ffi.Int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeTransferInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    int,
    int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

class ProgramsRustFFI {
  late ffi.DynamicLibrary dyLib;

  ProgramsRustFFI(dyLib) {
    this.dyLib = dyLib;
  }

  ffi.Pointer<Utf8> transfer(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> recipient,
    ffi.Pointer<Utf8> transfer_type,
    int amount_credits,
    int fee_credits,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> amount_record,
    ffi.Pointer<Utf8> fee_record,
  ) {
    final tryTransfer = dyLib
        .lookupFunction<TypeTransferInRust, TypeTransferInDart>('try_transfer');

    return tryTransfer(private_key, recipient, transfer_type, amount_credits,
        fee_credits, url, amount_record, fee_record);
  }
}
