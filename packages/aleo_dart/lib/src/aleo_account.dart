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
    try {
      final result = accountRustFFI.seedToPrivateKey(seed);
      return takeNativeString(accountRustFFI.dyLib, result);
    } finally {
      calloc.free(seed);
    }
  }

  String mnemonicToPrivateKey(String mnemonic) {
    final seed = mnemonicToSeed(mnemonic);
    return seedToPrivateKey(seed);
  }

  String privateKeyToAddress(String privateKeyRaw) {
    AleoUtils.checkPrivateKey(privateKeyRaw);
    final privateKey = dartStrToC(privateKeyRaw);
    try {
      final result = accountRustFFI.privateKeyToAddress(privateKey);
      return takeNativeString(accountRustFFI.dyLib, result);
    } finally {
      malloc.free(privateKey);
    }
  }

  String mnemonicToAddress(String mnemonic) {
    final rootSeed = mnemonicToSeed(mnemonic);
    final privateKey = seedToPrivateKey(rootSeed);
    return privateKeyToAddress(privateKey);
  }

  String privateKeyToViewKey(String privateKeyRaw) {
    AleoUtils.checkPrivateKey(privateKeyRaw);
    final privateKey = dartStrToC(privateKeyRaw);
    try {
      final result = accountRustFFI.privateKeyToViewKey(privateKey);
      return takeNativeString(accountRustFFI.dyLib, result);
    } finally {
      malloc.free(privateKey);
    }
  }

  String mnemonicToViewKey(String mnemonic) {
    final seed = mnemonicToSeed(mnemonic);
    final privateKeyRaw = seedToPrivateKey(seed);
    return privateKeyToViewKey(privateKeyRaw);
  }

  String viewKeyToAddress(String viewKeyRaw) {
    AleoUtils.checkViewKey(viewKeyRaw);
    final viewKey = dartStrToC(viewKeyRaw);
    try {
      final result = accountRustFFI.viewKeyToAddress(viewKey);
      return takeNativeString(accountRustFFI.dyLib, result);
    } finally {
      malloc.free(viewKey);
    }
  }

  String sign(String privateKeyRaw, Uint8List messageRaw) {
    final privateKey = dartStrToC(privateKeyRaw);
    final message = dartListToC(messageRaw);
    try {
      final result =
          accountRustFFI.sign(privateKey, message, messageRaw.length);
      return takeNativeString(accountRustFFI.dyLib, result);
    } finally {
      malloc.free(privateKey);
      calloc.free(message);
    }
  }

  bool isValidSignature(
      String addressRaw, String signatureRaw, Uint8List messageRaw) {
    final address = dartStrToC(addressRaw);
    final signature = dartStrToC(signatureRaw);
    final message = dartListToC(messageRaw);
    try {
      return accountRustFFI.isValidSignature(
          address, signature, message, messageRaw.length);
    } finally {
      malloc.free(address);
      malloc.free(signature);
      calloc.free(message);
    }
  }

  String getTokenOwnerHash(String addressRaw, String tokenIdRaw) {
    final address = dartStrToC(addressRaw);
    final tokenId = dartStrToC(tokenIdRaw);
    try {
      final result = accountRustFFI.getTokenOwnerHash(address, tokenId);
      return takeNativeString(accountRustFFI.dyLib, result);
    } finally {
      malloc.free(address);
      malloc.free(tokenId);
    }
  }
}
