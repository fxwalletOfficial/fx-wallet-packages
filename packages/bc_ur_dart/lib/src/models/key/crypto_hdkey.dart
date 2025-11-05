import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:convert/convert.dart';

import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:crypto_wallet_util/crypto_utils.dart' show BIP32, HIGHEST_BIT;

const String CRYPTO_HD_KEY = 'CRYPTO-HDKEY';

class CryptoHDKeyUR extends UR {
  final BIP32 wallet;
  final String path;
  final String name;
  final String? xfp;

  CryptoHDKeyUR({
    required UR ur,
    required this.path,
    required this.name,
    required this.wallet,
    this.xfp
  }) : super(payload: ur.payload, type: ur.type);

  CryptoHDKeyUR.fromWallet({
    required this.name,
    required this.path,
    required this.wallet,
    this.xfp
  }) : super.fromCBOR(
    type: CRYPTO_HD_KEY,
    value: CborMap({
      CborSmallInt(3): CborBytes(wallet.publicKey),
      CborSmallInt(4): CborBytes(wallet.chainCode),
      CborSmallInt(6):  CborMap({
        CborSmallInt(1): CborList(getPath(path)),
        CborSmallInt(2): CborInt(BigInt.from(wallet.parentFingerprint))
      }, tags: [304]),
      CborSmallInt(8): CborInt(xfp == null || xfp.isEmpty ? BigInt.from(wallet.parentFingerprint) : toXfpCode(xfp, bigEndian: false)),
      CborSmallInt(9): CborString(name)
    })
  );

  static CryptoHDKeyUR fromUR({required UR ur}) {
    if (ur.type.toUpperCase() != CRYPTO_HD_KEY) throw Exception('Invalid type');

    final data = ur.decodeCBOR() as CborMap;

    final publicKey = Uint8List.fromList((data[CborSmallInt(3)] as CborBytes).bytes);
    final chainCode = Uint8List.fromList((data[CborSmallInt(4)] as CborBytes).bytes);
    final parentFingerprint = (data[CborSmallInt(8)] as CborInt).toInt();
    final components = (data[CborSmallInt(6)] as CborMap)[CborSmallInt(1)] as CborList;
    final name = (data[CborSmallInt(9)] as CborString).toString();

    String path = 'm';
    int index = 0;
    for (final item in components) {
      if (item is CborSmallInt) {
        path += '/${item.value}';
        index = item.value;
      }

      if (item is CborBool && item.value) {
        path += "'";
        index += HIGHEST_BIT;
      }
    }

    final wallet = BIP32.fromPublicKey(publicKey, chainCode);
    wallet.parentFingerprint = parentFingerprint;
    wallet.depth = (components.length / 2).round();
    wallet.index = index;

    return CryptoHDKeyUR(ur: ur, wallet: wallet, path: path, name: name);
  }

  @override
  String toString() => '''
{
"derivationPath":"$path",
"masterFingerprint":"${hex.encode(wallet.fingerprint)}",
"extendedPublicKey": "${wallet.toBase58()}",
"chainCode": "${hex.encode(wallet.chainCode)}",
"walletName":"$name"
}
  ''';
}