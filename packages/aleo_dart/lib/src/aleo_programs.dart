import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

import 'package:aleo_dart/src/rust_lib/programs_rust_ffi.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';
import 'package:aleo_dart/src/rust_lib/setup/library_locator.dart';

class TransferType {
  static const String public = 'transfer_public';
  static const String public_to_private = 'transfer_public_to_private';
  static const String private = 'transfer_private';
  static const String private_to_public = 'transfer_private_to_public';
}

class AleoProgram {
  late ProgramsRustFFI programsRustFFI;

  AleoProgram(dyLib) {
    this.programsRustFFI = ProgramsRustFFI(dyLib);
  }

  String tryTransfer(
    String private_key_raw,
    String recipient_raw,
    String transfer_type_raw,
    int amount_credits,
    int fee_credits,
    String url_raw,
    String amount_record_raw,
    String fee_record_raw,
  ) {
    final private_key = dartStrToC(private_key_raw);
    final transfer_type = dartStrToC(transfer_type_raw);
    final recipient = dartStrToC(recipient_raw);
    final url = dartStrToC(url_raw);
    final amount_record = dartStrToC(amount_record_raw);
    final fee_record = dartStrToC(fee_record_raw);

    return programsRustFFI
        .transfer(private_key, recipient, transfer_type, amount_credits,
            fee_credits, url, amount_record, fee_record)
        .toDartString();
  }

  String buildTransaction(
    String private_key_raw,
    String recipient_raw,
    String transfer_type_raw,
    int amount_credits,
    int fee_credits,
    String url_raw,
    String amount_record_raw,
    String fee_record_raw,
  ) {
    final private_key = dartStrToC(private_key_raw);
    final transfer_type = dartStrToC(transfer_type_raw);
    final recipient = dartStrToC(recipient_raw);
    final url = dartStrToC(url_raw);
    final amount_record = dartStrToC(amount_record_raw);
    final fee_record = dartStrToC(fee_record_raw);

    return programsRustFFI
        .buildTransaction(private_key, recipient, transfer_type, amount_credits,
            fee_credits, url, amount_record, fee_record)
        .toDartString();
  }

  String broadcast(
    String transaction_raw,
    String url_raw,
    String transfer_type_raw,
  ) {
    final transaction = dartStrToC(transaction_raw);
    final url = dartStrToC(url_raw);
    final transfer_type = dartStrToC(transfer_type_raw);

    return programsRustFFI
        .broadcast(transaction, url, transfer_type)
        .toDartString();
  }

  Future<void> downloadProvingKey() async {
    final client = HttpClient();
    late final rootPath;
    final root = libBuildOutDir();
    if (Platform.isLinux) {
      var rootDirectory = Directory.current;
      var parts = path.split(rootDirectory.path);
      rootPath = parts[0] + parts[1] + '/' + parts[2] + '/';
      print(rootPath);
    }
    client.connectionTimeout = Duration(seconds: 300);
    const downLoadUrl =
        'https://s3-us-west-1.amazonaws.com/testnet3.parameters/inclusion.prover.cd85cc5';
    final request = await client.getUrl(Uri.parse(downLoadUrl));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw Exception(
        'Could not download archive "$downLoadUrl":'
        ' ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    Future<File> writeToFile(String filePath, Stream<List<int>> stream) async {
      final file = File(root.resolve(filePath).toFilePath());
      await file.create(recursive: true);
      final sink = file.openWrite(mode: FileMode.writeOnly);
      await sink.addStream(stream);
      await sink.flush();
      await sink.close();
      return file;
    }

    final fileName = 'inclusion.prover.cd85cc5';
    final provingKey = await writeToFile('temp/$fileName', response);
    if (!provingKey.existsSync()) {
      throw Exception('Could not find library "${provingKey.path}"');
    }
    final outputPath = rootPath + '.aleo/resources/inclusion.prover.cd85cc5';
    final outputFile = await provingKey.rename(outputPath);
    print('Extracted library $provingKey to ${outputFile.path}');

    await Directory(root.resolve('temp').toFilePath()).delete(recursive: true);

    return;
  }
}
