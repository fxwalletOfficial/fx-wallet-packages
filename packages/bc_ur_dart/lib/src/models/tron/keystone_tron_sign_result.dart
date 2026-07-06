import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/src/gen/keystone/base.pb.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:cbor/cbor.dart';

class KeystoneTronSignResult {
  final String requestId;
  final String txId;
  final String rawTx;

  const KeystoneTronSignResult({
    required this.requestId,
    required this.txId,
    required this.rawTx,
  });

  static KeystoneTronSignResult fromUR(UR ur) {
    const model = 'keystone-tron-sign-result';
    if (ur.type.toLowerCase() != RegistryType.KEYSTONE_SIGNATURE.type) {
      throw InvalidTypeURException(expected: RegistryType.KEYSTONE_SIGNATURE.type, actual: ur.type);
    }

    final CborValue decoded;
    try {
      decoded = ur.decodeCBOR();
    } on Object catch (error) {
      throw InvalidCborURException(model: model, reason: 'invalid CBOR payload', cause: error);
    }
    if (decoded is! CborMap) {
      throw InvalidCborURException(model: model, reason: 'expected top-level CborMap, got ${decoded.runtimeType}');
    }

    final signResultValue = decoded[CborSmallInt(1)];
    if (signResultValue is! CborBytes) {
      throw InvalidCborURException(model: model, field: 'sign_result', reason: 'expected CborBytes, got ${signResultValue.runtimeType}');
    }

    final String requestId;
    final String txId;
    final String rawTx;
    try {
      final base = Base.fromBuffer(GZipCodec().decode(Uint8List.fromList(signResultValue.bytes)));
      final result = base.payloadData.signTxResult;
      requestId = result.signId;
      txId = result.txId;
      rawTx = result.rawTx;
    } on Object catch (error) {
      throw InvalidCborURException(model: model, field: 'sign_result', reason: 'invalid gzip/protobuf payload', cause: error);
    }

    return KeystoneTronSignResult(
      requestId: requestId,
      txId: txId,
      rawTx: rawTx,
    );
  }
}
