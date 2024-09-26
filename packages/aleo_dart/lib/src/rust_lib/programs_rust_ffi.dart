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
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeBroadcast = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeAuthorizationInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeAuthorizationInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeProof = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeJoinInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeJoinInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeJoinAuthorization = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeGetBaseFeeInRust = ffi.Int Function(
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
);

typedef TypeGetBaseFeeInDart = int Function(
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
  ffi.Pointer<Utf8>,
);

class ProgramsRustFFI {
  final ffi.DynamicLibrary dyLib;
  final network;

  ProgramsRustFFI(this.dyLib, this.network);

  Future<ffi.Pointer<Utf8>> transfer(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> recipient,
    ffi.Pointer<Utf8> transfer_type,
    int amount_credits,
    int fee_credits,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> amount_record,
    ffi.Pointer<Utf8> fee_record,
  ) async {
    final rustFunction = dyLib
        .lookupFunction<TypeTransferInRust, TypeTransferInDart>('try_transfer');

    return rustFunction(private_key, recipient, transfer_type, amount_credits,
        fee_credits, url, amount_record, fee_record, this.network);
  }

  Future<ffi.Pointer<Utf8>> join(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> record_1,
    ffi.Pointer<Utf8> record_2,
    int fee_credits,
    ffi.Pointer<Utf8> fee_record,
    ffi.Pointer<Utf8> url,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeJoinInRust, TypeJoinInDart>('try_join');

    return rustFunction(private_key, record_1, record_2, fee_credits,
        fee_record, url, this.network);
  }

  Future<ffi.Pointer<Utf8>> joinAuthorization(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> record_1,
    ffi.Pointer<Utf8> record_2,
    ffi.Pointer<Utf8> url,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeJoinAuthorization, TypeJoinAuthorization>(
            'join_authorization');

    return rustFunction(private_key, record_1, record_2, url, this.network);
  }

  Future<ffi.Pointer<Utf8>> buildTransaction(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> recipient,
    ffi.Pointer<Utf8> transfer_type,
    int amount_credits,
    int fee_credits,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> amount_record,
    ffi.Pointer<Utf8> fee_record,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeTransferInRust, TypeTransferInDart>(
            'build_transaction');

    return rustFunction(private_key, recipient, transfer_type, amount_credits,
        fee_credits, url, amount_record, fee_record, this.network);
  }

  Future<ffi.Pointer<Utf8>> broadcast(
    ffi.Pointer<Utf8> transaction,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> transfer_type,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeBroadcast, TypeBroadcast>('broadcast');

    return rustFunction(transaction, url, transfer_type, this.network);
  }

  Future<ffi.Pointer<Utf8>> executionAuthorization(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> recipient,
    ffi.Pointer<Utf8> transfer_type,
    int amount_credits,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> amount_record,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeAuthorizationInRust, TypeAuthorizationInDart>(
            'execution_authorization');

    return rustFunction(private_key, recipient, transfer_type, amount_credits,
        url, amount_record, this.network);
  }

  Future<ffi.Pointer<Utf8>> executionFeeAuthorization(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> transfer_type,
    int fee_credits,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> fee_record,
    ffi.Pointer<Utf8> execution,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeAuthorizationInRust, TypeAuthorizationInDart>(
            'execution_fee_authorization');

    return rustFunction(private_key, transfer_type, url, fee_credits,
        fee_record, execution, this.network);
  }

  Future<ffi.Pointer<Utf8>> executeProof(
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> authorization,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeProof, TypeProof>('execute_proof');

    return rustFunction(url, authorization, this.network);
  }

  Future<ffi.Pointer<Utf8>> executeFeeProof(
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> authorization,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeProof, TypeProof>('execute_fee_proof');

    return rustFunction(url, authorization, this.network);
  }

  Future<ffi.Pointer<Utf8>> buildTransactionOffline(
    ffi.Pointer<Utf8> execution,
    ffi.Pointer<Utf8> fee,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeProof, TypeProof>('build_transaction_offline');
    return rustFunction(execution, fee, this.network);
  }

  Future<int> getBaseFee(
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> execution,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeGetBaseFeeInRust, TypeGetBaseFeeInDart>(
            'get_base_fee');
    return rustFunction(url, execution, this.network);
  }
}
