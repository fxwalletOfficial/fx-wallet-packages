import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Ethereum Signed Message (EIP-191) signature and verification wrapper
class EthMessageSigner {
  /// Calculate keccak256 hash for Ethereum Signed Message
  static Uint8List ethereumMessageHash(String message) {
    final messageBytes = utf8.encode(message);
    final prefix = utf8.encode(
        "\u0019Ethereum Signed Message:\n${messageBytes.length}");
    final data = Uint8List.fromList([...prefix, ...messageBytes]);
    return getKeccakDigest(data);
  }

  /// Sign message using private key
  /// Returns 65-byte signature (r||s||v)
  static String signMessage(String message, Uint8List privateKey) {
    final hashed = ethereumMessageHash(message);
    final signature = EcdaSignature.sign(dynamicToString(hashed), privateKey);
    return '0x${signature.getSignatureWithRecId()}';
  }

  /// Verify signature: recover signer address from message and signature
  static bool verifyMessage(String message, String signature, Uint8List publicKey) {
    if (signature.length != 132) { // 0x + 130 (r+s+v as hex)
      throw ArgumentError('Signature must be 132 characters (0x + r + s + v)');
    }

    final hashed = ethereumMessageHash(message);
    return EcdaSignature.verify(dynamicToString(hashed), publicKey, signature);
  }
}
