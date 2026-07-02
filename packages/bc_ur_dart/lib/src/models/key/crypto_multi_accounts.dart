import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/models/key/to_string_fields.dart';
import 'package:bc_ur_dart/src/registry/cbor_field_reader.dart';
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
    final reader = CborFieldReader.fromUr(ur, model: 'crypto-multi-accounts', expectedType: mtiType);

    // field 1: masterFingerprint
    final fpRaw = reader.requiredInt(1, field: 'master_fingerprint', min: 0, max: 0xffffffff);
    final fpBytes = Uint8List(4)..buffer.asByteData().setUint32(0, fpRaw, Endian.big);
    final masterFingerprint = hex.encode(fpBytes);

    // field 2: keys 列表
    final keysValue = reader.requiredList(2, field: 'keys');
    final chainList = <CryptoHDKeyUR>[];

    for (var index = 0; index < keysValue.length; index++) {
      final item = keysValue[index];
      if (item is! CborMap) {
        throw InvalidCborURException(model: 'crypto-multi-accounts', field: 'keys[$index]', reason: 'expected CborMap, got ${item.runtimeType}');
      }
      final keyUr = UR(
        type: hdType,
        payload: Uint8List.fromList(cbor.encode(item)),
      );
      try {
        chainList.add(CryptoHDKeyUR.fromUR(ur: keyUr));
      } on Object catch (error) {
        throw InvalidCborURException(model: 'crypto-multi-accounts', field: 'keys[$index]', reason: 'invalid crypto-hdkey entry', cause: error);
      }
    }

    // field 3: device（可选）
    final device = reader.optionalText(3, field: 'device') ?? '';

    // field 4: deviceId（可选）
    final deviceId = reader.optionalText(4, field: 'device_id');

    // field 5: version（可选）
    final version = reader.optionalText(5, field: 'version');

    // field 6: walletName（私有扩展，可选）
    final walletName = reader.optionalText(6, field: 'wallet_name');
    final hasXfpFormatMarker = reader.has(7);
    final xfpFormat = reader.optionalText(7, field: 'xfp_format') ?? 'canonical';

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
  String toString() {
    final fields = CompactToStringFields();

    fields.addString('masterFingerprint', masterFingerprint);
    fields.addString('walletName', walletName);
    fields.addString('device', device);
    fields.addString('deviceId', deviceId);
    fields.addString('version', version);
    fields.addString('xfpFormat', xfpFormat);
    fields.addRaw('chains', '[${chains.map((e) => e.toString()).join(',')}]');
    return fields.toString();
  }
}
