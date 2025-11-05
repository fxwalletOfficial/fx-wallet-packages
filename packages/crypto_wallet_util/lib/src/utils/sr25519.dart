import 'dart:convert';
import 'dart:typed_data';

import 'package:sr25519/sr25519.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Provide SR25519 [sign] and [verify].
class SR25519 {
  static Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    final MiniSecretKey priv =
        MiniSecretKey.fromHex(dynamicToString(privateKey));
    final PublicKey pub = priv.public();
    final publicBytes = pub.encode();
    return Uint8List.fromList(publicBytes);
  }

  static Uint8List sign(Uint8List privateKey, dynamic message) {
    final MiniSecretKey priv =
        MiniSecretKey.fromHex(dynamicToString(privateKey));
    var sk = priv.expandEd25519();
    final transcript =
        Sr25519.newSigningContext(utf8.encode('substrate'), message);
    final signature = sk.sign(transcript);
    return dynamicToUint8List(signature.encode());
  }

  static bool verify(
      Uint8List publicKey, String signedMessage, String message) {
    Signature signature = Signature.fromHex(signedMessage);
    final PublicKey pubKey = PublicKey.fromHex(dynamicToString(publicKey));
    final result =
        Sr25519.verify(pubKey, signature, dynamicToUint8List(message));
    return result.$1;
  }
}
