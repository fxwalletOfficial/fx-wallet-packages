import 'dart:convert';

import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:cbor/cbor.dart';

class KeystoneXrpAccountBytes {
  final String address;
  final String publicKey;
  final Map<String, dynamic> payload;

  const KeystoneXrpAccountBytes({
    required this.address,
    required this.publicKey,
    required this.payload,
  });

  static KeystoneXrpAccountBytes fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.BYTES.type) {
      throw InvalidTypeURException(expected: RegistryType.BYTES.type, actual: ur.type);
    }

    final Map<String, dynamic> json = _decodeJsonPayload(ur);
    final String address = _readString(json, ['address', 'Address']);
    final String publicKey = _readString(json, ['pubkey', 'publicKey', 'SigningPubKey']);
    if (address.isEmpty || publicKey.isEmpty) {
      throw InvalidCborURException(model: 'keystone-xrp-account', reason: 'missing address/publicKey in payload');
    }

    return KeystoneXrpAccountBytes(
      address: address,
      publicKey: publicKey,
      payload: json,
    );
  }

  static Map<String, dynamic> _decodeJsonPayload(UR ur) {
    final CborValue decoded;
    try {
      decoded = ur.decodeCBOR();
    } on Object catch (error) {
      throw InvalidCborURException(model: 'keystone-xrp-account', reason: 'invalid CBOR payload', cause: error);
    }
    if (decoded is! CborBytes) {
      throw InvalidCborURException(model: 'keystone-xrp-account', reason: 'expected top-level CborBytes, got ${decoded.runtimeType}');
    }

    final dynamic json;
    try {
      json = jsonDecode(utf8.decode(decoded.bytes));
    } on Object catch (error) {
      throw InvalidCborURException(model: 'keystone-xrp-account', reason: 'payload is not valid UTF-8 JSON', cause: error);
    }
    if (json is! Map<String, dynamic>) {
      throw InvalidCborURException(model: 'keystone-xrp-account', reason: 'payload must decode to a JSON object, got ${json.runtimeType}');
    }
    return json;
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return '';
  }
}
