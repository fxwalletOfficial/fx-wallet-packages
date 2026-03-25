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
  final String? sourceFingerprint;
  final String? childrenPath;
  final String? note;

  CryptoHDKeyUR({
    required UR ur,
    required this.path,
    required this.name,
    required this.wallet,
    this.xfp,
    this.sourceFingerprint,
    this.childrenPath,
    this.note,
  }) : super(payload: ur.payload, type: ur.type);

  CryptoHDKeyUR.fromWallet({
    required this.name,
    required this.path,
    required this.wallet,
    this.xfp,
    this.sourceFingerprint,
    this.childrenPath,
    this.note,
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
    final origin = data[CborSmallInt(6)] as CborMap;
    final components = origin[CborSmallInt(1)] as CborList;
    final name = (data[CborSmallInt(9)] as CborString).toString();
    final note = (data[CborSmallInt(10)] as CborString?)?.toString();

    final path = _parseKeyPath(components);
    final children = data[CborSmallInt(7)] as CborMap?;
    final childrenComponents = children?[CborSmallInt(1)] as CborList?;
    final childrenPath = childrenComponents == null
        ? null
        : _parseKeyPath(childrenComponents, includeRoot: false);
    final sourceFingerprint = _parseSourceFingerprint(origin[CborSmallInt(2)]);
    final index = _lastIndex(components);

    final wallet = BIP32.fromPublicKey(publicKey, chainCode);
    wallet.parentFingerprint = parentFingerprint;
    wallet.depth = (components.length / 2).round();
    wallet.index = index;

    return CryptoHDKeyUR(
      ur: ur,
      wallet: wallet,
      path: path,
      name: name,
      sourceFingerprint: sourceFingerprint,
      childrenPath: childrenPath,
      note: note,
    );
  }

  @override
  String toString() => '''
{
"derivationPath":"$path",
"childrenPath":"${childrenPath ?? ''}",
"sourceFingerprint":"${sourceFingerprint ?? ''}",
"masterFingerprint":"${hex.encode(wallet.fingerprint)}",
"extendedPublicKey": "${wallet.toBase58()}",
"chainCode": "${hex.encode(wallet.chainCode)}",
"walletName":"$name",
"note":"${note ?? ''}"
}
  ''';

  static String _parseKeyPath(CborList components, {bool includeRoot = true}) {
    var path = includeRoot ? 'm' : '';
    for (var i = 0; i < components.length; i += 2) {
      final index = components[i];
      final hardened = (components[i + 1] as CborBool).value;
      final part = index is CborSmallInt
          ? '${index.value}${hardened ? "'" : ''}'
          : '*${hardened ? "'" : ''}';
      path += includeRoot || path.isNotEmpty ? '/$part' : part;
    }
    return path;
  }

  static int _lastIndex(CborList components) {
    var index = 0;
    for (var i = 0; i < components.length; i += 2) {
      final value = components[i];
      final hardened = (components[i + 1] as CborBool).value;
      if (value is CborSmallInt) {
        index = value.value;
        if (hardened) index += HIGHEST_BIT;
      }
    }
    return index;
  }

  static String? _parseSourceFingerprint(CborValue? value) {
    if (value is! CborInt) return null;
    final bytes = Uint8List(4);
    bytes.buffer.asByteData().setUint32(0, value.toInt(), Endian.little);
    return hex.encode(bytes).toUpperCase();
  }
}
