import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;

import 'package:aleo_dart/src/rust_lib/programs_rust_ffi.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';

class AleoProgram {
  late ProgramsRustFFI programsRustFFI;

  // Long-lived: the network pointer is held for the object's lifetime and
  // passed to every call, so it is not freed per-call.
  AleoProgram(dyLib, [network_raw = 'testnet']) {
    final network = dartStrToC(network_raw);
    this.programsRustFFI = ProgramsRustFFI(dyLib, network);
  }

  Future<String> tryTransfer(
    String private_key_raw,
    String recipient_raw,
    String transfer_type_raw,
    int amount_credits,
    int fee_credits,
    String url_raw,
    String amount_record_raw,
    String fee_record_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final transfer_type = dartStrToC(transfer_type_raw);
    final recipient = dartStrToC(recipient_raw);
    final url = dartStrToC(url_raw);
    final amount_record = dartStrToC(amount_record_raw);
    final fee_record = dartStrToC(fee_record_raw);
    final result = await programsRustFFI.transfer(
        private_key,
        recipient,
        transfer_type,
        amount_credits,
        fee_credits,
        url,
        amount_record,
        fee_record);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([
      private_key,
      transfer_type,
      recipient,
      url,
      amount_record,
      fee_record
    ]);
    return out;
  }

  Future<String> tryJoin(
    String private_key_raw,
    String record_1_raw,
    String record_2_raw,
    int fee_credits,
    String fee_record_raw,
    String url_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final record_1 = dartStrToC(record_1_raw);
    final record_2 = dartStrToC(record_2_raw);
    final fee_record = dartStrToC(fee_record_raw);
    final url = dartStrToC(url_raw);
    final result = await programsRustFFI.join(
        private_key, record_1, record_2, fee_credits, fee_record, url);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([private_key, record_1, record_2, fee_record, url]);
    return out;
  }

  Future<String> joinAuthorization(
    String private_key_raw,
    String record_1_raw,
    String record_2_raw,
    String url_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final record_1 = dartStrToC(record_1_raw);
    final record_2 = dartStrToC(record_2_raw);
    final url = dartStrToC(url_raw);
    final result = await programsRustFFI.joinAuthorization(
        private_key, record_1, record_2, url);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([private_key, record_1, record_2, url]);
    return out;
  }

  Future<String> upgradeAuthorization(
    String private_key_raw,
    String record_raw,
    String url_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final record = dartStrToC(record_raw);
    final url = dartStrToC(url_raw);
    final result =
        await programsRustFFI.upgradeAuthorization(private_key, record, url);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([private_key, record, url]);
    return out;
  }

  Future<String> buildTransaction(
    String private_key_raw,
    String recipient_raw,
    String transfer_type_raw,
    int amount_credits,
    int fee_credits,
    String url_raw,
    String amount_record_raw,
    String fee_record_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final transfer_type = dartStrToC(transfer_type_raw);
    final recipient = dartStrToC(recipient_raw);
    final url = dartStrToC(url_raw);
    final amount_record = dartStrToC(amount_record_raw);
    final fee_record = dartStrToC(fee_record_raw);

    final result = await programsRustFFI.buildTransaction(
        private_key,
        recipient,
        transfer_type,
        amount_credits,
        fee_credits,
        url,
        amount_record,
        fee_record);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([
      private_key,
      transfer_type,
      recipient,
      url,
      amount_record,
      fee_record
    ]);
    return out;
  }

  Future<String> broadcast(
    String transaction_raw,
    String url_raw,
    String transfer_type_raw,
  ) async {
    final transaction = dartStrToC(transaction_raw);
    final url = dartStrToC(url_raw);
    final transfer_type = dartStrToC(transfer_type_raw);

    final result =
        await programsRustFFI.broadcast(transaction, url, transfer_type);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([transaction, url, transfer_type]);
    return out;
  }

  Future<String> executionAuthorization(
    String private_key_raw,
    String recipient_raw,
    String transfer_type_raw,
    int amount_credits,
    String url_raw,
    String amount_record_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final transfer_type = dartStrToC(transfer_type_raw);
    final recipient = dartStrToC(recipient_raw);
    final url = dartStrToC(url_raw);
    final amount_record = dartStrToC(amount_record_raw);

    final result = await programsRustFFI.executionAuthorization(private_key,
        recipient, transfer_type, amount_credits, url, amount_record);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([private_key, transfer_type, recipient, url, amount_record]);
    return out;
  }

  Future<String> executionFeeAuthorization(
      String private_key_raw,
      String transfer_type_raw,
      int fee_credits,
      String url_raw,
      String fee_record_raw,
      String execution_raw) async {
    final private_key = dartStrToC(private_key_raw);
    final transfer_type = dartStrToC(transfer_type_raw);
    final url = dartStrToC(url_raw);
    final fee_record = dartStrToC(fee_record_raw);
    final execution = dartStrToC(execution_raw);

    final result = await programsRustFFI.executionFeeAuthorization(
        private_key, transfer_type, fee_credits, url, fee_record, execution);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([private_key, transfer_type, url, fee_record, execution]);
    return out;
  }

  Future<String> executeProof(String url_raw, String authorization_raw) async {
    final url = dartStrToC(url_raw);
    final authorization = dartStrToC(authorization_raw);
    final result = await programsRustFFI.executeProof(url, authorization);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([url, authorization]);
    return out;
  }

