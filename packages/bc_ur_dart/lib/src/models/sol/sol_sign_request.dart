import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:bc_ur_dart/src/registry/data_item.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

enum SolSignRequestKeys {
  zero,
  uuid,
  signData,
  derivationPath,
  outputAddress,
  origin,
  signType,
  contractAddress,
  fee,
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

  @override
  RegistryType getRegistryType() {
    return ExtendedRegistryType.SOL_SIGN_REQUEST;
  }

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
  CborValue toCborValue() {
    final Map map = {};
    map[SolSignRequestKeys.uuid.index] = CborBytes(getRequestId(), tags: [RegistryType.UUID.tag]);
    map[SolSignRequestKeys.signData.index] = signData;
    CborValue keyPath = derivationPath.toCborValue();
    keyPath = cborValueSetTags(keyPath, [derivationPath.getRegistryType().tag]);
    map[SolSignRequestKeys.derivationPath.index] = keyPath;
    if (outputAddress != null) {
      map[SolSignRequestKeys.outputAddress.index] = outputAddress;
    }
    if (origin != null) {
      map[SolSignRequestKeys.origin.index] = origin;
    }
    map[SolSignRequestKeys.signType.index] = signType.index;
    if (contractAddress != null) {
      map[SolSignRequestKeys.contractAddress.index] = contractAddress;
    }
    if (fee != null) {
      map[SolSignRequestKeys.fee.index] = fee;
    }
    return CborValue(map);
  }

  static SolSignRequest fromDataItem(dynamic jsonData) {
    final map = jsonData is String
        ? jsonDecode(jsonData)
        : jsonData is Map
            ? jsonData
            : null;
    if (map == null) {
      throw "Param for fromDataItem is neither String nor Map, please check it!";
    }
    final signData = map[SolSignRequestKeys.signData.index.toString()];
    final signType = SignType.values[map[SolSignRequestKeys.signType.index.toString()]];
    final derivationPath = CryptoKeypath.fromDataItem(map[SolSignRequestKeys.derivationPath.index.toString()]);
    final outputAddress = map[SolSignRequestKeys.outputAddress.index.toString()];
    final contractAddress = map[SolSignRequestKeys.contractAddress.index.toString()];
    final uuid = map[SolSignRequestKeys.uuid.index.toString()];
    final origin = map[SolSignRequestKeys.origin.index.toString()];
    final fee = map[SolSignRequestKeys.fee.index.toString()];

    return SolSignRequest(
      uuid: uuid != null ? fromHex(uuid) : null,
      signData: fromHex(signData),
      signType: signType,
      derivationPath: derivationPath,
      outputAddress: outputAddress,
      contractAddress: contractAddress,
      origin: origin,
      fee: fee,
    );
  }

  static SolSignRequest fromCBOR(Uint8List cborPayload) {
    CborValue cborValue = cbor.decode(cborPayload);
    String jsonData = const CborJsonEncoder().convert(cborValue);
    return fromDataItem(jsonData);
  }
}
