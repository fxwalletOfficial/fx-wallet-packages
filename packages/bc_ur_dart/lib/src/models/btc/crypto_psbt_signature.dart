import 'dart:typed_data';

import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:cbor/cbor.dart';

class BtcSignature extends UR {
  final Uint8List? uuid;
  final Uint8List signature; // 完整的已签名 PSBT bytes

  BtcSignature({
    this.uuid,
    required this.signature,
    super.type,
    super.payload,
  });

  factory BtcSignature.fromUR({required UR ur}) {
    if (ur.type.toUpperCase() != RegistryType.CRYPTO_PSBT.type.toUpperCase()) {
      throw Exception('Invalid type: ${ur.type}');
    }

    final psbtBytes = ur.decodeCBOR() as CborBytes;
    final signature = Uint8List.fromList(psbtBytes.bytes);

    return BtcSignature(
      signature: signature,
      type: ur.type,
      payload: ur.payload,
    );
  }
}
