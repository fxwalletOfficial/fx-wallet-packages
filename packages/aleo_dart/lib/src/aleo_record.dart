import 'package:aleo_dart/src/rust_lib/record_rust_ffi.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';
import 'package:ffi/ffi.dart';

class AleoRecord {
  late RecordRustFFI recordRustFFI;

  AleoRecord(dyLib) {
    this.recordRustFFI = RecordRustFFI(dyLib);
  }

  String encryptPrivateKey(privateKeyRaw, secretRaw) {
    final privateKey = dartStrToC(privateKeyRaw);
    final secret = dartStrToC(secretRaw);
    final ciphertext = recordRustFFI.encryptPrivateKey(privateKey, secret);
    return ciphertext.toDartString();
  }

  String decryptToPrivateKey(ciphertextRaw, secretRaw) {
    final ciphertext = dartStrToC(ciphertextRaw);
    final secret = dartStrToC(secretRaw);
    final privateKey = recordRustFFI.decryptToPrivateKey(ciphertext, secret);
    return privateKey.toDartString();
  }

  String decryptCipherText(String record, String viewKey) {
    final result = recordRustFFI.decryptCipherText(
        dartStrToC(record), dartStrToC(viewKey));
    return result.toDartString();
  }

  bool isOwner(String record, String viewKey) {
    return recordRustFFI.isOwner(dartStrToC(record), dartStrToC(viewKey));
  }
}
