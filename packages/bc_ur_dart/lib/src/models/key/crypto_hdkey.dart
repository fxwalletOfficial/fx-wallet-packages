import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/models/key/to_string_fields.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:convert/convert.dart';
import 'package:crypto_wallet_util/crypto_utils.dart' show BIP32;

final hdType = RegistryType.CRYPTO_HDKEY.type;

class CryptoHDKeyUR extends UR {
  final BIP32? wallet;
  final String path;
  final String name;
  final String? xfp;
  final String? sourceFingerprint;
  final String? xfpFormat;
  final bool hasXfpFormatMarker;
  final String? childrenPath;
  final String? note;
  final bool? isMaster;
  final bool? isPrivateKey;
  final CryptoCoinInfo? useInfo;
  final Uint8List? publicKey;
  final Uint8List? chainCode;

  CryptoHDKeyUR({
    required UR ur,
    required this.path,
    required this.name,
    this.wallet,
    this.xfp,
    this.sourceFingerprint,
    this.xfpFormat,
    this.hasXfpFormatMarker = false,
    this.childrenPath,
    this.note,
    this.isMaster,
    this.isPrivateKey,
    this.useInfo,
    this.publicKey,
    this.chainCode,
  }) : super(payload: ur.payload, type: ur.type);

  CryptoHDKeyUR.fromWallet({
    required this.name,
    required this.path,
    this.wallet, // 可选，有 BIP32 wallet 时使用
    this.publicKey, // 直接提供公钥（当 wallet 为 null 时必须提供）
    this.chainCode, // 直接提供链码（当 wallet 为 null 时必须提供）
    this.xfp,
    this.sourceFingerprint,
    this.xfpFormat,
    bool? hasXfpFormatMarker,
    this.childrenPath,
    this.note,
    this.isMaster,
    this.isPrivateKey,
    this.useInfo,
  })  : hasXfpFormatMarker = hasXfpFormatMarker ?? (xfpFormat != null && xfpFormat.isNotEmpty),
        super.fromCBOR(
          type: hdType,
          value: CborMap(
            {
              // field 1: is_master (主密钥标识)
              if (isMaster != null) CborSmallInt(1): CborBool(isMaster),
              // field 2: is_private (私钥标识)
              if (isPrivateKey != null) CborSmallInt(2): CborBool(isPrivateKey),
              // field 3: public key (优先使用 wallet，否则使用提供的 publicKey)
              CborSmallInt(3): CborBytes(wallet?.publicKey ?? publicKey!),
              // field 4: chain_code (链码)
              if (wallet?.chainCode != null || chainCode != null) CborSmallInt(4): CborBytes(wallet?.chainCode ?? chainCode!),
              // field 5: use_info
              if (useInfo != null) CborSmallInt(5): useInfo.toCborValue(),
              // field 6: origin keypath
              CborSmallInt(6): CborMap({CborSmallInt(1): CborList(getPath(path)), CborSmallInt(2): CborInt(BigInt.from(wallet?.parentFingerprint ?? 0))}, tags: [304]),
              // field 7: children path
              if (childrenPath != null && childrenPath.isNotEmpty)
                CborSmallInt(7): CborMap(
                  {CborSmallInt(1): CborList(getPath('m/$childrenPath'))},
                  tags: [304],
                ),
              // field 8: parent_fingerprint / xfp
              if (wallet != null) CborSmallInt(8): CborInt(xfp == null || xfp.isEmpty ? BigInt.from(wallet.parentFingerprint) : toXfpCode(xfp, reverseBytes: false)),
              CborSmallInt(9): CborString(name),
              if (note != null && note.isNotEmpty) CborSmallInt(10): CborString(note),
              if (xfpFormat != null && xfpFormat.isNotEmpty) CborSmallInt(11): CborString(xfpFormat),
            },
          ),
        );

