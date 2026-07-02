import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/models/key/to_string_fields.dart';
import 'package:bc_ur_dart/src/registry/cbor_field_reader.dart';
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
    final reader = CborFieldReader.fromUr(ur, model: 'crypto-account', expectedType: accountType);

    final fpRaw = reader.requiredInt(1, field: 'master_fingerprint', min: 0, max: 0xffffffff);
    final fpBytes = Uint8List(4)..buffer.asByteData().setUint32(0, fpRaw, Endian.big);
    final masterFingerprint = hex.encode(fpBytes);

    final outputsRaw = reader.requiredList(2, field: 'outputs');
    final outputs = <CryptoHDKeyUR>[];
    for (var i = 0; i < outputsRaw.length; i++) {
      final item = outputsRaw[i];
      if (item is! CborMap) {
        throw InvalidCborURException(model: 'crypto-account', field: 'outputs[$i]', reason: 'expected CborMap, got ${item.runtimeType}');
      }
      final keyUr = UR(
        type: hdType,
        payload: Uint8List.fromList(cbor.encode(item)),
      );
      try {
        outputs.add(CryptoHDKeyUR.fromUR(ur: keyUr));
      } on InvalidCborURException catch (error) {
        throw InvalidCborURException(model: 'crypto-account', field: 'outputs[$i]', reason: error.message, cause: error);
      }
    }

    final hasXfpFormatMarker = reader.has(3);
    final xfpFormat = reader.optionalText(3, field: 'xfp_format');

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
    final fields = CompactToStringFields();

    fields.addString('masterFingerprint', masterFingerprint);
    fields.addString('xfpFormat', xfpFormat);
    fields.addRaw('outputs', '[${outputs.map((e) => e.toString()).join(',')}]');
    return fields.toString();
  }
}
