import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

final ffi.DynamicLibrary dyLib =
    ffi.DynamicLibrary.open('./aleo_rust/wasm/target/debug/libaleo_wasm.so');

typedef TypeStr2To1 = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeStr4To1 = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

typedef TypeStr2ToBoolInRust = ffi.Int32 Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef TypeStr2ToBoolInDart = int Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

class RecordRustFFI {
  static ffi.Pointer<Utf8> encryptPrivateKey(
      ffi.Pointer<Utf8> privateKey, ffi.Pointer<Utf8> secret) {
    final encryptPrivateKey =
        dyLib.lookupFunction<TypeStr2To1, TypeStr2To1>('encryptPrivateKey');
    return encryptPrivateKey(privateKey, secret);
  }

  static ffi.Pointer<Utf8> decryptToPrivateKey(
      ffi.Pointer<Utf8> ciphertext, ffi.Pointer<Utf8> secret) {
    final decryptToPrivateKey =
        dyLib.lookupFunction<TypeStr2To1, TypeStr2To1>('decryptToPrivateKey');
    return decryptToPrivateKey(ciphertext, secret);
  }

  static ffi.Pointer<Utf8> serialNumberString(
      ffi.Pointer<Utf8> recordPlainText,
      ffi.Pointer<Utf8> privateKey,
      ffi.Pointer<Utf8> programId,
      ffi.Pointer<Utf8> recordName) {
    final serialNumberString =
        dyLib.lookupFunction<TypeStr4To1, TypeStr4To1>('serialNumberString');
    return serialNumberString(
        recordPlainText, privateKey, programId, recordName);
  }

  static ffi.Pointer<Utf8> decryptCipherText(
      ffi.Pointer<Utf8> record, ffi.Pointer<Utf8> viewKey) {
    final decryptCipherText =
        dyLib.lookupFunction<TypeStr2To1, TypeStr2To1>('decryptCipherText');
    return decryptCipherText(record, viewKey);
  }

  static bool isOwner(ffi.Pointer<Utf8> record, ffi.Pointer<Utf8> viewKey) {
    final isOwner = dyLib
        .lookupFunction<TypeStr2ToBoolInRust, TypeStr2ToBoolInDart>('isOwner');
    return isOwner(record, viewKey) != 0;
  }
}
