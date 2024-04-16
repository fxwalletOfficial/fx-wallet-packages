import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'package:aleo_dart/src/rust_lib/programs_rust_ffi.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';

class AleoProgram {
  late ProgramsRustFFI programsRustFFI;

  AleoProgram(dyLib) {
    this.programsRustFFI = ProgramsRustFFI(dyLib);
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
    return result.toDartString();
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
    return result.toDartString();
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
    return result.toDartString();
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
    return result.toDartString();
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
    return result.toDartString();
  }

  Future<String> executeProof(
    String url_raw,
    String authorization_raw,
  ) async {
    final url = dartStrToC(url_raw);
    final authorization = dartStrToC(authorization_raw);
    final result = await programsRustFFI.executeProof(url, authorization);
    return result.toDartString();
  }

  Future<String> executeFeeProof(
    String url_raw,
    String authorization_raw,
  ) async {
    final url = dartStrToC(url_raw);
    final authorization = dartStrToC(authorization_raw);
    final result = await programsRustFFI.executeFeeProof(url, authorization);
    return result.toDartString();
  }

  Future<String> buildTransactionOffline(
    String execution_raw,
    String fee_raw,
  ) async {
    final execution = dartStrToC(execution_raw);
    final fee = dartStrToC(fee_raw);
    final result =
        await programsRustFFI.buildTransactionOffline(execution, fee);
    return result.toDartString();
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
          'https://s3-us-west-1.amazonaws.com/testnet3.parameters/inclusion.prover.cd85cc5';
      await downloadFile(downLoadUrl, savePath);
    }
    return;
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
