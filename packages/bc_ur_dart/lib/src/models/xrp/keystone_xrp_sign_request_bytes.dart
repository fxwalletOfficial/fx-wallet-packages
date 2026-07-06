import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';

class KeystoneXrpSignRequestBytes {
  final Map<String, dynamic> transaction;
  final Uint8List payloadBytes;

  const KeystoneXrpSignRequestBytes({
    required this.transaction,
    required this.payloadBytes,
  });

  static KeystoneXrpSignRequestBytes fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.BYTES.type) {
      throw ArgumentError('Invalid UR type for KeystoneXrpSignRequestBytes: ${ur.type}');
    }

    final decoded = ur.decodeCBOR();
    if (decoded is! CborBytes) {
      throw ArgumentError('Keystone XRP sign request payload must be cbor bytes');
    }

    final dynamic json = jsonDecode(utf8.decode(decoded.bytes));
    if (json is! Map<String, dynamic>) {
      throw ArgumentError('Keystone XRP sign request payload must decode to a JSON object');
    }

    return KeystoneXrpSignRequestBytes(
      transaction: json,
      payloadBytes: Uint8List.fromList(decoded.bytes),
    );
  }

  static UR buildUR({required Map<String, dynamic> transaction}) {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(jsonEncode(transaction)));
    return UR.fromCBOR(
      type: RegistryType.BYTES.type,
      value: CborBytes(bytes),
    );
  }
}
