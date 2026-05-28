import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur_dart/src/registry/registry_item.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:cbor/cbor.dart';

enum ScSignRequestKeys {
  zero,
  uuid,
  xfp,
  path,
  address,
  publicKey,
  signingPayloadData,
  fee,
  outputs,
  subtractFee,
  origin,
  chain,
}

class ScSignRequest extends RegistryItem {
  /// Request id follows the same UUID-bytes convention as other sign requests.
  /// It is generated lazily when omitted by the caller.
  Uint8List? uuid;
  final String xfp;
  final String path;
  final String address;
  final String publicKey;

  /// The value of API response `signing_payload.data`.
  /// Cold side passes this directly to `ScUnsignedTransaction.fromJson`.
  final Map<String, dynamic> signingPayloadData;

  /// Optional display metadata from the hot side; not used to build the SC tx.
  final String? fee;
  final List<dynamic>? outputs;
  final bool? subtractFee;
  final String? origin;
  final String chain;

  ScSignRequest({
    this.uuid,
    required this.xfp,
    required this.path,
    required this.address,
    required this.publicKey,
    required this.signingPayloadData,
    this.fee,
    this.outputs,
    this.subtractFee,
    this.origin,
    this.chain = '',
  });

  Uint8List getRequestId() => uuid ??= generateUuid();
  String getRequestIdString() => uuidStringify(getRequestId());

  @override
  RegistryType getRegistryType() => RegistryType.SC_SIGN_REQUEST;

  @override
  CborValue toCborValue() {
    final Map<CborValue, CborValue> map = {
      CborSmallInt(ScSignRequestKeys.uuid.index): cborBytes(
        getRequestId(),
        tags: [RegistryType.UUID.tag],
      ),
      CborSmallInt(ScSignRequestKeys.xfp.index): CborString(xfp),
      CborSmallInt(ScSignRequestKeys.path.index): CborString(path),
      CborSmallInt(ScSignRequestKeys.address.index): CborString(address),
      CborSmallInt(ScSignRequestKeys.publicKey.index): CborString(publicKey),
      CborSmallInt(ScSignRequestKeys.signingPayloadData.index): cborBytes(_jsonBytes(signingPayloadData)),
    };

    if (origin != null) {
      map[CborSmallInt(ScSignRequestKeys.origin.index)] = CborString(origin!);
    }
    if (fee != null) {
      map[CborSmallInt(ScSignRequestKeys.fee.index)] = CborString(fee!);
    }
    if (outputs != null) {
      map[CborSmallInt(ScSignRequestKeys.outputs.index)] = cborBytes(_jsonBytes(outputs));
    }
    if (subtractFee != null) {
      map[CborSmallInt(ScSignRequestKeys.subtractFee.index)] = CborBool(subtractFee!);
    }
    if (chain.isNotEmpty) {
      map[CborSmallInt(ScSignRequestKeys.chain.index)] = CborString(chain);
    }

    return CborMap(map);
  }

  @override
  RegistryItem decodeFromCbor(CborMap map) {
    return ScSignRequest(
      uuid: RegistryItem.readBytes(map, ScSignRequestKeys.uuid.index),
      xfp: _readText(map, ScSignRequestKeys.xfp.index),
      path: _readText(map, ScSignRequestKeys.path.index),
      address: _readText(map, ScSignRequestKeys.address.index),
      publicKey: _readText(map, ScSignRequestKeys.publicKey.index),
      signingPayloadData: _readJsonMap(map, ScSignRequestKeys.signingPayloadData.index),
      fee: RegistryItem.readOptionalText(map, ScSignRequestKeys.fee.index),
      outputs: _readOptionalJsonList(map, ScSignRequestKeys.outputs.index),
      subtractFee: _readOptionalBool(map, ScSignRequestKeys.subtractFee.index),
      origin: RegistryItem.readOptionalText(map, ScSignRequestKeys.origin.index),
      chain: RegistryItem.readOptionalText(map, ScSignRequestKeys.chain.index) ?? '',
    );
  }

  static ScSignRequest fromCBOR(Uint8List cborPayload) {
    return RegistryItem.fromCBOR<ScSignRequest>(
      cborPayload,
      ScSignRequest(
        xfp: '',
        path: '',
        address: '',
        publicKey: '',
        signingPayloadData: const {},
      ),
    );
  }

  static ScSignRequest fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.SC_SIGN_REQUEST.type) {
      throw ArgumentError('Invalid UR type for ScSignRequest: ${ur.type}');
    }
    return fromCBOR(ur.payload);
  }

  static UR buildUR({
    String? requestId,
    required String xfp,
    required String path,
    required String address,
    required String publicKey,
    required Map<String, dynamic> signingPayloadData,
    String? fee,
    List<dynamic>? outputs,
    bool? subtractFee,
    String? origin,
    String chain = '',
  }) {
    return ScSignRequest(
      uuid: requestId != null ? Uint8List.fromList(uuidParse(requestId)) : null,
      xfp: xfp,
      path: path,
      address: address,
      publicKey: publicKey,
      signingPayloadData: signingPayloadData,
      fee: fee,
      outputs: outputs,
      subtractFee: subtractFee,
      origin: origin,
      chain: chain,
    ).toUR();
  }

  static Uint8List _jsonBytes(Object? value) {
    return Uint8List.fromList(utf8.encode(jsonEncode(value)));
  }

  static String _readText(CborMap map, int key) {
    final value = map[CborSmallInt(key)];
    if (value is CborString) return value.toString();
    throw ArgumentError('Invalid text at key $key');
  }

  static Map<String, dynamic> _readJsonMap(CborMap map, int key) {
    final value = _readJson(map, key);
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ArgumentError('Invalid json map at key $key');
  }

  static List<dynamic>? _readOptionalJsonList(CborMap map, int key) {
    if (!RegistryItem.hasKey(map, key)) return null;
    final value = _readJson(map, key);
    if (value is List<dynamic>) return value;
    throw ArgumentError('Invalid json list at key $key');
  }

  static dynamic _readJson(CborMap map, int key) {
    final bytes = RegistryItem.readBytes(map, key);
    return jsonDecode(utf8.decode(bytes));
  }

  static bool? _readOptionalBool(CborMap map, int key) {
    if (!RegistryItem.hasKey(map, key)) return null;
    final value = map[CborSmallInt(key)];
    if (value is CborBool) return value.value;
    throw ArgumentError('Invalid bool at key $key');
  }
}
