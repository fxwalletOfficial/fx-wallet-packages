import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

enum SolSignRequestKeys {
  zero, // 0 
  uuid, // 1
  signData, // 2
  derivationPath, // 3
  outputAddress, // 4
  origin, // 5
  signType, // 6
  contractAddress, // 7
  fee, // 8
}

enum SignType {
  zero,
  transaction,
  message,
}

class SolSignRequest extends RegistryItem {
  Uint8List? uuid;
  final Uint8List signData;
  final SignType signType;
  final CryptoKeypath derivationPath;
  final String? outputAddress;
  final String? contractAddress;
  final String? origin;
  final int? fee;

  SolSignRequest({
    this.uuid,
    required this.signData,
    required this.signType,
    required this.derivationPath,
    this.outputAddress,
    this.contractAddress,
    this.origin,
    this.fee,
  });

  Uint8List getRequestId() => uuid ??= generateUuid();
  Uint8List getSignData() => signData;
  SignType getSignType() => signType;
  String? getDerivationPath() => derivationPath.getPath();
  Uint8List? getSourceFingerprint() => derivationPath.sourceFingerprint;
  String? getOutputAddress() => outputAddress;
  String? getContractAddress() => contractAddress;
  String? getOrigin() => origin;
  int? getFee() => fee;

  @override
  RegistryType getRegistryType() => ExtendedRegistryType.SOL_SIGN_REQUEST;

  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {};

    map[CborSmallInt(SolSignRequestKeys.uuid.index)] = cborBytes(
      getRequestId(),
      tags: [RegistryType.UUID.tag],
    );
    map[CborSmallInt(SolSignRequestKeys.signData.index)] = cborBytes(signData);
    map[CborSmallInt(SolSignRequestKeys.derivationPath.index)] = derivationPath.toCborValue();
    map[CborSmallInt(SolSignRequestKeys.signType.index)] = cborInt(signType.index);
    if (outputAddress != null) {
      map[CborSmallInt(SolSignRequestKeys.outputAddress.index)] = CborString(outputAddress!);
    }
    if (origin != null) {
      map[CborSmallInt(SolSignRequestKeys.origin.index)] = CborString(origin!);
    }
    if (contractAddress != null) {
      map[CborSmallInt(SolSignRequestKeys.contractAddress.index)] = CborString(contractAddress!);
    }
    if (fee != null) {
      map[CborSmallInt(SolSignRequestKeys.fee.index)] = cborInt(fee!);
    }

    return CborMap(map);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    // signType 枚举
    final signTypeIndex = RegistryItem.readInt(
      map,
      SolSignRequestKeys.signType.index,
    );

    return SolSignRequest(
      uuid: RegistryItem.readBytes(map, SolSignRequestKeys.uuid.index),
      signData: RegistryItem.readBytes(map, SolSignRequestKeys.signData.index),
      signType: SignType.values[signTypeIndex],
      derivationPath: RegistryItem.readKeypath(map, SolSignRequestKeys.derivationPath.index),
      outputAddress: RegistryItem.readOptionalText(map, SolSignRequestKeys.outputAddress.index),
      origin: RegistryItem.readOptionalText(map, SolSignRequestKeys.origin.index),
      contractAddress: RegistryItem.readOptionalText(map, SolSignRequestKeys.contractAddress.index),
      fee: RegistryItem.readOptionalInt(map, SolSignRequestKeys.fee.index),
    );
  }

  static SolSignRequest fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<SolSignRequest>(
      cborPayload,
      SolSignRequest(signData: Uint8List(0), signType: SignType.transaction, derivationPath: CryptoKeypath()),
    );
  }

  static UR generateSignRequest({
    String? uuid,
    required String signData,
    required SignType signType,
    required String path,
    required String xfp,
    String? outputAddress,
    String? contractAddress,
    String? origin,
    int? fee,
  }) {
    return SolSignRequest(
      uuid: uuid != null ? Uint8List.fromList(uuidParse(uuid)) : null,
      signData: fromHex(signData),
      signType: signType,
      derivationPath: CryptoKeypath(
        components: parsePath(path).map((e) => PathComponent(index: e["index"], hardened: e["hardened"])).toList(),
        sourceFingerprint: fromHex(xfp),
      ),
      outputAddress: outputAddress,
      contractAddress: contractAddress,
      origin: origin,
      fee: fee,
    ).toUR();
  }
}
