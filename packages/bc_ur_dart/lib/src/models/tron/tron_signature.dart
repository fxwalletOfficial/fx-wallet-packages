import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/gs_signature.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

enum TronSignatureKeys {
  zero, // 0
  uuid, // 1
  signature, // 2
  origin, // 3
}

class TronSignature extends GsSignature {
  TronSignature({
    super.uuid, // ← optional，Tron 允许不传
    required super.signature,
    super.origin,
  });

  @override
  RegistryType getRegistryType() => ExtendedRegistryType.TRON_SIGNATURE;

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    final gs = super.decodeFromCbor(map) as GsSignature;
    return TronSignature(
      uuid: gs.uuid,
      signature: gs.signature,
      origin: gs.origin,
    );
  }

  static TronSignature fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<TronSignature>(
      cborPayload,
      TronSignature(signature: Uint8List(0)),
    );
  }

  /// 从签名请求 + 签名结果构建 UR
  static UR fromSignature({required TronSignRequest request, required Uint8List signature}) {
    return TronSignature(uuid: request.getRequestId(), signature: signature, origin: request.getOrigin()).toUR();
  }
}
