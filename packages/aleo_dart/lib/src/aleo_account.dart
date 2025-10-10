import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;

import 'package:aleo_dart/src/rust_lib/account_rust_ffi.dart';
import 'package:aleo_dart/src/aleo_hd_key.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';
import 'package:aleo_dart/src/aleo_utils.dart';

const ALEO_PATH = "m/44/0/0/0";

class AleoAccount {
  late AccountRustFFI accountRustFFI;
  AleoAccount(dyLib, [network_raw = 'testnet']) {
    final network = dartStrToC(network_raw);
    this.accountRustFFI = AccountRustFFI(dyLib, network);
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
    final privateKey = accountRustFFI.seedToPrivateKey(seed);
    return cStrToDart(privateKey);
  }

  String mnemonicToPrivateKey(String mnemonic) {
    final seed = mnemonicToSeed(mnemonic);
    return seedToPrivateKey(seed);
  }

  String privateKeyToAddress(String privateKeyRaw) {
    AleoUtils.checkPrivateKey(privateKeyRaw);
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
    AleoUtils.checkPrivateKey(privateKeyRaw);
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
    AleoUtils.checkViewKey(viewKeyRaw);
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

  String getTokenOwnerHash(String addressRaw, String tokenIdRaw) {
    final address = dartStrToC(addressRaw);
    final tokenId = dartStrToC(tokenIdRaw);
    final tokenOwnerHash = accountRustFFI.getTokenOwnerHash(address, tokenId);
    return cStrToDart(tokenOwnerHash);
  }
}
