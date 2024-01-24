import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';

typedef TypeTestInRust = ffi.Int Function(ffi.Int, ffi.Int);

typedef TypeTestInDart = int Function(int, int);

typedef TypeU8listToString = ffi.Pointer<Utf8> Function(ffi.Pointer<ffi.Uint8>);

typedef TypeStringToString = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>);

typedef TypeSignInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<ffi.Uint8>, ffi.Int32);
typedef TypeSignInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<ffi.Uint8>, int);

typedef TypeVerifyInRust = ffi.Int32 Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<ffi.Uint8>, ffi.Int32);
typedef TypeVerifyInDart = int Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<ffi.Uint8>, int);

final ffi.DynamicLibrary dyLib =
    ffi.DynamicLibrary.open('./aleo_rust/target/debug/libaleo_wasm.so');

class AccountRustFFI {
  static int testRustFFi(int a, int b) {
    var numbers_add =
        dyLib.lookupFunction<TypeTestInRust, TypeTestInDart>('numbers_add');
    final result = numbers_add(a, b);
    return result;
  }

  static ffi.Pointer<Utf8> seedToPrivateKey(ffi.Pointer<ffi.Uint8> seed) {
    final seedToPrivateKey =
        dyLib.lookupFunction<TypeU8listToString, TypeU8listToString>(
            'seedToPrivateKey');
    return seedToPrivateKey(seed);
  }

  static ffi.Pointer<Utf8> privateKeyToAddress(ffi.Pointer<Utf8> privateKey) {
    final privateKeyToAddress =
        dyLib.lookupFunction<TypeStringToString, TypeStringToString>(
            'privateKeyToAddress');
    return privateKeyToAddress(privateKey);
  }

  static ffi.Pointer<Utf8> privateKeyToViewKey(ffi.Pointer<Utf8> privateKey) {
    final privateKeyToViewKey =
        dyLib.lookupFunction<TypeStringToString, TypeStringToString>(
            'privateKeyToViewKey');
    return privateKeyToViewKey(privateKey);
  }

  static ffi.Pointer<Utf8> viewKeyToAddress(ffi.Pointer<Utf8> privateKey) {
    final viewKeyToAddress =
        dyLib.lookupFunction<TypeStringToString, TypeStringToString>(
            'viewKeyToAddress');
    return viewKeyToAddress(privateKey);
  }

  static ffi.Pointer<Utf8> sign(ffi.Pointer<Utf8> privateKey,
      ffi.Pointer<ffi.Uint8> message, int length) {
    final signMessage =
        dyLib.lookupFunction<TypeSignInRust, TypeSignInDart>('signMessage');
    return signMessage(privateKey, message, length);
  }

  static bool isValidSignature(ffi.Pointer<Utf8> address,
      ffi.Pointer<Utf8> signature, ffi.Pointer<ffi.Uint8> message, int length) {
    final verify =
        dyLib.lookupFunction<TypeVerifyInRust, TypeVerifyInDart>('verify');
    final result = verify(address, signature, message, length);
    return result != 0;
  }
}
