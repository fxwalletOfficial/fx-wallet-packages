import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/gs_signature.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';

class AlphSignature extends GsSignature {
  AlphSignature({
    required super.signature,
    super.uuid,
    super.origin,
  });

  @override
  RegistryType getRegistryType() => RegistryType.ALPH_SIGNATURE;

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    final gs = super.decodeFromCbor(map) as GsSignature;
    return AlphSignature(
      signature: gs.signature,
      uuid: gs.uuid,
      origin: gs.origin,
    );
  }

  static AlphSignature fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<AlphSignature>(
      cborPayload,
      AlphSignature(signature: Uint8List(0)),
    );
  }

  static UR fromSignature({required AlphSignRequest request, required Uint8List signature}) {
    return AlphSignature(uuid: request.getRequestId(), signature: signature, origin: request.origin).toUR();
  }
}
