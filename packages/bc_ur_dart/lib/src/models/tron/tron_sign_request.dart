import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:bc_ur_dart/src/registry/crypto_key_path.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';

enum TronSignRequestKeys {
  zero, // 0 
  uuid, // 1
  signData, // 2
  derivationPath, // 3
  fee, // 4
  origin, // 5
}

class TronSignRequest extends RegistryItem {
  Uint8List? uuid;
  final Uint8List signData;
  final CryptoKeypath derivationPath;
  final int? fee;
  final String? origin;

  TronSignRequest({
    this.uuid,
    required this.signData,
    required this.derivationPath,
    this.fee,
    this.origin,
  });

  Uint8List getRequestId() => uuid ??= generateUuid();
  Uint8List getSignData() => signData;
  String? getDerivationPath() => derivationPath.getPath();
  Uint8List? getSourceFingerprint() => derivationPath.sourceFingerprint;
  int? getFee() => fee;
  String? getOrigin() => origin;

  @override
  RegistryType getRegistryType() => ExtendedRegistryType.TRON_SIGN_REQUEST;

  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {};


    map[CborSmallInt(TronSignRequestKeys.uuid.index)] = cborBytes(
      getRequestId(),
      tags: [RegistryType.UUID.tag],
    );
    map[CborSmallInt(TronSignRequestKeys.signData.index)] = cborBytes(signData);
    map[CborSmallInt(TronSignRequestKeys.derivationPath.index)] = derivationPath.toCborValue();
    if (fee != null) {
      map[CborSmallInt(TronSignRequestKeys.fee.index)] = cborInt(fee!);
    }
    if (origin != null) {
      map[CborSmallInt(TronSignRequestKeys.origin.index)] = CborString(origin!);
    }

    return CborMap(map);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {

    return TronSignRequest(
      uuid: RegistryItem.readBytes(map, TronSignRequestKeys.uuid.index),
      signData: RegistryItem.readBytes(map, TronSignRequestKeys.signData.index),
      derivationPath: RegistryItem.readKeypath(map, SolSignRequestKeys.derivationPath.index),
      fee: RegistryItem.readOptionalInt(map, TronSignRequestKeys.fee.index),
      origin: RegistryItem.readOptionalText(map, TronSignRequestKeys.origin.index),
    );
  }

  static TronSignRequest fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<TronSignRequest>(
      cborPayload,
      TronSignRequest(
        signData: Uint8List(0),
        derivationPath: CryptoKeypath(),
      ),
    );
  }

  static UR generateSignRequest({
    String? uuid,
    required String signData,
    required String path,
    required String xfp,
    int? fee,
    String? origin,
  }) {
    return TronSignRequest(
      uuid: uuid != null ? Uint8List.fromList(uuidParse(uuid)) : null,
      signData: fromHex(signData),
      derivationPath: CryptoKeypath(
        components: parsePath(path).map((e) => PathComponent(index: e["index"], hardened: e["hardened"])).toList(),
        sourceFingerprint: fromHex(xfp),
      ),
      fee: fee,
      origin: origin,
    ).toUR();
  }
}
