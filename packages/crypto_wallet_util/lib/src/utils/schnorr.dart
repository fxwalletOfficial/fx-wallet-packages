import 'dart:typed_data';

import 'package:bip340/bip340.dart' as bip340;

import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Provide Schnorr [sign] and [verify].
class Schnorr {
  static String sign(Uint8List privateKey, String message, [String? random]) {
    final String aux = random ?? generateRandomString();
    return bip340.sign(dynamicToString(privateKey), message, aux);
  }

  static bool verify(Uint8List publicKey, String signature, String message) {
    return bip340.verify(dynamicToString(publicKey), message, signature);
  }
}
