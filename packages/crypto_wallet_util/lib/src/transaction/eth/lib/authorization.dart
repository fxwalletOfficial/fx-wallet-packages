// EIP-7702: Authorization
import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/rlp.dart' as rlp;
import 'package:crypto_wallet_util/src/transaction/eth/lib/utils.dart';

final EIP7702_MAGIC = '0x05';

class Eip7702Authorization {
  final int chainId;
  final String address; // contract address
  String? gasPayerAddress;
  String? signerAddress;
  final int signerNonce; // singer nonce
  int? v;
  String? r;
  String? s;

  Eip7702Authorization({
    required this.chainId,
    required this.address,
    this.gasPayerAddress,
    this.signerAddress,
    required this.signerNonce,
    this.v,
    this.r,
    this.s,
  });

  toJson() {
    return {
      'address': address,
      'chainId': chainId,
      'nonce': signerNonce,
      'signature': {
        'r': r,
        's': s,
        'v': v,
      },
    };
  }

  factory Eip7702Authorization.deserialize(decodeData) {
    final chainId = hexToBigInt(dynamicToString(decodeData[0])).toInt();
    final address = dynamicToHex(decodeData[1]);
    final signerNonce = hexToBigInt(dynamicToString(decodeData[2])).toInt();

    Eip7702Authorization authorization = Eip7702Authorization(
      chainId: chainId,
      address: address,
      signerNonce: signerNonce,
    );

    if (decodeData.length == 6) {
      authorization.v = hexToBigInt(dynamicToString(decodeData[3])).toInt();
      authorization.r = dynamicToHex(decodeData[4]);
      authorization.s = dynamicToHex(decodeData[5]);
    }

    return authorization;
  }

  Eip7702Authorization sign(String privateKey) {
    int nonce = signerNonce;
    if (signerAddress == gasPayerAddress) nonce++;

    // 1. RLP encode [chainId, address, nonce]
    final items = [
      intToBuffer(chainId), // chainId to bytes32
      address.toLowerCase(), // address to lower case
      intToBuffer(nonce), // nonce to bytes32
    ];
    final rlpData =
        Uint8List.fromList(EIP7702_MAGIC.toUint8List() + rlp.encode(items));
    final hash = getKeccakDigest(rlpData);
    final signature =
        EcdaSignature.sign(hash.toStr(), privateKey.toUint8List());

    return Eip7702Authorization(
        chainId: chainId,
        address: address,
        gasPayerAddress: gasPayerAddress,
        signerAddress: signerAddress,
        signerNonce: nonce,
        v: signature.v,
        r: signature.r.toHex(),
        s: signature.s.toHex());
  }
}
