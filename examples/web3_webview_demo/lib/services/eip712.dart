import 'dart:convert';
import 'dart:typed_data';

import 'package:web3dart/web3dart.dart';

/// Minimal EIP-712 (`eth_signTypedData_v4`) encoder.
///
/// Produces the 32-byte digest a wallet signs:
///
///   keccak256(0x1901 ‖ domainSeparator ‖ hashStruct(primaryType, message))
///
/// Implemented from scratch (rather than via `eth_sig_util`, which pins an
/// incompatible `pointycastle ^3`) on top of web3dart's `keccak256`. The
/// encoder is v4-shaped: it supports nested structs and arrays, which makes
/// it a superset of v3 for any payload that doesn't use arrays. The legacy
/// v1 array form is intentionally unsupported.
class Eip712 {
  /// Compute the signing digest for a decoded typed-data [payload]
  /// (`{ types, domain, primaryType, message }`).
  static Uint8List digest(Map<String, dynamic> payload) {
    final types = (payload['types'] as Map).cast<String, dynamic>();
    final primaryType = payload['primaryType'] as String;
    final domain = (payload['domain'] as Map).cast<String, dynamic>();
    final message = (payload['message'] as Map).cast<String, dynamic>();

    final domainSeparator = _hashStruct(types, 'EIP712Domain', domain);
    final messageHash = _hashStruct(types, primaryType, message);

    final builder = BytesBuilder();
    builder.add([0x19, 0x01]);
    builder.add(domainSeparator);
    builder.add(messageHash);
    return keccak256(builder.toBytes());
  }

  /// Convenience for callers that hold the raw JSON string.
  static Uint8List digestFromJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map) {
      throw const FormatException(
          'typed data must be a JSON object (v1 array form unsupported)');
    }
    return digest(decoded.cast<String, dynamic>());
  }

  // hashStruct(s) = keccak256(typeHash(type) ‖ encodeData(type, data))
  static Uint8List _hashStruct(
    Map<String, dynamic> types,
    String type,
    Map<String, dynamic> data,
  ) {
    return keccak256(_encodeData(types, type, data));
  }

  static Uint8List _encodeData(
    Map<String, dynamic> types,
    String type,
    Map<String, dynamic> data,
  ) {
    final builder = BytesBuilder();
    builder.add(_typeHash(types, type));

    final fields = (types[type] as List).cast<dynamic>();
    for (final field in fields) {
      final f = (field as Map).cast<String, dynamic>();
      builder.add(_encodeField(types, f['type'] as String, data[f['name']]));
    }
    return builder.toBytes();
  }

  static Uint8List _typeHash(Map<String, dynamic> types, String type) {
    return keccak256(Uint8List.fromList(utf8.encode(_encodeType(types, type))));
  }

  // "Primary(t1 n1,t2 n2)Dep1(...)Dep2(...)" with deps sorted alphabetically.
  static String _encodeType(Map<String, dynamic> types, String primaryType) {
    final deps = _dependencies(types, primaryType, <String>{})
      ..remove(primaryType);
    final ordered = [primaryType, ...(deps.toList()..sort())];

    final buffer = StringBuffer();
    for (final type in ordered) {
      final fields = (types[type] as List).cast<dynamic>();
      final params = fields
          .map((f) => '${(f as Map)['type']} ${f['name']}')
          .join(',');
      buffer.write('$type($params)');
    }
    return buffer.toString();
  }

  static Set<String> _dependencies(
    Map<String, dynamic> types,
    String type,
    Set<String> found,
  ) {
    final bareType = _baseType(type);
    if (found.contains(bareType) || !types.containsKey(bareType)) {
      return found;
    }
    found.add(bareType);
    for (final field in (types[bareType] as List)) {
      _dependencies(types, (field as Map)['type'] as String, found);
    }
    return found;
  }

  static Uint8List _encodeField(
    Map<String, dynamic> types,
    String type,
    dynamic value,
  ) {
    // Nested struct → hashStruct.
    if (types.containsKey(type)) {
      return _hashStruct(
          types, type, (value as Map).cast<String, dynamic>());
    }

    // Array → keccak256 of the concatenated encoded elements.
    if (type.endsWith(']')) {
      final inner = type.substring(0, type.lastIndexOf('['));
      final items = (value as List);
      final builder = BytesBuilder();
      for (final item in items) {
        builder.add(_encodeField(types, inner, item));
      }
      return keccak256(builder.toBytes());
    }

    if (type == 'string') {
      return keccak256(Uint8List.fromList(utf8.encode(value as String)));
    }
    if (type == 'bytes') {
      return keccak256(_dynamicBytes(value));
    }
    if (type == 'bool') {
      return _pad32(BigInt.from((value == true || value == 'true') ? 1 : 0));
    }
    if (type == 'address') {
      return _pad32(BigInt.parse(strip0x(value as String), radix: 16));
    }
    if (type.startsWith('uint') || type.startsWith('int')) {
      return _pad32(_toBigInt(value));
    }
    if (type.startsWith('bytes')) {
      // bytesN — right-padded to 32.
      final bytes = _dynamicBytes(value);
      final out = Uint8List(32);
      out.setRange(0, bytes.length, bytes);
      return out;
    }

    throw FormatException('Unsupported EIP-712 field type: $type');
  }

  static String _baseType(String type) {
    final bracket = type.indexOf('[');
    return bracket == -1 ? type : type.substring(0, bracket);
  }

  static Uint8List _dynamicBytes(dynamic value) {
    if (value is String) {
      return value.startsWith('0x')
          ? hexToBytes(value)
          : Uint8List.fromList(utf8.encode(value));
    }
    if (value is List) {
      return Uint8List.fromList(value.cast<int>());
    }
    throw FormatException('Cannot read bytes from $value');
  }

  static BigInt _toBigInt(dynamic value) {
    if (value is int) return BigInt.from(value);
    if (value is BigInt) return value;
    if (value is String) {
      return value.startsWith('0x')
          ? BigInt.parse(strip0x(value), radix: 16)
          : BigInt.parse(value);
    }
    throw FormatException('Cannot read integer from $value');
  }

  /// 32-byte big-endian two's-complement encoding of [value].
  static Uint8List _pad32(BigInt value) {
    var v = value;
    if (v < BigInt.zero) {
      v = (BigInt.one << 256) + v; // two's complement
    }
    final out = Uint8List(32);
    for (var i = 31; i >= 0; i--) {
      out[i] = (v & BigInt.from(0xff)).toInt();
      v = v >> 8;
    }
    return out;
  }
}
