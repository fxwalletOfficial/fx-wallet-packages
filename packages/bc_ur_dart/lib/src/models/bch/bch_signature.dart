import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/src/gen/keystone/base.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/payload.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/sign_transaction_result.pb.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:cbor/cbor.dart';

class BchSignatureUR extends UR {
  final String requestId;
  final String txId;
  final String rawTx;

  BchSignatureUR({
    required this.requestId,
    this.txId = '',
    required this.rawTx,
    super.type,
    super.payload,
  });

  factory BchSignatureUR.fromSignature({
    required String requestId,
    required String rawTx,
  }) {
    // 构建 SignTransactionResult
    final signTxResult = SignTransactionResult()
      ..signId = requestId
      ..rawTx = rawTx;

    final payload = Payload()
      ..type = Payload_Type.TYPE_SIGN_TX_RESULT
      ..signTxResult = signTxResult;

    // gzip 压缩
    final payloadBytes = payload.writeToBuffer();
    final compressed = GZipCodec().encode(payloadBytes);
    final signResultBytes = Uint8List.fromList(compressed);

    // 封装为 BCH-SIGNATURE CBOR
    final ur = UR.fromCBOR(
      type: RegistryType.KEYSTONE_SIGNATURE.type,
      value: CborMap({
        CborSmallInt(1): CborBytes(signResultBytes),
      }),
    );

    return BchSignatureUR(
      requestId: requestId,
      rawTx: rawTx,
      type: ur.type,
      payload: ur.payload,
    );
  }

  factory BchSignatureUR.fromUR({required UR ur, bool bigEndian = true}) {
    const model = 'bch-signature';
    if (ur.type.toUpperCase() != RegistryType.KEYSTONE_SIGNATURE.type.toUpperCase()) {
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

    // field 1: signResult（gzip 压缩的 Protobuf bytes）
    final signResultValue = decoded[CborSmallInt(1)];
    if (signResultValue is! CborBytes) {
      throw InvalidCborURException(model: model, field: 'sign_result', reason: 'expected CborBytes, got ${signResultValue.runtimeType}');
    }
    final signResultBytes = Uint8List.fromList(signResultValue.bytes);

    final String requestId;
    final String rawTx;
    try {
      // gzip 解压 + 解析 Base envelope + 取出 SignTxResult
      final decompressed = GZipCodec().decode(signResultBytes);
      final base = Base.fromBuffer(decompressed);
      final payload = base.payloadData;
      final signTxResult = payload.signTxResult;
      requestId = signTxResult.signId;
      rawTx = signTxResult.rawTx;
    } on Object catch (error) {
      throw InvalidCborURException(model: model, field: 'sign_result', reason: 'invalid gzip/protobuf payload', cause: error);
    }

    return BchSignatureUR(
      requestId: requestId,
      rawTx: rawTx,
      type: ur.type,
      payload: ur.payload,
    );
  }
}
