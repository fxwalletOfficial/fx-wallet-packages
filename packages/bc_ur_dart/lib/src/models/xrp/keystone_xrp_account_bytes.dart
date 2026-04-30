import 'dart:convert';

import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
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
      throw ArgumentError(
          'Invalid UR type for KeystoneXrpAccountBytes: ${ur.type}');
    }

    final Map<String, dynamic> json = _decodeJsonPayload(ur);
    final String address = _readString(json, ['address', 'Address']);
    final String publicKey =
        _readString(json, ['pubkey', 'publicKey', 'SigningPubKey']);
    if (address.isEmpty || publicKey.isEmpty) {
      throw ArgumentError('Invalid Keystone XRP account bytes payload');
    }

    return KeystoneXrpAccountBytes(
      address: address,
      publicKey: publicKey,
      payload: json,
    );
  }

  static Map<String, dynamic> _decodeJsonPayload(UR ur) {
    final CborValue decoded = ur.decodeCBOR();
    if (decoded is! CborBytes) {
      throw ArgumentError('Keystone XRP bytes payload must be cbor bytes');
    }

    final dynamic json = jsonDecode(utf8.decode(decoded.bytes));
    if (json is! Map<String, dynamic>) {
      throw ArgumentError(
          'Keystone XRP account bytes payload must decode to a JSON object');
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
