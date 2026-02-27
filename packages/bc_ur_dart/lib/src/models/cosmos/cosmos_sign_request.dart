import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

enum CosmosSignRequestKeys {
  zero, // 0 
  uuid, // 1
  signData, // 2
  derivationPath, // 3
  chain, // 4
  origin, // 5
  fee, // 6
}

class CosmosSignRequest extends RegistryItem {
  Uint8List? uuid;
  final Uint8List signData;
  final String chain;
  final CryptoKeypath derivationPath;
  final String? origin;
  final int? fee;

  CosmosSignRequest({
    this.uuid,
    required this.signData,
    required this.chain,
    required this.derivationPath,
    this.origin,
    this.fee,
  });

  Uint8List getRequestId() => uuid ??= generateUuid();
  Uint8List getSignData() => signData;
  String getChain() => chain;
  String? getDerivationPath() => derivationPath.getPath();
  Uint8List? getSourceFingerprint() => derivationPath.sourceFingerprint;
  String? getOrigin() => origin;
  int? getFee() => fee;

  @override
  RegistryType getRegistryType() => ExtendedRegistryType.COSMOS_SIGN_REQUEST;


  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {};

    map[CborSmallInt(CosmosSignRequestKeys.uuid.index)] = CborBytes(
      getRequestId(),
      tags: [RegistryType.UUID.tag],
    );
    map[CborSmallInt(CosmosSignRequestKeys.signData.index)] = CborBytes(signData);
    map[CborSmallInt(CosmosSignRequestKeys.derivationPath.index)] = derivationPath.toCborValue();
    map[CborSmallInt(CosmosSignRequestKeys.chain.index)] = CborString(chain);
    if (origin != null) {
      map[CborSmallInt(CosmosSignRequestKeys.origin.index)] = CborString(origin!);
    }
    if (fee != null) {
      map[CborSmallInt(CosmosSignRequestKeys.fee.index)] = CborInt(BigInt.from(fee!));
    }

    return CborMap(map);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {

    return CosmosSignRequest(
      uuid: RegistryItem.readBytes(map, CosmosSignRequestKeys.uuid.index),
      signData: RegistryItem.readBytes(map, CosmosSignRequestKeys.signData.index),
      chain: RegistryItem.readOptionalText(map, CosmosSignRequestKeys.chain.index) ?? '',
      derivationPath: RegistryItem.readKeypath(map, CosmosSignRequestKeys.derivationPath.index),
      origin: RegistryItem.readOptionalText(map, CosmosSignRequestKeys.origin.index),
      fee: RegistryItem.readOptionalInt(map, CosmosSignRequestKeys.fee.index),
    );
  }

  static CosmosSignRequest fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<CosmosSignRequest>(
      cborPayload,
      CosmosSignRequest(signData: Uint8List(0), chain: '', derivationPath: CryptoKeypath()),
    );
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
