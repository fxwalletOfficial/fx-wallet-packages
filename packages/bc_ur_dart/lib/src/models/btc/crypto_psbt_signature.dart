import 'dart:typed_data';

import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
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
    final expectedType = RegistryType.CRYPTO_PSBT.type;
    if (ur.type.toUpperCase() != expectedType.toUpperCase()) {
      throw InvalidTypeURException(expected: expectedType, actual: ur.type);
    }

    final decoded = ur.decodeCBOR();
    if (decoded is! CborBytes) {
      throw InvalidCborURException(model: 'crypto-psbt', reason: 'expected top-level CborBytes, got ${decoded.runtimeType}');
    }
    final signature = Uint8List.fromList(decoded.bytes);

    return BtcSignature(
      signature: signature,
      type: ur.type,
      payload: ur.payload,
    );
  }
}
