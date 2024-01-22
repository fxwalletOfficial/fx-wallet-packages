import 'dart:typed_data';

import 'package:bip39/bip39.dart' as bip39;

import 'package:aleo_dart/src/rust_lib/rust_ffi.dart';
import 'package:aleo_dart/src/aleo_hd_key.dart';

int testRustFFi(int a, int b) {
  return RustFFI.testRustFFi(a, b);
}

const ALEO_PATH = "m/44/0/0/0";

Uint8List mnemonicToSeed(String mnemonic) {
  final rootSeed = bip39.mnemonicToSeed(mnemonic);
  return derive(ALEO_PATH, rootSeed);
}
