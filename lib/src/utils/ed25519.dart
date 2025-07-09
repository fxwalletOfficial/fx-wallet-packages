import 'package:pinenacl/ed25519.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Provide ED25519 [sign] and [verify].
class ED25519 {
  static Uint8List privateKeyToPublicKey(Uint8List privateKey) {
    SigningKey keyPair = SigningKey.fromSeed(privateKey);
    return Uint8List.fromList(keyPair.publicKey);
  }

  static Uint8List sign(Uint8List privateKey, dynamic message) {
    SigningKey keyPair = SigningKey.fromSeed(privateKey);
    SignedMessage signedMessage = keyPair.sign(dynamicToUint8List(message));
    return Uint8List.fromList(signedMessage.signature);
  }

  static bool verify(Uint8List publicKey, dynamic signature, dynamic message) {
    VerifyKey verifyKey = VerifyKey(Uint8List.fromList(publicKey));
    SignedMessage signedMessage =
        SignedMessage.fromList(signedMessage: dynamicToUint8List(signature));
    return verifyKey.verify(
        signature: signedMessage.signature,
        message: dynamicToUint8List(message));
  }
}
