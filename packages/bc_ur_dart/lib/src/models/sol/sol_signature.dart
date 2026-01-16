import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/gs_signature.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

class SolSignature extends GsSignature {

  SolSignature({
    required super.signature,
    super.uuid,
    super.origin,
  });

  @override
  RegistryType getRegistryType() {
    return ExtendedRegistryType.SOL_SIGNATURE;
  }

  static SolSignature fromDataItem(dynamic jsonData) {
    final map = jsonData is String ? jsonDecode(jsonData) : jsonData is Map? jsonData : null;
    if(map == null){
      throw "Param for fromDataItem is neither String nor Map, please check it!";
    }
    final signature = map[GsSignatureKeys.signature.index.toString()];
    final uuid = map[GsSignatureKeys.uuid.index.toString()];
    final origin = map[GsSignatureKeys.origin.index.toString()];

    return SolSignature(
      signature: fromHex(signature),
      uuid: uuid != null ? fromHex(uuid) : null , 
      origin: origin,
    );
  }

  static SolSignature fromCBOR(Uint8List cborPayload) {
    CborValue cborValue = cbor.decode(cborPayload);
    String jsonData = const CborJsonEncoder().convert(cborValue);
    return fromDataItem(jsonData);
  }
}
