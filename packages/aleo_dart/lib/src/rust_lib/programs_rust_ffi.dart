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

typedef TypeBroadcast = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeAuthorizationInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeAuthorizationInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeProof = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

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
    final rustFunction = dyLib
        .lookupFunction<TypeTransferInRust, TypeTransferInDart>('try_transfer');

    return rustFunction(private_key, recipient, transfer_type, amount_credits,
        fee_credits, url, amount_record, fee_record);
  }

  ffi.Pointer<Utf8> buildTransaction(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> recipient,
    ffi.Pointer<Utf8> transfer_type,
    int amount_credits,
    int fee_credits,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> amount_record,
    ffi.Pointer<Utf8> fee_record,
  ) {
    final rustFunction =
        dyLib.lookupFunction<TypeTransferInRust, TypeTransferInDart>(
            'build_transaction');

    return rustFunction(private_key, recipient, transfer_type, amount_credits,
        fee_credits, url, amount_record, fee_record);
  }

  ffi.Pointer<Utf8> broadcast(
    ffi.Pointer<Utf8> transaction,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> transfer_type,
  ) {
    final rustFunction =
        dyLib.lookupFunction<TypeBroadcast, TypeBroadcast>('broadcast');

    return rustFunction(transaction, url, transfer_type);
  }

  ffi.Pointer<Utf8> executionAuthorization(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> recipient,
    ffi.Pointer<Utf8> transfer_type,
    int amount_credits,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> amount_record,
  ) {
    final rustFunction =
        dyLib.lookupFunction<TypeAuthorizationInRust, TypeAuthorizationInDart>(
            'execution_authorization');

    return rustFunction(private_key, recipient, transfer_type, amount_credits,
        url, amount_record);
  }

  ffi.Pointer<Utf8> executionFeeAuthorization(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> transfer_type,
    int fee_credits,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> fee_record,
    ffi.Pointer<Utf8> execution,
  ) {
    final rustFunction =
        dyLib.lookupFunction<TypeAuthorizationInRust, TypeAuthorizationInDart>(
            'execution_fee_authorization');

    return rustFunction(
        private_key, transfer_type, url, fee_credits, fee_record, execution);
  }

  ffi.Pointer<Utf8> executeProof(
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> authorization,
  ) {
    final rustFunction =
        dyLib.lookupFunction<TypeProof, TypeProof>('execute_proof');

    return rustFunction(url, authorization);
  }

  ffi.Pointer<Utf8> executeFeeProof(
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> authorization,
  ) {
    final rustFunction =
        dyLib.lookupFunction<TypeProof, TypeProof>('execute_fee_proof');

    return rustFunction(url, authorization);
  }

  ffi.Pointer<Utf8> buildTransactionOffline(
    ffi.Pointer<Utf8> execution,
    ffi.Pointer<Utf8> fee,
  ) {
    final rustFunction =
        dyLib.lookupFunction<TypeProof, TypeProof>('build_transaction_offline');
    return rustFunction(execution, fee);
  }
}