  static CryptoHDKeyUR fromUR({required UR ur}) {
    if (ur.type.toLowerCase() != hdType) {
      throw FormatException('Invalid crypto-hdkey UR type: ${ur.type}');
    }

    final CborMap data;
    try {
      data = ur.decodeCBOR() as CborMap;
    } catch (e) {
      throw FormatException('Invalid crypto-hdkey CBOR payload: $e');
    }

    // field 1: is_master
    final isMaster = data[CborSmallInt(1)] != null ? (data[CborSmallInt(1)] as CborBool).value : null;

    // field 2: is_private
    final isPrivateKey = data[CborSmallInt(2)] != null ? (data[CborSmallInt(2)] as CborBool).value : null;

    // field 3: public key (required)
    if (!RegistryItem.hasKey(data, 3)) {
      throw ArgumentError('Missing required field: public key (field 3)');
    }
    final publicKey = Uint8List.fromList((data[CborSmallInt(3)] as CborBytes).bytes);

    // field 4: chain code (optional - Solana 等可能没有)
    Uint8List? chainCode;
    if (RegistryItem.hasKey(data, 4)) {
      chainCode = Uint8List.fromList((data[CborSmallInt(4)] as CborBytes).bytes);
    }

    // field 5: use_info (CryptoCoinInfo) - field 5 是 tagged CborMap (tag 305)
    CryptoCoinInfo? useInfo;
    if (RegistryItem.hasKey(data, 5)) {
      try {
        final useInfoValue = data[CborSmallInt(5)];
        if (useInfoValue is CborMap) {
          useInfo = CryptoCoinInfo.empty().decodeFromCbor(useInfoValue) as CryptoCoinInfo;
        }
      } catch (_) {}
    }

    // field 6: origin keypath
    final keypath = RegistryItem.readKeypath(data, 6);
    final path = keypath.getPath() ?? 'm';

    // field 7: children path
    final childrenRaw = data[CborSmallInt(7)] as CborMap?;
    final childrenPath = childrenRaw == null ? null : (CryptoKeypath().decodeFromCbor(childrenRaw) as CryptoKeypath).getRelativePath();

    // field 8: parent_fingerprint (optional - 当无 wallet 时可能没有)
    int? parentFingerprint;
    if (RegistryItem.hasKey(data, 8)) {
      parentFingerprint = (data[CborSmallInt(8)] as CborInt).toInt();
    }

    // field 9: name (optional)
    String? name;
    if (RegistryItem.hasKey(data, 9)) {
      name = (data[CborSmallInt(9)] as CborString).toString();
    }

    // field 10: note (optional)
    String? note;
    if (RegistryItem.hasKey(data, 10)) {
      note = (data[CborSmallInt(10)] as CborString).toString();
    }

    // field 11: xfp format marker (private extension)
    final hasXfpFormatMarker = RegistryItem.hasKey(data, 11);
    final xfpFormat = data[CborSmallInt(11)]?.toString() ?? 'canonical';

    // sourceFingerprint from origin field 2
    final sourceFingerprint = keypath.sourceFingerprint != null ? hex.encode(keypath.sourceFingerprint!) : null;

    final index = keypath.components.isNotEmpty ? keypath.components.last.getIndex() ?? 0 : 0;

    // Build BIP32 wallet (仅当有 chainCode 且公钥属于 secp256k1 时才构建)。
    //
    // BIP32 只适用于 secp256k1；这里不能
    // 因单条非 secp 公钥导致整个 crypto-multi-accounts 导入失败，而是保留原始
    // publicKey / chainCode 交给上层按链类型处理。
    BIP32? wallet;
    if (chainCode != null) {
      try {
        wallet = BIP32.fromPublicKey(publicKey, chainCode);
      } catch (e) {
        if (!_allowsRawNonSecpKey(useInfo, path)) {
          throw FormatException('Invalid crypto-hdkey public key or chain code: $e');
        }
      }
      if (wallet != null) {
        wallet.parentFingerprint = parentFingerprint ?? 0;
        wallet.depth = keypath.depth ?? keypath.components.length;
        wallet.index = index;
      }
    }

    return CryptoHDKeyUR(
      ur: ur,
      wallet: wallet,
      path: path,
      name: name ?? '',
      sourceFingerprint: sourceFingerprint,
      xfpFormat: xfpFormat,
      hasXfpFormatMarker: hasXfpFormatMarker,
      childrenPath: childrenPath,
      note: note,
      isMaster: isMaster,
      isPrivateKey: isPrivateKey,
      useInfo: useInfo,
      publicKey: publicKey,
      chainCode: chainCode,
    );
  }

  @override
  String toString() {
    // 获取公钥和链码：优先使用 wallet，否则使用直接提供的字段
    final pubKey = wallet?.publicKey ?? publicKey;
    final chain = wallet?.chainCode ?? chainCode;
    final fields = CompactToStringFields();

    fields.addRaw('useInfo', useInfo?.toString());
    fields.addString('derivationPath', path);
    fields.addString('childrenPath', childrenPath);
    fields.addString('sourceFingerprint', sourceFingerprint);
    fields.addString('xfpFormat', xfpFormat);
    fields.addString('masterFingerprint', wallet != null ? hex.encode(wallet!.fingerprint) : null);
    fields.addString('extendedPublicKey', wallet?.toBase58());
    fields.addString('publicKey', pubKey != null && pubKey.isNotEmpty ? hex.encode(pubKey) : null);
    fields.addString('chainCode', chain != null && chain.isNotEmpty ? hex.encode(chain) : null);
    fields.addString('name', name);
    fields.addString('note', note);

    return fields.toString();
  }

  static bool _allowsRawNonSecpKey(CryptoCoinInfo? useInfo, String path) {
    final coinType = useInfo?.coinType ?? _coinTypeFromPath(path);
    return coinType == CoinType.SOL;
  }

  static int? _coinTypeFromPath(String path) {
    final match = RegExp(r"^m/44'/(\d+)'").firstMatch(path);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
