import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:cbor/cbor.dart';
import 'package:uuid/uuid.dart';
import 'package:fixnum/fixnum.dart';
import 'package:bc_ur_dart/src/gen/keystone/payload.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/transaction.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/chains/bch_transaction.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/chains/btc_transaction.pb.dart';

// CBOR field keys（来自官方 SDK）
// BCH-SIGN-REQUEST: field 1 = signData(bytes), field 2 = origin(string)

class BchInput {
  final String hash; // UTXO txid hex
  final int index; // UTXO vout index
  final int value; // satoshis
  final String pubkey; // 压缩公钥 hex
  final String ownerKeyPath; // e.g. "m/44'/145'/0'/0/0"

  BchInput({
    required this.hash,
    required this.index,
    required this.value,
    required this.pubkey,
    required this.ownerKeyPath,
  });
}

class BchOutput {
  final String address;
  final int value; // satoshis
  final bool isChange;
  final String changeAddressPath; // e.g. "M/44'/145'/0'/0/0"，空字符串表示非找零

  BchOutput({
    required this.address,
    required this.value,
    this.isChange = false,
    this.changeAddressPath = '',
  });
}

class BchSignRequestUR extends UR {
  final String requestId;
  final String xfp;
  final String hdPath;
  final String? origin;

  BchSignRequestUR({
    required UR ur,
    required this.requestId,
    required this.xfp,
    required this.hdPath,
    this.origin,
  }) : super(payload: ur.payload, type: ur.type);

  factory BchSignRequestUR.fromTransaction({
    required List<BchInput> inputs,
    required List<BchOutput> outputs,
    required int fee,
    required String xfp,
    required String hdPath,
    String? requestId,
    String? origin,
    int dustThreshold = 546,
  }) {
    final id = requestId ?? const Uuid().v4();

    // 1. 构建 BchTx Protobuf
    final bchTx = _buildBchTxProto(
      inputs: inputs,
      outputs: outputs,
      fee: fee,
      dustThreshold: dustThreshold,
    );

    // 2. 构建 Payload → SignTransaction → BchTx
    final signTransaction = SignTransaction()
      ..coinCode = 'BCH'
      ..signId = id
      ..hdPath = hdPath
      ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch ~/ 1000)
      ..decimal = 8
      ..bchTx = bchTx;

    final payload = Payload()
      ..type = Payload_Type.TYPE_SIGN_TX
      ..xfp = xfp
      ..signTx = signTransaction;

    // 3. gzip 压缩
    final payloadBytes = payload.writeToBuffer();
    final compressed = GZipCodec().encode(payloadBytes);
    final signDataBytes = Uint8List.fromList(compressed);

    // 4. 封装为 BCH-SIGN-REQUEST CBOR
    // field 1: signData(bytes), field 2: origin(string, optional)
    final ur = UR.fromCBOR(
      type: RegistryType.BCH_SIGN_REQUEST.type,
      value: CborMap({
        CborSmallInt(1): CborBytes(signDataBytes),
        if (origin != null && origin.isNotEmpty) CborSmallInt(2): CborString(origin),
      }),
    );

    return BchSignRequestUR(
      ur: ur,
      requestId: id,
      xfp: xfp,
      hdPath: hdPath,
      origin: origin,
    );
  }

  factory BchSignRequestUR.fromUR({required UR ur, bool bigEndian = true}) {
    if (ur.type.toUpperCase() != RegistryType.BCH_SIGN_REQUEST.type.toUpperCase()) {
      throw Exception(URExceptionType.invalidType.toString());
    }

    final data = ur.decodeCBOR() as CborMap;

    final signDataBytes = Uint8List.fromList(
      (data[CborSmallInt(1)] as CborBytes).bytes,
    );

    // gzip 解压
    final decompressed = GZipCodec().decode(signDataBytes);

    // 解析 Payload Protobuf
    final payload = Payload.fromBuffer(decompressed);

    // 取出 signTx
    final signTx = payload.signTx;
    final signId = signTx.signId;
    final xfp = payload.xfp;
    final hdPath = signTx.hdPath;

    final originField = data[CborSmallInt(2)];
    final origin = originField != null ? (originField as CborString).toString() : null;

    return BchSignRequestUR(
      ur: ur,
      requestId: signId,
      xfp: xfp,
      hdPath: hdPath,
      origin: origin,
    );
  }

  static BchTx _buildBchTxProto({
    required List<BchInput> inputs,
    required List<BchOutput> outputs,
    required int fee,
    required int dustThreshold,
  }) {
    final bchInputs = inputs
        .map((input) => BchTx_Input(
              hash: input.hash,
              index: input.index,
              value: Int64(input.value),
              pubkey: input.pubkey,
              ownerKeyPath: input.ownerKeyPath,
            ))
        .toList();

    final bchOutputs = outputs
        .map((output) => Output(
              address: output.address,
              value: Int64(output.value),
              isChange: output.isChange,
              changeAddressPath: output.changeAddressPath,
            ))
        .toList();

    return BchTx(
      fee: Int64(fee),
      dustThreshold: dustThreshold,
      inputs: bchInputs,
      outputs: bchOutputs,
    );
  }
}
