import 'dart:typed_data';

import 'package:bc_ur_dart/src/models/sc/sc_v2_codec.dart';
import 'package:bc_ur_dart/src/models/sc/sc_v2_sign_request.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:cbor/cbor.dart';

final class ScV2Signature extends RegistryItem {
  static const int supportedProtocolVersion = ScV2SignRequest.supportedProtocolVersion;
  static const int maxCborPayloadBytes = 90;

  static const int _protocolVersionKey = 1;
  static const int _requestIdKey = 2;
  static const int _signatureKey = 3;
  static const List<int> _keys = <int>[_protocolVersionKey, _requestIdKey, _signatureKey];

  final int protocolVersion;
  final Uint8List requestId;
  final Uint8List signature;

  ScV2Signature({this.protocolVersion = supportedProtocolVersion, required Uint8List requestId, required Uint8List signature})
      : requestId = Uint8List.fromList(requestId),
        signature = Uint8List.fromList(signature) {
    _validate();
  }

  String get requestIdString => uuidStringify(requestId);

  @override
  RegistryType getRegistryType() => RegistryType.SC_V2_SIGNATURE;

  @override
  CborValue toCborValue() {
    _validate();
    return CborMap(<CborValue, CborValue>{
      const CborSmallInt(_protocolVersionKey): const CborSmallInt(supportedProtocolVersion),
      const CborSmallInt(_requestIdKey): CborBytes(requestId, tags: const <int>[37]),
      const CborSmallInt(_signatureKey): CborBytes(signature),
    }, type: CborLengthType.definite);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    return fromCBOR(Uint8List.fromList(cbor.encode(map)));
  }

  static ScV2Signature fromCBOR(Uint8List cborPayload) {
    const model = 'sc-v2-signature';
    final map = ScV2Codec.decodeMap(cborPayload, model: model, keys: _keys, maxPayloadBytes: maxCborPayloadBytes);
    final version = ScV2Codec.readInt(map, _protocolVersionKey, model: model, field: 'protocolVersion');
    if (version != supportedProtocolVersion) {
      throw InvalidCborURException(model: model, field: 'protocolVersion', reason: 'unsupported version $version');
    }

    return ScV2Signature(
      protocolVersion: version,
      requestId: ScV2Codec.readBytes(map, _requestIdKey, model: model, field: 'requestId', length: 16, tags: const <int>[37]),
      signature: ScV2Codec.readBytes(map, _signatureKey, model: model, field: 'signature', length: 64),
    );
  }

  static ScV2Signature fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.SC_V2_SIGNATURE.type) {
      throw InvalidTypeURException(expected: RegistryType.SC_V2_SIGNATURE.type, actual: ur.type);
    }
    return fromCBOR(ur.payload);
  }

  static UR buildUR({required String requestId, required Uint8List signature}) {
    return ScV2Signature(requestId: Uint8List.fromList(uuidParse(requestId)), signature: signature).toUR();
  }

  static UR fromRequest({required ScV2SignRequest request, required Uint8List signature}) {
    return ScV2Signature(requestId: request.requestId, signature: signature).toUR();
  }

  void _validate() {
    if (protocolVersion != supportedProtocolVersion) {
      throw ArgumentError.value(protocolVersion, 'protocolVersion', 'only version $supportedProtocolVersion is supported');
    }
    if (requestId.length != 16) {
      throw ArgumentError.value(requestId.length, 'requestId', 'must be exactly 16 bytes');
    }
    if (signature.length != 64) {
      throw ArgumentError.value(signature.length, 'signature', 'must be exactly 64 bytes');
    }
  }
}
