import 'dart:convert';
import 'dart:typed_data';
import 'package:protobuf/protobuf.dart';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/data_item.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';

enum CosmosSignRequestKeys { zero, uuid, signData, derivationPath, chain, origin, fee }

class CosmosSignRequest extends RegistryItem {
  Uint8List? uuid;
  final Uint8List signData;
  final String? origin;
  final String chain;
  final CryptoKeypath derivationPath;
  final int? fee;

  CosmosSignRequest({
    this.uuid,
    required this.signData,
    required this.chain,
    required this.derivationPath,
    this.origin,
    this.fee,
  });

  @override
  RegistryType getRegistryType() {
    return ExtendedRegistryType.COSMOS_SIGN_REQUEST;
  }

  Uint8List getRequestId() => uuid ??= generateUuid();
  Uint8List getSignData() => signData;
  String? getOrigin() => origin;
  String getChain() => chain;
  String? getDerivationPath() => derivationPath.getPath();
  Uint8List? getSourceFingerprint() => derivationPath.sourceFingerprint;
  int? getFee() => fee;

  /// 转换为 CBOR 值
  @override
  CborValue toCborValue() {
    final Map map = {};
    // UUID
    map[CosmosSignRequestKeys.uuid.index] = CborBytes(getRequestId(), tags: [RegistryType.UUID.tag]);
    // 签名数据
    map[CosmosSignRequestKeys.signData.index] = CborBytes(signData);
    // 派生路径（带标签）
    CborValue keyPath = derivationPath.toCborValue();
    keyPath = cborValueSetTags(keyPath, [derivationPath.getRegistryType().tag]);
    map[CosmosSignRequestKeys.derivationPath.index] = keyPath;

    // 链标识
    map[CosmosSignRequestKeys.chain.index] = chain;

    // 可选字段
    if (origin != null) {
      map[CosmosSignRequestKeys.origin.index] = origin;
    }
    if (fee != null) {
      map[CosmosSignRequestKeys.fee.index] = fee;
    }
    return CborValue(map);
  }

  static CosmosSignRequest fromDataItem(dynamic jsonData) {
    final map = jsonData is String
        ? jsonDecode(jsonData)
        : jsonData is Map
            ? jsonData
            : null;
    if (map == null) {
      throw "Param for fromDataItem is neither String nor Map, please check it!";
    }
    final signData = map[CosmosSignRequestKeys.signData.index.toString()];
    final uuid = map[CosmosSignRequestKeys.uuid.index.toString()];
    final chain = map[CosmosSignRequestKeys.chain.index.toString()];
    final origin = map[CosmosSignRequestKeys.origin.index.toString()];
    final derivationPath = CryptoKeypath.fromDataItem(map[CosmosSignRequestKeys.derivationPath.index.toString()]);
    final fee = map[CosmosSignRequestKeys.fee.index.toString()];

    return CosmosSignRequest(
      uuid: fromHex(uuid),
      signData: fromHex(signData),
      derivationPath: derivationPath,
      chain: chain,
      origin: origin,
      fee: fee,
    );
  }

  /// 签名请求UR 解析
  static CosmosSignRequest fromCBOR(Uint8List cborPayload) {
    CborValue cborValue = cbor.decode(cborPayload);
    String jsonData = const CborJsonEncoder().convert(cborValue);
    return fromDataItem(jsonData);
  }

  /// 签名请求UR生成
  static UR generateSignRequest({
    String? uuid,
    required String signData,
    required String path,
    required String chain,
    required String xfp,
    String? origin,
    int? fee,
    List<GeneratedMessage>? msgs,
  }) {
    return CosmosSignRequest(
      uuid: uuid != null ? Uint8List.fromList(uuidParse(uuid)) : null,
      signData: fromHex(signData),
      derivationPath: CryptoKeypath(
        components: parsePath(path).map((e) => PathComponent(index: e["index"], hardened: e["hardened"])).toList(),
        sourceFingerprint: fromHex(xfp),
      ),
      chain: chain,
      origin: origin,
      fee: fee,
    ).toUR();
  }
}
