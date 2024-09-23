import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

typedef TypeStr2To1 = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeStr4To1 = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeStr2ToBoolInRust = ffi.Int32 Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef TypeStr2ToBoolInDart = int Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

class RecordRustFFI {
  final ffi.DynamicLibrary dyLib;
  final network;

  RecordRustFFI(this.dyLib, this.network);

  ffi.Pointer<Utf8> encryptPrivateKey(
      ffi.Pointer<Utf8> privateKey, ffi.Pointer<Utf8> secret) {
    final encryptPrivateKey =
        dyLib.lookupFunction<TypeStr2To1, TypeStr2To1>('encrypt_private_key');
    return encryptPrivateKey(privateKey, secret);
  }

  ffi.Pointer<Utf8> decryptToPrivateKey(
      ffi.Pointer<Utf8> ciphertext, ffi.Pointer<Utf8> secret) {
    final decryptToPrivateKey =
        dyLib.lookupFunction<TypeStr2To1, TypeStr2To1>('decrypt_to_private_key');
    return decryptToPrivateKey(ciphertext, secret);
  }

  ffi.Pointer<Utf8> decryptCipherText(
      ffi.Pointer<Utf8> record, ffi.Pointer<Utf8> viewKey) {
    final decryptCipherText =
        dyLib.lookupFunction<TypeStr2To1, TypeStr2To1>('decrypt_cipher_text');
    return decryptCipherText(record, viewKey);
  }

  bool isOwner(ffi.Pointer<Utf8> record, ffi.Pointer<Utf8> viewKey) {
    final isOwner = dyLib
        .lookupFunction<TypeStr2ToBoolInRust, TypeStr2ToBoolInDart>('is_owner');
    return isOwner(record, viewKey) != 0;
  }

  ffi.Pointer<Utf8> serialNumberString(
      ffi.Pointer<Utf8> recordCipherText,
      ffi.Pointer<Utf8> privateKey,
      ffi.Pointer<Utf8> programId,
      ffi.Pointer<Utf8> recordName) {
    final serialNumberString =
        dyLib.lookupFunction<TypeStr4To1, TypeStr4To1>('serial_number_string');
    return serialNumberString(
        recordCipherText, privateKey, programId, recordName);
  }
}
