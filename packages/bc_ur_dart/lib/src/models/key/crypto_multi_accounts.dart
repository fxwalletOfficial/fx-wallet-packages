import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:convert/convert.dart';

final mtiType = RegistryType.CRYPTO_MULTI_ACCOUNTS.type;

class CryptoMultiAccountsUR extends UR {
  final List<CryptoHDKeyUR> chains;
  final String masterFingerprint;
  final String device;
  final String? xfpFormat;
  final bool hasXfpFormatMarker;
  final String? deviceId; // field 4: Keystone 设备唯一 ID
  final String? version; // field 5: 固件版本
  final String? walletName; // field 6: 私有扩展字段，非 Keystone 标准

  CryptoMultiAccountsUR({
    required UR ur,
    required this.chains,
    required this.device,
    required this.masterFingerprint,
    this.deviceId,
    this.version,
    this.walletName,
    this.xfpFormat,
    this.hasXfpFormatMarker = false,
  }) : super(payload: ur.payload, type: ur.type);

  static CryptoMultiAccountsUR fromUR({required UR ur}) {
    if (ur.type.toLowerCase() != mtiType) {
      throw Exception('Invalid type');
    }
    final data = ur.decodeCBOR() as CborMap;

    // field 1: masterFingerprint，按大端序读取（UInt32BE）
    final fpRaw = (data[CborSmallInt(1)] as CborInt).toInt();
    final fpBytes = Uint8List(4)..buffer.asByteData().setUint32(0, fpRaw, Endian.big);
    final masterFingerprint = hex.encode(fpBytes);

    // field 2: keys 列表
    final keysRaw = data[CborSmallInt(2)] as CborList;
    final chainList = <CryptoHDKeyUR>[];
    for (final item in keysRaw) {
      // 每个 key 是一个带有 CRYPTO_HDKEY tag 的 CborMap
      final keyMap = item as CborMap;
      // 创建临时 UR 用于解析 CryptoHDKeyUR
      final keyUr = UR(
        type: hdType,
        payload: Uint8List.fromList(cbor.encode(keyMap)),
      );
      final chainInfo = CryptoHDKeyUR.fromUR(ur: keyUr);
      chainList.add(chainInfo);
    }

    // field 3: device（可选）
    final device = data[CborSmallInt(3)]?.toString() ?? '';

    // field 4: deviceId（可选）
    final deviceId = data[CborSmallInt(4)]?.toString();

    // field 5: version（可选）
    final version = data[CborSmallInt(5)]?.toString();

    // field 6: walletName（私有扩展，可选）
    final walletName = data[CborSmallInt(6)]?.toString();
    final hasXfpFormatMarker = data.containsKey(CborSmallInt(7));
    final xfpFormat = data[CborSmallInt(7)]?.toString() ?? 'canonical';

    return CryptoMultiAccountsUR(
      ur: ur,
      chains: chainList,
      device: device,
      masterFingerprint: masterFingerprint,
      deviceId: deviceId,
      version: version,
      walletName: walletName,
      xfpFormat: xfpFormat,
      hasXfpFormatMarker: hasXfpFormatMarker,
    );
  }

  static CryptoMultiAccountsUR fromWallet({
    required BigInt masterFingerprint,
    required String device,
    String? deviceId,
    String version = '1.0.0',
    required List<CryptoHDKeyUR> chains,
    String? walletName,
    String? xfpFormat,
  }) {
    final xfp = getXfp(masterFingerprint, reverseBytes: false);

    // BigInt 直接转 int，按大端序写入 CBOR（UInt32BE），与规范一致
    final fpInt = masterFingerprint.toInt();

    final ur = UR.fromCBOR(
      type: mtiType,
      value: CborMap({
        CborSmallInt(1): CborInt(BigInt.from(fpInt)),
        CborSmallInt(2): CborList(chains.map((e) => e.decodeCBOR()).toList()),
        if (device.isNotEmpty) CborSmallInt(3): CborString(device),
        if (deviceId != null && deviceId.isNotEmpty) CborSmallInt(4): CborString(deviceId),
        CborSmallInt(5): CborString(version),
        if (walletName != null && walletName.isNotEmpty) CborSmallInt(6): CborString(walletName),
        if (xfpFormat != null && xfpFormat.isNotEmpty) CborSmallInt(7): CborString(xfpFormat),
      }),
    );

    return CryptoMultiAccountsUR(
      ur: ur,
      chains: chains,
      device: device,
      masterFingerprint: xfp,
      deviceId: deviceId,
      version: version,
      walletName: walletName,
      xfpFormat: xfpFormat,
      hasXfpFormatMarker: xfpFormat != null && xfpFormat.isNotEmpty,
    );
  }

  @override
  String toString() => '''
{
"masterFingerprint":"$masterFingerprint",
"walletName":"${walletName ?? ''}",
"device":"$device",
"deviceId":"${deviceId ?? ''}",
"version":"${version ?? ''}",
"xfpFormat":"${xfpFormat ?? ''}",
"chains":${chains.map((e) => e.toString()).join(',')}
}
  ''';
}