  Future<String> executeProgramProof(String url_raw, String authorization_raw,
      {String program_id_raw = 'credits.aleo'}) async {
    final url = dartStrToC(url_raw);
    final authorization = dartStrToC(authorization_raw);
    final program_id = dartStrToC(program_id_raw);
    final result = await programsRustFFI.executeProgramProof(
        url, authorization, program_id);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([url, authorization, program_id]);
    return out;
  }

  Future<String> executeFeeProof(
    String url_raw,
    String authorization_raw,
  ) async {
    final url = dartStrToC(url_raw);
    final authorization = dartStrToC(authorization_raw);
    final result = await programsRustFFI.executeFeeProof(url, authorization);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([url, authorization]);
    return out;
  }

  Future<String> buildTransactionOffline(
    String execution_raw,
    String fee_raw,
  ) async {
    final execution = dartStrToC(execution_raw);
    final fee = dartStrToC(fee_raw);
    final result =
        await programsRustFFI.buildTransactionOffline(execution, fee);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([execution, fee]);
    return out;
  }

  Future<String> buildUpgradeTransactionOffline(
    String execution_raw,
  ) async {
    final execution = dartStrToC(execution_raw);
    final result =
        await programsRustFFI.buildUpgradeTransactionOffline(execution);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([execution]);
    return out;
  }

  Future<int> getBaseFee(
    String url_raw,
    String execution_raw,
  ) async {
    final execution = dartStrToC(execution_raw);
    final url = dartStrToC(url_raw);
    final result = await programsRustFFI.getBaseFee(url, execution);
    freeAll([execution, url]);
    return result;
  }

  Future<void> downloadProvingKey({updateKey = false}) async {
    late final rootPath;
    if (Platform.isLinux) {
      var rootDirectory = Directory.current;
      var parts = path.split(rootDirectory.path);
      rootPath = parts[0] + parts[1] + '/' + parts[2] + '/';
    }
    final savePath = rootPath + '.aleo/resources/inclusion.prover.cd85cc5';

    final file = File(savePath);

    if (file.existsSync() || !updateKey) {
      return;
    } else {
      print('start downloading');
      const downLoadUrl =
          'https://s3-us-west-1.amazonaws.com/testnet.parameters/inclusion.prover.cd85cc5';
      await downloadFile(downLoadUrl, savePath);
    }
    return;
  }

  Future<String> contractExecution(
    String private_key_raw,
    String program_id_raw,
    String function_name_raw,
    String arguments_raw,
    String url_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final program_id = dartStrToC(program_id_raw);
    final function_name = dartStrToC(function_name_raw);
    final arguments = dartStrToC(arguments_raw);
    final url = dartStrToC(url_raw);
    final result = await programsRustFFI.contractExecution(
        private_key, program_id, function_name, arguments, url);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([private_key, program_id, function_name, arguments, url]);
    return out;
  }

  Future<String> executeProgram(
    String private_key_raw,
    String program_id_raw,
    String function_name_raw,
    String arguments_raw,
    int fee,
    String url_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final program_id = dartStrToC(program_id_raw);
    final function_name = dartStrToC(function_name_raw);
    final arguments = dartStrToC(arguments_raw);
    final url = dartStrToC(url_raw);
    final result = await programsRustFFI.executeProgram(
        private_key, program_id, function_name, arguments, fee, url);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([private_key, program_id, function_name, arguments, url]);
    return out;
  }

  Future<String> contractFeeExecution(
    String private_key_raw,
    int fee,
    String execution_raw,
    String program_id_raw,
    String url_raw,
  ) async {
    final private_key = dartStrToC(private_key_raw);
    final execution = dartStrToC(execution_raw);
    final program_id = dartStrToC(program_id_raw);
    final url = dartStrToC(url_raw);
    final result = await programsRustFFI.contractFeeExecution(
        private_key, fee, execution, program_id, url);
    final out = takeNativeString(programsRustFFI.dyLib, result);
    freeAll([private_key, execution, program_id, url]);
    return out;
  }

  String modifyAuthorization(
    String authorizationJson,
  ) {
    final authorization = json.decode(authorizationJson);
    final data = {'requests': [], 'transitions': []};
    final transitions = authorization['transitions'];
    for (var request in authorization['requests']) {
      final program = request['program'];
      final function = request['function'];
      for (var transition in transitions) {
        if (transition['program'] == program &&
            transition['function'] == function) {
          data['transitions']!.add(transition);
          data['requests']!.add(request);
        }
      }
    }
    return json.encode(data);
  }
}

Future<void> downloadFile(String url, String savePath) async {
  final httpClient = HttpClient();
  final request =
      await httpClient.getUrl(Uri.parse(url)).timeout(Duration(minutes: 3));
  final response = await request.close();
  final file = File(savePath);
  await file.create(recursive: true);
  final output = file.openWrite();

  int totalBytes = response.contentLength;
  int receivedBytes = 0;

  await response.forEach((data) {
    output.add(data);
    receivedBytes += data.length;
    print('downing: ${(receivedBytes / totalBytes * 100).toStringAsFixed(2)}%');
  }).timeout(Duration(minutes: 3), onTimeout: () {
    throw Exception('timeout');
  }).catchError((error) {
    print('downing error: $error');
    output.close();
    file.deleteSync();
    throw error;
  });

  await output.close();
}
