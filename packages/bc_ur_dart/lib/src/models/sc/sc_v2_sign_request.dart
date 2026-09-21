import 'dart:typed_data';

import 'package:bc_ur_dart/src/models/sc/sc_v2_codec.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:cbor/cbor.dart';

enum ScV2Profile {
  sc(0),
  scp(1);

  const ScV2Profile(this.wireValue);

  final int wireValue;
}

final class ScV2SignRequest extends RegistryItem {
  static const int supportedProtocolVersion = 2;
  static const int maxSemanticTransactionBytes = 32 * 1024;
  static const int maxCborPayloadBytes = maxSemanticTransactionBytes + 70;

  static const int _protocolVersionKey = 1;
  static const int _requestIdKey = 2;
  static const int _profileKey = 3;
  static const int _masterFingerprintKey = 4;
  static const int _signerCoreAddressKey = 5;
  static const int _semanticTransactionKey = 6;
  static const List<int> _keys = <int>[_protocolVersionKey, _requestIdKey, _profileKey, _masterFingerprintKey, _signerCoreAddressKey, _semanticTransactionKey];

  final int protocolVersion;
  final Uint8List requestId;
  final ScV2Profile profile;
  final Uint8List masterFingerprint;
  final Uint8List signerCoreAddress;
  final Uint8List semanticTransaction;

  ScV2SignRequest({
    this.protocolVersion = supportedProtocolVersion,
    required Uint8List requestId,
    required this.profile,
    required Uint8List masterFingerprint,
    required Uint8List signerCoreAddress,
    required Uint8List semanticTransaction,
  })  : requestId = Uint8List.fromList(requestId),
        masterFingerprint = Uint8List.fromList(masterFingerprint),
        signerCoreAddress = Uint8List.fromList(signerCoreAddress),
        semanticTransaction = Uint8List.fromList(semanticTransaction) {
    _validate();
  }

  String get requestIdString => uuidStringify(requestId);

  @override
  RegistryType getRegistryType() => RegistryType.SC_V2_SIGN_REQUEST;

  @override
  CborValue toCborValue() {
    _validate();
    return CborMap(<CborValue, CborValue>{
      const CborSmallInt(_protocolVersionKey): const CborSmallInt(supportedProtocolVersion),
      const CborSmallInt(_requestIdKey): CborBytes(requestId, tags: const <int>[37]),
      const CborSmallInt(_profileKey): CborSmallInt(profile.wireValue),
      const CborSmallInt(_masterFingerprintKey): CborBytes(masterFingerprint),
      const CborSmallInt(_signerCoreAddressKey): CborBytes(signerCoreAddress),
      const CborSmallInt(_semanticTransactionKey): CborBytes(semanticTransaction),
    }, type: CborLengthType.definite);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    return fromCBOR(Uint8List.fromList(cbor.encode(map)));
  }

  static ScV2SignRequest fromCBOR(Uint8List cborPayload) {
    const model = 'sc-v2-sign-request';
    final map = ScV2Codec.decodeMap(cborPayload, model: model, keys: _keys, maxPayloadBytes: maxCborPayloadBytes);
    final version = ScV2Codec.readInt(map, _protocolVersionKey, model: model, field: 'protocolVersion');
    if (version != supportedProtocolVersion) {
      throw InvalidCborURException(model: model, field: 'protocolVersion', reason: 'unsupported version $version');
    }

    final profileIndex = ScV2Codec.readInt(map, _profileKey, model: model, field: 'profile');
    final profile = switch (profileIndex) {
      0 => ScV2Profile.sc,
      1 => ScV2Profile.scp,
      _ => null,
    };
    if (profile == null) {
      throw InvalidCborURException(model: model, field: 'profile', reason: 'unsupported profile $profileIndex');
    }

    return ScV2SignRequest(
      protocolVersion: version,
      requestId: ScV2Codec.readBytes(map, _requestIdKey, model: model, field: 'requestId', length: 16, tags: const <int>[37]),
      profile: profile,
      masterFingerprint: ScV2Codec.readBytes(map, _masterFingerprintKey, model: model, field: 'masterFingerprint', length: 4),
      signerCoreAddress: ScV2Codec.readBytes(map, _signerCoreAddressKey, model: model, field: 'signerCoreAddress', length: 32),
      semanticTransaction: ScV2Codec.readBytes(map, _semanticTransactionKey, model: model, field: 'semanticTransaction', maxLength: maxSemanticTransactionBytes),
    );
  }

  static ScV2SignRequest fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.SC_V2_SIGN_REQUEST.type) {
      throw InvalidTypeURException(expected: RegistryType.SC_V2_SIGN_REQUEST.type, actual: ur.type);
    }
    return fromCBOR(ur.payload);
  }

  static UR buildUR({required String requestId, required ScV2Profile profile, required Uint8List masterFingerprint, required Uint8List signerCoreAddress, required Uint8List semanticTransaction}) {
    return ScV2SignRequest(
      requestId: Uint8List.fromList(uuidParse(requestId)),
      profile: profile,
      masterFingerprint: masterFingerprint,
      signerCoreAddress: signerCoreAddress,
      semanticTransaction: semanticTransaction,
    ).toUR();
  }

  void _validate() {
    if (protocolVersion != supportedProtocolVersion) {
      throw ArgumentError.value(protocolVersion, 'protocolVersion', 'only version $supportedProtocolVersion is supported');
    }
    _validateLength(requestId, 16, 'requestId');
    _validateLength(masterFingerprint, 4, 'masterFingerprint');
    _validateLength(signerCoreAddress, 32, 'signerCoreAddress');
    if (semanticTransaction.isEmpty) {
      throw ArgumentError.value(semanticTransaction.length, 'semanticTransaction', 'must not be empty');
    }
    if (semanticTransaction.length > maxSemanticTransactionBytes) {
      throw ArgumentError.value(semanticTransaction.length, 'semanticTransaction', 'must not exceed $maxSemanticTransactionBytes bytes');
    }
  }

  static void _validateLength(Uint8List value, int length, String name) {
    if (value.length != length) {
      throw ArgumentError.value(value.length, name, 'must be exactly $length bytes');
    }
  }
}
