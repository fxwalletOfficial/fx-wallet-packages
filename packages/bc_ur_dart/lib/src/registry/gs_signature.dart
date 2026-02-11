import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

enum GsSignatureKeys {
  zero,
  uuid,
  signature,
  origin,
}

class GsSignature extends RegistryItem {
  final Uint8List uuid;
  final String? origin;
  final Uint8List signature;

  GsSignature({
    required this.signature,
    required this.uuid,
    this.origin,
  });

  @override
  RegistryType getRegistryType() {
    return ExtendedRegistryType.GS_SIGNATURE;
  }

  Uint8List getRequestId() => uuid;
  Uint8List getSignature() => signature;
  String? getOrigin() => origin;

  @override
  CborValue toCborValue() {
    final Map map = {};

    map[GsSignatureKeys.uuid.index] = CborBytes(uuid, tags: [RegistryType.UUID.tag]);

    if (origin != null) {
      map[GsSignatureKeys.origin.index] = origin;
    }
    map[GsSignatureKeys.signature.index] = signature;
    return CborValue(map);
  }

  static GsSignature fromDataItem(dynamic jsonData) {
    final map = jsonData is String
        ? jsonDecode(jsonData)
        : jsonData is Map
            ? jsonData
            : null;
    if (map == null) {
      throw "Param for fromDataItem is neither String nor Map, please check it!";
    }
    final signature = map[GsSignatureKeys.signature.index.toString()];
    final uuid = map[GsSignatureKeys.uuid.index.toString()];
    final origin = map[GsSignatureKeys.origin.index.toString()];

    return GsSignature(
      signature: fromHex(signature),
      uuid: fromHex(uuid),
      origin: origin,
    );
  }

  static GsSignature fromCBOR(Uint8List cborPayload) {
    CborValue cborValue = cbor.decode(cborPayload);
    String jsonData = const CborJsonEncoder().convert(cborValue);
    return fromDataItem(jsonData);
  }
}
