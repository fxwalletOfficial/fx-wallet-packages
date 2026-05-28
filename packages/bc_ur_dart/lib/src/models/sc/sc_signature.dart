import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur_dart/src/models/sc/sc_sign_request.dart';
import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:cbor/cbor.dart';

enum ScSignatureKeys {
  zero,
  uuid,
  broadcastTx,
  origin,
}

class ScSignature extends RegistryItem {
  /// Mirrors the request UUID so the hot side can match the scanned result.
  Uint8List? uuid;

  /// Direct output of `txData.toBroadcast()` after cold-side signing.
  final Map<String, dynamic> broadcastTx;
  final String? origin;

  ScSignature({
    this.uuid,
    required this.broadcastTx,
    this.origin,
  });

  Uint8List getRequestId() => uuid ??= generateUuid();
  String getRequestIdString() => uuidStringify(getRequestId());

  @override
  RegistryType getRegistryType() => RegistryType.SC_SIGNATURE;

  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {
      CborSmallInt(ScSignatureKeys.uuid.index): cborBytes(
        getRequestId(),
        tags: [RegistryType.UUID.tag],
      ),
      CborSmallInt(ScSignatureKeys.broadcastTx.index): cborBytes(_jsonBytes(broadcastTx)),
    };

    if (origin != null) {
      map[CborSmallInt(ScSignatureKeys.origin.index)] = CborString(origin!);
    }

    return CborMap(map);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    return ScSignature(
      uuid: RegistryItem.readBytes(map, ScSignatureKeys.uuid.index),
      broadcastTx: _readJsonMap(map, ScSignatureKeys.broadcastTx.index),
      origin: RegistryItem.readOptionalText(map, ScSignatureKeys.origin.index),
    );
  }

  static ScSignature fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<ScSignature>(
      cborPayload,
      ScSignature(broadcastTx: const {}),
    );
  }

  static ScSignature fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.SC_SIGNATURE.type) {
      throw ArgumentError('Invalid UR type for ScSignature: ${ur.type}');
    }
    return fromCBOR(ur.payload);
  }

  static UR buildUR({
    String? requestId,
    required Map<String, dynamic> broadcastTx,
    String? origin,
  }) {
    return ScSignature(
      uuid: requestId != null ? Uint8List.fromList(uuidParse(requestId)) : null,
      broadcastTx: broadcastTx,
      origin: origin,
    ).toUR();
  }

  static UR fromSignedTx({
    required ScSignRequest request,
    required Map<String, dynamic> broadcastTx,
  }) {
    return buildUR(
      requestId: request.getRequestIdString(),
      broadcastTx: broadcastTx,
      origin: request.origin,
    );
  }

  static Uint8List _jsonBytes(Object? value) {
    return Uint8List.fromList(utf8.encode(jsonEncode(value)));
  }

  static Map<String, dynamic> _readJsonMap(CborMap map, int key) {
    final value = _readJson(map, key);
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ArgumentError('Invalid json map at key $key');
  }

  static dynamic _readJson(CborMap map, int key) {
    final bytes = RegistryItem.readBytes(map, key);
    return jsonDecode(utf8.decode(bytes));
  }
}
