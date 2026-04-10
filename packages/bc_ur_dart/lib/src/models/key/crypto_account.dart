import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:convert/convert.dart';

final accountType = RegistryType.CRYPTO_ACCOUNT.type;

class CryptoAccountUR extends UR {
  final String masterFingerprint;
  final List<CryptoHDKeyUR> outputs;
  final String? xfpFormat;
  final bool hasXfpFormatMarker;

  CryptoAccountUR({
    required UR ur,
    required this.masterFingerprint,
    required this.outputs,
    this.xfpFormat,
    this.hasXfpFormatMarker = false,
  }) : super(payload: ur.payload, type: ur.type);

  static CryptoAccountUR fromUR({required UR ur}) {
    if (ur.type.toLowerCase() != accountType) {
      throw Exception('Invalid type');
    }

    final data = ur.decodeCBOR() as CborMap;
    if (!RegistryItem.hasKey(data, 1)) {
      throw ArgumentError('Missing required field: master fingerprint (field 1)');
    }
    if (!RegistryItem.hasKey(data, 2)) {
      throw ArgumentError('Missing required field: outputs (field 2)');
    }

    final fpRaw = (data[CborSmallInt(1)] as CborInt).toInt();
    final fpBytes = Uint8List(4)..buffer.asByteData().setUint32(0, fpRaw, Endian.big);
    final masterFingerprint = hex.encode(fpBytes);

    final outputsRaw = data[CborSmallInt(2)] as CborList;
    final outputs = <CryptoHDKeyUR>[];
    for (final item in outputsRaw) {
      final keyMap = item as CborMap;
      final keyUr = UR(
        type: hdType,
        payload: Uint8List.fromList(cbor.encode(keyMap)),
      );
      outputs.add(CryptoHDKeyUR.fromUR(ur: keyUr));
    }

    final hasXfpFormatMarker = RegistryItem.hasKey(data, 3);
    final xfpFormat = data[CborSmallInt(3)]?.toString();

    return CryptoAccountUR(
      ur: ur,
      masterFingerprint: masterFingerprint,
      outputs: outputs,
      xfpFormat: xfpFormat,
      hasXfpFormatMarker: hasXfpFormatMarker,
    );
  }

  static CryptoAccountUR fromWallet({
    required BigInt masterFingerprint,
    required List<CryptoHDKeyUR> outputs,
    String? xfpFormat,
  }) {
    final fpInt = masterFingerprint.toInt();
    final ur = UR.fromCBOR(
      type: accountType,
      value: CborMap({
        CborSmallInt(1): CborInt(BigInt.from(fpInt)),
        CborSmallInt(2): CborList(outputs.map((e) => e.decodeCBOR()).toList()),
        if (xfpFormat != null && xfpFormat.isNotEmpty) CborSmallInt(3): CborString(xfpFormat),
      }),
    );

    final fpBytes = Uint8List(4)..buffer.asByteData().setUint32(0, fpInt, Endian.big);
    return CryptoAccountUR(
      ur: ur,
      masterFingerprint: hex.encode(fpBytes),
      outputs: outputs,
      xfpFormat: xfpFormat,
      hasXfpFormatMarker: xfpFormat != null && xfpFormat.isNotEmpty,
    );
  }

  @override
  String toString() {
    return '''
{
"masterFingerprint":"$masterFingerprint",
"xfpFormat":"${xfpFormat ?? ''}",
"outputs":[${outputs.map((e) => e.toString()).join(',')}]
}
  ''';
  }
}
