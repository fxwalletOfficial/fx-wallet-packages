import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/gs_signature.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

class SolSignature extends GsSignature {
  SolSignature({
    required super.signature,
    required super.uuid,
    super.origin,
  });

  @override
  RegistryType getRegistryType() {
    return ExtendedRegistryType.SOL_SIGNATURE;
  }

  static SolSignature fromDataItem(dynamic jsonData) {
    final gs = GsSignature.fromDataItem(jsonData);
    return SolSignature(
      signature: gs.signature,
      uuid: gs.uuid,
      origin: gs.origin,
    );
  }

  static SolSignature fromCBOR(Uint8List cborPayload) {
    CborValue cborValue = cbor.decode(cborPayload);
    String jsonData = const CborJsonEncoder().convert(cborValue);
    return fromDataItem(jsonData);
  }

  static UR fromSignature({required SolSignRequest request, required Uint8List signature}) {
    return SolSignature(uuid: request.getRequestId(), signature: signature, origin: request.getOrigin()).toUR();
  }
}
