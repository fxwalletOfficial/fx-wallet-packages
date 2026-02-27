import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/gs_signature.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

class CosmosSignature extends GsSignature {
  CosmosSignature({
    required super.uuid,
    required super.signature,
    super.origin,
  });

  @override
  RegistryType getRegistryType() => ExtendedRegistryType.COSMOS_SIGNATURE;

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    final gs = super.decodeFromCbor(map) as GsSignature;
    return CosmosSignature(
      uuid: gs.uuid,
      signature: gs.signature,
      origin: gs.origin,
    );
  }

  static CosmosSignature fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<CosmosSignature>(
      cborPayload,
      CosmosSignature(uuid: Uint8List(0), signature: Uint8List(0)),
    );
  }

  /// 从签名请求 + 签名结果构建 UR
  static UR fromSignature({required CosmosSignRequest request, required Uint8List signature}) {
    return CosmosSignature(uuid: request.getRequestId(), signature: signature, origin: request.getOrigin()).toUR();
  }
}
