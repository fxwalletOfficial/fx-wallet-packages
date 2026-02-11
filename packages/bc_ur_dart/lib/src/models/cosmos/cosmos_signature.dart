import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

enum CosmosSignatureKeys {
  zero,
  uuid,
  signature,
  origin,
}

class CosmosSignature extends RegistryItem {
  final Uint8List uuid;
  final String? origin;
  final Uint8List signature;

  CosmosSignature({required this.signature, required this.uuid, this.origin});

  @override
  RegistryType getRegistryType() {
    return ExtendedRegistryType.COSMOS_SIGNATURE;
  }

  Uint8List getRequestId() => uuid;
  Uint8List getSignature() => signature;
  String? getOrigin() => origin;

  @override
  CborValue toCborValue() {
    final Map map = {};
    map[CosmosSignatureKeys.uuid.index] = CborBytes(uuid, tags: [RegistryType.UUID.tag]);
    if (origin != null) {
      map[CosmosSignatureKeys.origin.index] = origin;
    }
    map[CosmosSignatureKeys.signature.index] = signature;
    return CborValue(map);
  }

  static CosmosSignature fromDataItem(dynamic jsonData) {
    final map = jsonData is String
        ? jsonDecode(jsonData)
        : jsonData is Map
            ? jsonData
            : null;
    if (map == null) {
      throw "Param for fromDataItem is neither String nor Map, please check it!";
    }
    final signature = map[CosmosSignatureKeys.signature.index.toString()];
    final uuid = map[CosmosSignatureKeys.uuid.index.toString()];
    final origin = map[CosmosSignatureKeys.origin.index.toString()];

    return CosmosSignature(
      signature: fromHex(signature),
      uuid: fromHex(uuid),
      origin: origin,
    );
  }

  // 从UR解析数据
  static CosmosSignature fromCBOR(Uint8List cborPayload) {
    CborValue cborValue = cbor.decode(cborPayload);
    String jsonData = const CborJsonEncoder().convert(cborValue);
    return fromDataItem(jsonData);
  }

  // 生成签名UR
  static UR fromSignature({required CosmosSignRequest request, required Uint8List signature}) {
    return CosmosSignature(uuid: request.getRequestId(), signature: signature, origin: request.getOrigin()).toUR();
  }
}
