import 'package:aleo_dart/src/rust_lib/record_rust_ffi.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';
import 'package:ffi/ffi.dart';

String encryptPrivateKey(privateKeyRaw, secretRaw) {
  final privateKey = dartStrToC(privateKeyRaw);
  final secret = dartStrToC(secretRaw);
  final ciphertext = RecordRustFFI.encryptPrivateKey(privateKey, secret);
  return ciphertext.toDartString();
}

String decryptToPrivateKey(ciphertextRaw, secretRaw) {
  final ciphertext = dartStrToC(ciphertextRaw);
  final secret = dartStrToC(secretRaw);
  final privateKey = RecordRustFFI.decryptToPrivateKey(ciphertext, secret);
  return privateKey.toDartString();
}

String serialNumberString(String recordPlainTextRaw, String privateKeyRaw,
    String programIdRaw, String recordNameRaw) {
  final recordPlainText = dartStrToC(recordPlainTextRaw);
  final privateKey = dartStrToC(privateKeyRaw);
  final programId = dartStrToC(programIdRaw);
  final recordName = dartStrToC(recordNameRaw);
  final result = RecordRustFFI.serialNumberString(
      recordPlainText, privateKey, programId, recordName);
  return result.toDartString();
}

String decryptCipherText(String record, String viewKey) {
  final result =
      RecordRustFFI.decryptCipherText(dartStrToC(record), dartStrToC(viewKey));
  return result.toDartString();
}

bool isOwner(String record, String viewKey) {
  return RecordRustFFI.isOwner(dartStrToC(record), dartStrToC(viewKey));
}
