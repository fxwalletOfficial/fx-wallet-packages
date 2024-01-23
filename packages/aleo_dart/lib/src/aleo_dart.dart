import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;

import 'package:aleo_dart/src/rust_lib/rust_ffi.dart';
import 'package:aleo_dart/src/aleo_hd_key.dart';
import 'package:aleo_dart/src/rust_lib/utils.dart';

int testRustFFi(int a, int b) {
  return RustFFI.testRustFFi(a, b);
}

const ALEO_PATH = "m/44/0/0/0";

Uint8List mnemonicToSeed(String mnemonic) {
  final rootSeed = bip39.mnemonicToSeed(mnemonic);
  return derive(ALEO_PATH, rootSeed);
}

String seedToPrivateKey(Uint8List seedRaw) {
  final seed = dartListToC(seedRaw);
  final privateKey = RustFFI.seedToPrivateKey(seed);
  return cStrToDart(privateKey);
}

String mnemonicToPrivateKey(String mnemonic){
 final seed = mnemonicToSeed(mnemonic);
 return seedToPrivateKey(seed);
}

String privateKeyToAddress(String privateKeyRaw) {
  final privateKey = dartStrToC(privateKeyRaw);
  final address = RustFFI.privateKeyToAddress(privateKey);
  return cStrToDart(address);
}

String mnemonicToAddress(String mnemonic) {
  final rootSeed = mnemonicToSeed(mnemonic);
  final privateKey = seedToPrivateKey(rootSeed);
  return privateKeyToAddress(privateKey);
}

String privateKeyToViewKey(String privateKeyRaw) {
  final privateKey = dartStrToC(privateKeyRaw);
  final viewKey = RustFFI.privateKeyToViewKey(privateKey);
  return cStrToDart(viewKey);
}

String mnemonicToViewKey(String mnemonic) {
  final seed = mnemonicToSeed(mnemonic);
  final privateKeyRaw = seedToPrivateKey(seed);
  final privateKey = dartStrToC(privateKeyRaw);
  final viewKey = RustFFI.privateKeyToViewKey(privateKey);
  return cStrToDart(viewKey);
}

String viewKeyToAddress(String viewKeyRaw) {
  final viewKey = dartStrToC(viewKeyRaw);
  final address = RustFFI.viewKeyToAddress(viewKey);
  return cStrToDart(address);
}
