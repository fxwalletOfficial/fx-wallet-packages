import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;
import 'package:ffi/ffi.dart';

import 'package:aleo_dart/src/rust_lib/account_rust_ffi.dart';
import 'package:aleo_dart/src/aleo_hd_key.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';
import 'package:aleo_dart/src/aleo_utils.dart';

const ALEO_PATH = "m/44/0/0/0";

class AleoAccount {
  late AccountRustFFI accountRustFFI;
  AleoAccount(dyLib, [String network_raw = 'testnet']) {
    this.accountRustFFI = AccountRustFFI(dyLib, network_raw);
  }

  int testRustFFi(int a, int b) {
    return accountRustFFI.testRustFFi(a, b);
  }

  Uint8List mnemonicToSeed(String mnemonic, {String path = ALEO_PATH}) {
    final rootSeed = bip39.mnemonicToSeed(mnemonic);
    return derive(path, rootSeed);
  }

  String seedToPrivateKey(Uint8List seedRaw) {
    final seed = dartListToC(seedRaw);
    final result = accountRustFFI.seedToPrivateKey(seed);
    final privateKey = takeNativeString(accountRustFFI.dyLib, result);
    calloc.free(seed);
    return privateKey;
  }

  String mnemonicToPrivateKey(String mnemonic) {
    final seed = mnemonicToSeed(mnemonic);
    return seedToPrivateKey(seed);
  }

  String privateKeyToAddress(String privateKeyRaw) {
    AleoUtils.checkPrivateKey(privateKeyRaw);
    final privateKey = dartStrToC(privateKeyRaw);
    final result = accountRustFFI.privateKeyToAddress(privateKey);
    final address = takeNativeString(accountRustFFI.dyLib, result);
    malloc.free(privateKey);
    return address;
  }

  String mnemonicToAddress(String mnemonic) {
    final rootSeed = mnemonicToSeed(mnemonic);
    final privateKey = seedToPrivateKey(rootSeed);
    return privateKeyToAddress(privateKey);
  }

  String privateKeyToViewKey(String privateKeyRaw) {
    AleoUtils.checkPrivateKey(privateKeyRaw);
    final privateKey = dartStrToC(privateKeyRaw);
    final result = accountRustFFI.privateKeyToViewKey(privateKey);
    final viewKey = takeNativeString(accountRustFFI.dyLib, result);
    malloc.free(privateKey);
    return viewKey;
  }

  String mnemonicToViewKey(String mnemonic) {
    final seed = mnemonicToSeed(mnemonic);
    final privateKeyRaw = seedToPrivateKey(seed);
    final privateKey = dartStrToC(privateKeyRaw);
    final result = accountRustFFI.privateKeyToViewKey(privateKey);
    final viewKey = takeNativeString(accountRustFFI.dyLib, result);
    malloc.free(privateKey);
    return viewKey;
  }

  String viewKeyToAddress(String viewKeyRaw) {
    AleoUtils.checkViewKey(viewKeyRaw);
    final viewKey = dartStrToC(viewKeyRaw);
    final result = accountRustFFI.viewKeyToAddress(viewKey);
    final address = takeNativeString(accountRustFFI.dyLib, result);
    malloc.free(viewKey);
    return address;
  }

  String sign(String privateKeyRaw, Uint8List messageRaw) {
    final privateKey = dartStrToC(privateKeyRaw);
    final message = dartListToC(messageRaw);
    final result = accountRustFFI.sign(privateKey, message, messageRaw.length);
    final signature = takeNativeString(accountRustFFI.dyLib, result);
    malloc.free(privateKey);
    calloc.free(message);
    return signature;
  }

  bool isValidSignature(
      String addressRaw, String signatureRaw, Uint8List messageRaw) {
    final address = dartStrToC(addressRaw);
    final signature = dartStrToC(signatureRaw);
    final message = dartListToC(messageRaw);
    final valid = accountRustFFI.isValidSignature(
        address, signature, message, messageRaw.length);
    malloc.free(address);
    malloc.free(signature);
    calloc.free(message);
    return valid;
  }

  String getTokenOwnerHash(String addressRaw, String tokenIdRaw) {
    final address = dartStrToC(addressRaw);
    final tokenId = dartStrToC(tokenIdRaw);
    final result = accountRustFFI.getTokenOwnerHash(address, tokenId);
    final tokenOwnerHash = takeNativeString(accountRustFFI.dyLib, result);
    malloc.free(address);
    malloc.free(tokenId);
    return tokenOwnerHash;
  }
}
