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

class AccountRustFFI {
  late ffi.DynamicLibrary dyLib;

  AccountRustFFI(dyLib) {
    this.dyLib = dyLib;
  }
  int testRustFFi(int a, int b) {
    var numbers_add = this
        .dyLib
        .lookupFunction<TypeTestInRust, TypeTestInDart>('numbers_add');
    final result = numbers_add(a, b);
    return result;
  }

  ffi.Pointer<Utf8> seedToPrivateKey(ffi.Pointer<ffi.Uint8> seed) {
    final seedToPrivateKey = this
        .dyLib
        .lookupFunction<TypeU8listToString, TypeU8listToString>(
            'seedToPrivateKey');
    return seedToPrivateKey(seed);
  }

  ffi.Pointer<Utf8> privateKeyToAddress(ffi.Pointer<Utf8> privateKey) {
    final privateKeyToAddress = this
        .dyLib
        .lookupFunction<TypeStringToString, TypeStringToString>(
            'privateKeyToAddress');
    return privateKeyToAddress(privateKey);
  }

  ffi.Pointer<Utf8> privateKeyToViewKey(ffi.Pointer<Utf8> privateKey) {
    final privateKeyToViewKey = this
        .dyLib
        .lookupFunction<TypeStringToString, TypeStringToString>(
            'privateKeyToViewKey');
    return privateKeyToViewKey(privateKey);
  }

  ffi.Pointer<Utf8> viewKeyToAddress(ffi.Pointer<Utf8> privateKey) {
    final viewKeyToAddress = this
        .dyLib
        .lookupFunction<TypeStringToString, TypeStringToString>(
            'viewKeyToAddress');
    return viewKeyToAddress(privateKey);
  }

  ffi.Pointer<Utf8> sign(ffi.Pointer<Utf8> privateKey,
      ffi.Pointer<ffi.Uint8> message, int length) {
    final signMessage = this
        .dyLib
        .lookupFunction<TypeSignInRust, TypeSignInDart>('signMessage');
    return signMessage(privateKey, message, length);
  }

  bool isValidSignature(ffi.Pointer<Utf8> address, ffi.Pointer<Utf8> signature,
      ffi.Pointer<ffi.Uint8> message, int length) {
    final verify =
        this.dyLib.lookupFunction<TypeVerifyInRust, TypeVerifyInDart>('verify');
    final result = verify(address, signature, message, length);
    return result != 0;
  }
}
