import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha512.dart';
import 'package:pointycastle/key_derivators/api.dart' show Pbkdf2Parameters;
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

class PBKDF2 {
  final int blockLength;
  final int iterationCount;
  final int desiredKeyLength;
  final String saltPrefix = "mnemonic";

  final PBKDF2KeyDerivator derivator;

  PBKDF2({
    this.blockLength = 128,
    this.iterationCount = 2048,
    this.desiredKeyLength = 64
  }) : derivator = PBKDF2KeyDerivator(HMac(SHA512Digest(), blockLength));

  Uint8List process(String mnemonic, {String passphrase = ''}) {
    final salt = Uint8List.fromList(utf8.encode(saltPrefix + passphrase));
    derivator.reset();
    derivator.init(Pbkdf2Parameters(salt, iterationCount, desiredKeyLength));
    return derivator.process(Uint8List.fromList(mnemonic.codeUnits));
  }
}
