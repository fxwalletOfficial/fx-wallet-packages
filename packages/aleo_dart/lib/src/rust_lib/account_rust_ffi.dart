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

typedef TypeGetTokenOwnerHashInRust = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);
typedef TypeGetTokenOwnerHashInDart = ffi.Pointer<Utf8> Function(
    ffi.Pointer<Utf8>, ffi.Pointer<Utf8>);

class AccountRustFFI {
  final ffi.DynamicLibrary dyLib;
  final String network;

  AccountRustFFI(this.dyLib, this.network);

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
            'seed_to_private_key');
    return seedToPrivateKey(seed);
  }

  ffi.Pointer<Utf8> privateKeyToAddress(ffi.Pointer<Utf8> privateKey) {
    final privateKeyToAddress = this
        .dyLib
        .lookupFunction<TypeStringToString, TypeStringToString>(
            'private_key_to_address');
    return privateKeyToAddress(privateKey);
  }

  ffi.Pointer<Utf8> privateKeyToViewKey(ffi.Pointer<Utf8> privateKey) {
    final privateKeyToViewKey = this
        .dyLib
        .lookupFunction<TypeStringToString, TypeStringToString>(
            'private_key_to_view_key');
    return privateKeyToViewKey(privateKey);
  }

  ffi.Pointer<Utf8> viewKeyToAddress(ffi.Pointer<Utf8> privateKey) {
    final viewKeyToAddress = this
        .dyLib
        .lookupFunction<TypeStringToString, TypeStringToString>(
            'view_key_to_address');
    return viewKeyToAddress(privateKey);
  }

  ffi.Pointer<Utf8> sign(ffi.Pointer<Utf8> privateKey,
      ffi.Pointer<ffi.Uint8> message, int length) {
    final signMessage = this
        .dyLib
        .lookupFunction<TypeSignInRust, TypeSignInDart>('sign_message');
    return signMessage(privateKey, message, length);
  }

  bool isValidSignature(ffi.Pointer<Utf8> address, ffi.Pointer<Utf8> signature,
      ffi.Pointer<ffi.Uint8> message, int length) {
    final verify =
        this.dyLib.lookupFunction<TypeVerifyInRust, TypeVerifyInDart>('verify');
    final result = verify(address, signature, message, length);
    return result != 0;
  }

  ffi.Pointer<Utf8> getTokenOwnerHash(
      ffi.Pointer<Utf8> address, ffi.Pointer<Utf8> tokenId) {
    final getTokenOwnerHash = this.dyLib.lookupFunction<
        TypeGetTokenOwnerHashInRust,
        TypeGetTokenOwnerHashInDart>('get_token_owner_hash');
    return getTokenOwnerHash(address, tokenId);
  }
}
