import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';

enum AlphSignRequestKeys {
  zero, // 0
  uuid, // 1
  signData, // 2
  derivationPath, // 3
  outputs, // 4
  origin, // 5
  dataType, // 6
}

/// 对应官方 GsplDataType
enum GsplDataType {
  zero, // 0 - 保留
  transaction, // 1 - 普通交易（对应官方示例 GsplDataType.transaction）
  message, // 2 - 消息签名
}

class AlphSignRequest extends RegistryItem {
  Uint8List? uuid;
  final Uint8List signData;
  final CryptoKeypath? derivationPath;
  final List<CryptoTxEntity>? outputs;
  final String? origin;
  final GsplDataType dataType;

  AlphSignRequest({
    this.uuid,
    required this.signData,
    this.derivationPath,
    this.outputs,
    this.origin,
    this.dataType = GsplDataType.transaction,
  });

  Uint8List getRequestId() => uuid ??= generateUuid();
  String? getDerivationPath() => derivationPath?.getPath();
  Uint8List? getSourceFingerprint() => derivationPath?.sourceFingerprint;

  @override
  RegistryType getRegistryType() => RegistryType.ALPH_SIGN_REQUEST;

  /// 含嵌套 RegistryItem（derivationPath / outputs），走 toCborValue() 路径
  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {};

    map[CborSmallInt(AlphSignRequestKeys.uuid.index)] = CborBytes(
      getRequestId(),
      tags: [RegistryType.UUID.tag],
    );
    map[CborSmallInt(AlphSignRequestKeys.signData.index)] = CborBytes(signData);
    if (derivationPath != null) {
      map[CborSmallInt(AlphSignRequestKeys.derivationPath.index)] = derivationPath!.toCborValue();
    }
    if (outputs != null && outputs!.isNotEmpty) {
      final List<CborValue> outputsData = outputs!.map((output) {
        return output.toCborValue();
      }).toList();
      map[CborSmallInt(AlphSignRequestKeys.outputs.index)] = CborList(outputsData);
    }
    if (origin != null) {
      map[CborSmallInt(AlphSignRequestKeys.origin.index)] = CborString(origin!);
    }
    map[CborSmallInt(AlphSignRequestKeys.dataType.index)] = CborSmallInt(dataType.index);

    return CborMap(map);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    // derivationPath 是 optional tagged CborMap
    CryptoKeypath? derivationPath;
    if (RegistryItem.hasKey(map, AlphSignRequestKeys.derivationPath.index)) {
      derivationPath = RegistryItem.readKeypath(map, AlphSignRequestKeys.derivationPath.index);
    }

    // outputs 是 optional CborList，每个元素是 tagged CborMap
    List<CryptoTxEntity>? outputs;
    final outputsValue = map[CborSmallInt(AlphSignRequestKeys.outputs.index)];
    if (outputsValue is CborList) {
      outputs = outputsValue.toList().whereType<CborMap>().map((e) => CryptoTxEntity().decodeFromCbor(e) as CryptoTxEntity).toList();
    }
    final dataTypeIndex = RegistryItem.readOptionalInt(map, AlphSignRequestKeys.dataType.index) ?? GsplDataType.transaction.index;

    return AlphSignRequest(
      uuid: RegistryItem.readBytes(map, AlphSignRequestKeys.uuid.index),
      signData: RegistryItem.readBytes(map, AlphSignRequestKeys.signData.index),
      derivationPath: derivationPath,
      outputs: outputs,
      origin: RegistryItem.readOptionalText(map, AlphSignRequestKeys.origin.index),
      dataType: GsplDataType.values[dataTypeIndex],
    );
  }

  static AlphSignRequest fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<AlphSignRequest>(
      cborPayload,
      AlphSignRequest(signData: Uint8List(0)),
    );
  }

  static UR generateSignRequest({
    String? uuid,
    required String signData,
    GsplDataType dataType = GsplDataType.transaction, // ← optional，有默认值
    List<Map<String, dynamic>>? outputs,
    required String path,
    required String xfp,
    String? origin,
  }) {
    return AlphSignRequest(
      uuid: uuid != null ? Uint8List.fromList(uuidParse(uuid)) : null,
      signData: fromHex(signData),
      dataType: dataType,
      outputs: outputs?.map((e) => parseTxEntity(e)).toList(),
      derivationPath: CryptoKeypath(
        components: parsePath(path).map((e) => PathComponent(index: e["index"], hardened: e["hardened"])).toList(),
        sourceFingerprint: fromHex(xfp),
      ),
      origin: origin,
    ).toUR();
  }
}
