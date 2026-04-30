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
    if (ur.type.toUpperCase() != RegistryType.KEYSTONE_SIGNATURE.type.toUpperCase()) {
      throw Exception(URExceptionType.invalidType.toString());
    }

    final data = ur.decodeCBOR() as CborMap;

    // field 1: signResult（gzip 压缩的 Protobuf bytes）
    final signResultBytes = Uint8List.fromList(
      (data[CborSmallInt(1)] as CborBytes).bytes,
    );

    // 1. gzip 解压
    final decompressed = GZipCodec().decode(signResultBytes);

    // 2. 解析 Base envelope
    final base = Base.fromBuffer(decompressed);
    final payload = base.payloadData;

    // 3. 取出 SignTxResult
    final signTxResult = payload.signTxResult;
    final requestId = signTxResult.signId;
    final rawTx = signTxResult.rawTx;

    return BchSignatureUR(
      requestId: requestId,
      rawTx: rawTx,
      type: ur.type,
      payload: ur.payload,
    );
  }
}
