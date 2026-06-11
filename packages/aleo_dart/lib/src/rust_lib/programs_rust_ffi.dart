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

typedef TypeUpgradeTransactionOffline = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeProof = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeExecuteProof = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeExecuteProgramProof = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeUpgradeAuthorization = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

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

typedef TypeContractExecutionInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeContractExecutionInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeExecuteProgramInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeExecuteProgramInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeContractFeeExecutionInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    ffi.Int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

typedef TypeContractFeeExecutionInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>,
    int,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>,
    ffi.Pointer<Utf8>);

class ProgramsRustFFI {
  final ffi.DynamicLibrary dyLib;
  final String network;

  ProgramsRustFFI(this.dyLib, this.network);

  /// Allocates a native copy of [network] for the duration of [action] and
  /// frees it afterwards. The native functions copy the string during the
  /// call, so no allocation needs to outlive it.
  T _withNetwork<T>(T Function(ffi.Pointer<Utf8> network) action) {
    final networkPtr = network.toNativeUtf8();
    try {
      return action(networkPtr);
    } finally {
      malloc.free(networkPtr);
    }
  }

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

    return _withNetwork((network) => rustFunction(
        private_key,
        recipient,
        transfer_type,
        amount_credits,
        fee_credits,
        url,
        amount_record,
        fee_record,
        network));
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

    return _withNetwork((network) => rustFunction(private_key, record_1,
        record_2, fee_credits, fee_record, url, network));
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

    return _withNetwork((network) =>
        rustFunction(private_key, record_1, record_2, url, network));
  }

  Future<ffi.Pointer<Utf8>> upgradeAuthorization(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> record,
    ffi.Pointer<Utf8> url,
  ) async {
    final rustFunction = dyLib.lookupFunction<TypeUpgradeAuthorization,
        TypeUpgradeAuthorization>('upgrade_authorization');

    return _withNetwork(
        (network) => rustFunction(private_key, record, url, network));
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

    return _withNetwork((network) => rustFunction(
        private_key,
        recipient,
        transfer_type,
        amount_credits,
        fee_credits,
        url,
        amount_record,
        fee_record,
        network));
  }

  Future<ffi.Pointer<Utf8>> broadcast(
    ffi.Pointer<Utf8> transaction,
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> transfer_type,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeBroadcast, TypeBroadcast>('broadcast');

    return _withNetwork(
        (network) => rustFunction(transaction, url, transfer_type, network));
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

    return _withNetwork((network) => rustFunction(private_key, recipient,
        transfer_type, amount_credits, url, amount_record, network));
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

    return _withNetwork((network) => rustFunction(private_key, transfer_type,
        url, fee_credits, fee_record, execution, network));
  }

  Future<ffi.Pointer<Utf8>> executeProof(
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> authorization,
  ) async {
    final rustFunction = dyLib
        .lookupFunction<TypeExecuteProof, TypeExecuteProof>('execute_proof');

    return _withNetwork((network) => rustFunction(url, authorization, network));
  }

  Future<ffi.Pointer<Utf8>> executeProgramProof(
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> authorization,
    ffi.Pointer<Utf8> program_id,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeExecuteProgramProof, TypeExecuteProgramProof>(
            'execute_program_proof');

    return _withNetwork(
        (network) => rustFunction(url, authorization, network, program_id));
  }

  Future<ffi.Pointer<Utf8>> executeFeeProof(
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> authorization,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeProof, TypeProof>('execute_fee_proof');

    return _withNetwork((network) => rustFunction(url, authorization, network));
  }

  Future<ffi.Pointer<Utf8>> buildTransactionOffline(
    ffi.Pointer<Utf8> execution,
    ffi.Pointer<Utf8> fee,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeProof, TypeProof>('build_transaction_offline');
    return _withNetwork((network) => rustFunction(execution, fee, network));
  }

  Future<ffi.Pointer<Utf8>> buildUpgradeTransactionOffline(
    ffi.Pointer<Utf8> execution,
  ) async {
    final rustFunction = dyLib.lookupFunction<TypeUpgradeTransactionOffline,
        TypeUpgradeTransactionOffline>('build_upgrade_transaction_offline');
    return _withNetwork((network) => rustFunction(execution, network));
  }

  Future<int> getBaseFee(
    ffi.Pointer<Utf8> url,
    ffi.Pointer<Utf8> execution,
  ) async {
    final rustFunction =
        dyLib.lookupFunction<TypeGetBaseFeeInRust, TypeGetBaseFeeInDart>(
            'get_base_fee');
    return _withNetwork((network) => rustFunction(url, execution, network));
  }

  Future<ffi.Pointer<Utf8>> executeProgram(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> program_id,
    ffi.Pointer<Utf8> function_name,
    ffi.Pointer<Utf8> arguments,
    int fee,
    ffi.Pointer<Utf8> url,
  ) async {
    final rustFunction = dyLib.lookupFunction<TypeExecuteProgramInRust,
        TypeExecuteProgramInDart>('execute_program');

    return _withNetwork((network) => rustFunction(
        private_key, program_id, function_name, arguments, fee, url, network));
  }

  Future<ffi.Pointer<Utf8>> contractExecution(
    ffi.Pointer<Utf8> private_key,
    ffi.Pointer<Utf8> program_id,
    ffi.Pointer<Utf8> function_name,
    ffi.Pointer<Utf8> arguments,
    ffi.Pointer<Utf8> url,
  ) async {
    final rustFunction = dyLib.lookupFunction<TypeContractExecutionInRust,
        TypeContractExecutionInDart>('contract_execution');
    return _withNetwork((network) => rustFunction(
        private_key, program_id, function_name, arguments, url, network));
  }

  Future<ffi.Pointer<Utf8>> contractFeeExecution(
    ffi.Pointer<Utf8> private_key,
    int fee,
    ffi.Pointer<Utf8> execution,
    ffi.Pointer<Utf8> program_id,
    ffi.Pointer<Utf8> url,
  ) async {
    final rustFunction = dyLib.lookupFunction<TypeContractFeeExecutionInRust,
        TypeContractFeeExecutionInDart>('contract_fee_execution');
    return _withNetwork((network) =>
        rustFunction(private_key, fee, execution, program_id, url, network));
  }
}
