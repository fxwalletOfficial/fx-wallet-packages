import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;

import 'package:aleo_dart/src/rust_lib/account_rust_ffi.dart';
import 'package:aleo_dart/src/aleo_hd_key.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';

const ALEO_PATH = "m/44/0/0/0";

class AleoAccount {
  late AccountRustFFI accountRustFFI;

  AleoAccount(dyLib) {
    this.accountRustFFI = AccountRustFFI(dyLib);
  }

  int testRustFFi(int a, int b) {
    return accountRustFFI.testRustFFi(a, b);
  }

  Uint8List mnemonicToSeed(String mnemonic) {
    final rootSeed = bip39.mnemonicToSeed(mnemonic);
    return derive(ALEO_PATH, rootSeed);
  }

  String seedToPrivateKey(Uint8List seedRaw) {
    final seed = dartListToC(seedRaw);
    final privateKey = accountRustFFI.seedToPrivateKey(seed);
    return cStrToDart(privateKey);
  }

  String mnemonicToPrivateKey(String mnemonic) {
    final seed = mnemonicToSeed(mnemonic);
    return seedToPrivateKey(seed);
  }

  String privateKeyToAddress(String privateKeyRaw) {
    final privateKey = dartStrToC(privateKeyRaw);
    final address = accountRustFFI.privateKeyToAddress(privateKey);
    return cStrToDart(address);
  }

  String mnemonicToAddress(String mnemonic) {
    final rootSeed = mnemonicToSeed(mnemonic);
    final privateKey = seedToPrivateKey(rootSeed);
    return privateKeyToAddress(privateKey);
  }

  String privateKeyToViewKey(String privateKeyRaw) {
    final privateKey = dartStrToC(privateKeyRaw);
    final viewKey = accountRustFFI.privateKeyToViewKey(privateKey);
    return cStrToDart(viewKey);
  }

  String mnemonicToViewKey(String mnemonic) {
    final seed = mnemonicToSeed(mnemonic);
    final privateKeyRaw = seedToPrivateKey(seed);
    final privateKey = dartStrToC(privateKeyRaw);
    final viewKey = accountRustFFI.privateKeyToViewKey(privateKey);
    return cStrToDart(viewKey);
  }

  String viewKeyToAddress(String viewKeyRaw) {
    final viewKey = dartStrToC(viewKeyRaw);
    final address = accountRustFFI.viewKeyToAddress(viewKey);
    return cStrToDart(address);
  }

  String sign(String privateKeyRaw, Uint8List messageRaw) {
    final privateKey = dartStrToC(privateKeyRaw);
    final message = dartListToC(messageRaw);
    final signature =
        accountRustFFI.sign(privateKey, message, messageRaw.length);
    return cStrToDart(signature);
  }

  bool isValidSignature(
      String addressRaw, String signatureRaw, Uint8List messageRaw) {
    final address = dartStrToC(addressRaw);
    final signature = dartStrToC(signatureRaw);
    final message = dartListToC(messageRaw);
    return accountRustFFI.isValidSignature(
        address, signature, message, messageRaw.length);
  }
}
