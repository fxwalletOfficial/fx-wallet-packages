import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/gs_signature.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

class SolSignature extends GsSignature {
  SolSignature({
    required super.uuid,
    required super.signature,
    super.origin,
  });

  @override
  RegistryType getRegistryType() => ExtendedRegistryType.SOL_SIGNATURE;

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    // 复用父类解码逻辑，再包装成 SolSignature
    final gs = super.decodeFromCbor(map) as GsSignature;
    return SolSignature(
      uuid: gs.uuid,
      signature: gs.signature,
      origin: gs.origin,
    );
  }

  static SolSignature fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<SolSignature>(
      cborPayload,
      SolSignature(uuid: Uint8List(0), signature: Uint8List(0)),
    );
  }

  /// 从签名请求 + 签名结果构建 UR，用于钱包返回签名给 dApp
  static UR fromSignature({required SolSignRequest request, required Uint8List signature}) {
    return SolSignature(uuid: request.getRequestId(), signature: signature, origin: request.getOrigin()).toUR();
  }
}
