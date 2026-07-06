import 'dart:io';
import 'dart:typed_data';

import 'package:bc_ur_dart/src/gen/keystone/base.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/chains/bch_transaction.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/chains/btc_transaction.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/payload.pb.dart';
import 'package:bc_ur_dart/src/gen/keystone/transaction.pb.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:cbor/cbor.dart';
import 'package:fixnum/fixnum.dart';
import 'package:uuid/uuid.dart';

// CBOR field keys（来自官方 SDK）
// BCH-SIGN-REQUEST: field 1 = signData(bytes), field 2 = origin(string)

class BchInput {
  final String hash; // UTXO txid hex
  final int? index; // UTXO vout index
  final int value; // satoshis
  final String pubkey; // 压缩公钥 hex
  final String ownerKeyPath; // e.g. "m/44'/145'/0'/0/0"

  BchInput({
    required this.hash,
    this.index,
    required this.value,
    required this.pubkey,
    required this.ownerKeyPath,
  });
}

class BchOutput {
  final String address;
  final int value; // satoshis
  final bool? isChange;
  final String? changeAddressPath; // e.g. "M/44'/145'/0'/0/0"，空字符串表示非找零

  BchOutput({
    required this.address,
    required this.value,
    this.isChange,
    this.changeAddressPath,
  });
}

class BchSignRequestUR extends UR {
  /// Keystone 交易所属链的资产代码。
  ///
  /// Keystone 的 BCH/DOGE 等 UTXO 交易共用 [BchTx] 结构承载输入输出，
  /// 设备端通过 [coinCode] 区分最终签名链，默认保持历史 BCH 行为。
  final String coinCode;
  final String requestId;
  final String xfp;
  final String hdPath;
  final String? origin;

  BchSignRequestUR({
    required UR ur,
    this.coinCode = 'BCH',
    required this.requestId,
    required this.xfp,
    required this.hdPath,
    this.origin,
  }) : super(payload: ur.payload, type: ur.type);

  /// 构建 Keystone UTXO 签名请求。
  ///
  /// [coinCode] 默认是 `BCH`，Doge 等同源 UTXO 链可以传入自己的大写资产代码。
  /// 当前 Keystone UTXO payload 固定使用 8 位小数，调用方只应传入同样采用
  /// 8-decimal satoshi 单位的 coin code。
  /// Payload 仍使用 Keystone 现有的 [BchTx] oneof 字段，避免创建设备端不认识的新
  /// registry type。
  factory BchSignRequestUR.fromTransaction({
    required List<BchInput> inputs,
    required List<BchOutput> outputs,
    required int fee,
    required String xfp,
    required String hdPath,
    String? requestId,
    String? origin,
    int dustThreshold = 546,
    String coinCode = 'BCH',
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
      ..coinCode = coinCode
      ..signId = id
      ..hdPath = hdPath
      ..timestamp = Int64(DateTime.now().millisecondsSinceEpoch)
      ..decimal = 8
      ..bchTx = bchTx;

    final payload = Payload()
      ..type = Payload_Type.TYPE_SIGN_TX
      ..xfp = xfp
      ..signTx = signTransaction;

    // 外层包 Base
    final base = Base()
      ..version = 2
      ..description = 'QrCode Protocol'
      ..payloadData = payload;

    // 3. gzip 压缩 Base
    final compressed = GZipCodec().encode(base.writeToBuffer());
    final signDataBytes = Uint8List.fromList(compressed);

    // 4. 封装为 BCH-SIGN-REQUEST CBOR
    // field 1: signData(bytes), field 2: origin(string, optional)
    final ur = UR.fromCBOR(
      type: RegistryType.KEYSTONE_SIGN_REQUEST.type,
      value: CborMap({
        CborSmallInt(1): CborBytes(signDataBytes),
        if (origin != null && origin.isNotEmpty) CborSmallInt(2): CborString(origin),
      }),
    );

    return BchSignRequestUR(
      ur: ur,
      coinCode: coinCode,
      requestId: id,
      xfp: xfp,
      hdPath: hdPath,
      origin: origin,
    );
  }

  factory BchSignRequestUR.fromUR({required UR ur, bool bigEndian = true}) {
    const model = 'bch-sign-request';
    if (ur.type.toUpperCase() != RegistryType.KEYSTONE_SIGN_REQUEST.type.toUpperCase()) {
      throw InvalidTypeURException(expected: RegistryType.KEYSTONE_SIGN_REQUEST.type, actual: ur.type);
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
    final data = decoded;

    final signDataValue = data[CborSmallInt(1)];
    if (signDataValue is! CborBytes) {
      throw InvalidCborURException(model: model, field: 'sign_data', reason: 'expected CborBytes, got ${signDataValue.runtimeType}');
    }
    final signDataBytes = Uint8List.fromList(signDataValue.bytes);

    final String signId;
    final String coinCode;
    final String xfp;
    final String hdPath;
    try {
      // gzip 解压 + 解析 Base Protobuf
      final decompressed = GZipCodec().decode(signDataBytes);
      final base = Base.fromBuffer(decompressed);
      final payload = base.payloadData;
      final signTx = payload.signTx;
      signId = signTx.signId;
      coinCode = signTx.coinCode;
      xfp = payload.xfp;
      hdPath = signTx.hdPath;
    } on Object catch (error) {
      throw InvalidCborURException(model: model, field: 'sign_data', reason: 'invalid gzip/protobuf payload', cause: error);
    }

    final originField = data[CborSmallInt(2)];
    if (originField != null && originField is! CborString) {
      throw InvalidCborURException(model: model, field: 'origin', reason: 'expected CborString, got ${originField.runtimeType}');
    }
    final origin = originField != null ? (originField as CborString).toString() : null;

    return BchSignRequestUR(
      ur: ur,
      coinCode: coinCode,
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
    final bchInputs = inputs.map((input) {
      final protoInput = BchTx_Input(
        hash: input.hash,
        value: Int64(input.value),
        pubkey: input.pubkey,
        ownerKeyPath: input.ownerKeyPath,
      );
      // 只有 index 不为 null 时才设置
      if (input.index != null) {
        protoInput.index = input.index!;
      }
      return protoInput;
    }).toList();

    final bchOutputs = outputs.map((output) {
      final protoOutput = Output(
        address: output.address,
        value: Int64(output.value),
      );
      // 只有 isChange 不为 null 且为 true 时才设置
      if (output.isChange != null && output.isChange!) {
        protoOutput.isChange = output.isChange!;
      }
      // 只有 changeAddressPath 不为 null 且非空时才设置
      if (output.changeAddressPath != null && output.changeAddressPath!.isNotEmpty) {
        protoOutput.changeAddressPath = output.changeAddressPath!;
      }
      return protoOutput;
    }).toList();

    return BchTx(
      fee: Int64(fee),
      dustThreshold: dustThreshold,
      inputs: bchInputs,
      outputs: bchOutputs,
    );
  }
}
