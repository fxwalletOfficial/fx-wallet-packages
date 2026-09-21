import 'dart:typed_data';

import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:cbor/cbor.dart';

final class ScV2Codec {
  const ScV2Codec._();

  static CborMap decodeMap(Uint8List payload, {required String model, required List<int> keys, required int maxPayloadBytes}) {
    if (payload.length > maxPayloadBytes) {
      throw InvalidCborURException(model: model, reason: 'payload exceeds $maxPayloadBytes bytes');
    }

    final CborValue decoded;
    try {
      decoded = cbor.decode(payload);
    } on Object catch (error) {
      throw InvalidCborURException(model: model, reason: 'invalid CBOR payload', cause: error);
    }

    if (decoded is! CborMap) {
      throw InvalidCborURException(model: model, reason: 'expected top-level CborMap, got ${decoded.runtimeType}');
    }
    if (decoded.type != CborLengthType.definite || decoded.tags.isNotEmpty) {
      throw InvalidCborURException(model: model, reason: 'top-level map must be definite-length and untagged');
    }

    final actualKeys = decoded.keys.toList(growable: false);
    if (actualKeys.length != keys.length) {
      throw InvalidCborURException(model: model, reason: 'expected exactly keys ${keys.join(', ')}, got ${actualKeys.length} fields');
    }
    for (var index = 0; index < keys.length; index++) {
      final key = actualKeys[index];
      if (key is! CborSmallInt || key.tags.isNotEmpty || key.toInt() != keys[index]) {
        throw InvalidCborURException(model: model, reason: 'expected canonical key ${keys[index]} at field ${index + 1}');
      }
    }

    final canonical = cbor.encode(decoded);
    if (!_bytesEqual(payload, canonical)) {
      // This also catches duplicate keys: cbor.decode necessarily collapses them,
      // so re-encoding cannot reproduce the original map.
      throw InvalidCborURException(model: model, reason: 'payload is not deterministic canonical CBOR');
    }

    return decoded;
  }

  static int readInt(CborMap map, int key, {required String model, required String field}) {
    final value = map[CborSmallInt(key)];
    if (value is! CborInt || value.tags.isNotEmpty) {
      throw InvalidCborURException(model: model, field: field, reason: 'expected untagged integer');
    }
    final number = value.toBigInt();
    if (!number.isValidInt) {
      throw InvalidCborURException(model: model, field: field, reason: 'integer is outside the Dart int range');
    }
    return number.toInt();
  }

  static Uint8List readBytes(CborMap map, int key, {required String model, required String field, int? length, int? maxLength, bool allowEmpty = false, List<int> tags = const []}) {
    final value = map[CborSmallInt(key)];
    if (value is! CborBytes || value.type != CborLengthType.definite || !_intsEqual(value.tags, tags)) {
      throw InvalidCborURException(model: model, field: field, reason: 'expected definite-length bytes with tags $tags');
    }
    if (length != null && value.bytes.length != length) {
      throw InvalidCborURException(model: model, field: field, reason: 'expected $length bytes, got ${value.bytes.length}');
    }
    if (!allowEmpty && value.bytes.isEmpty) {
      throw InvalidCborURException(model: model, field: field, reason: 'must not be empty');
    }
    if (maxLength != null && value.bytes.length > maxLength) {
      throw InvalidCborURException(model: model, field: field, reason: 'exceeds $maxLength bytes');
    }
    return Uint8List.fromList(value.bytes);
  }

  static bool _bytesEqual(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static bool _intsEqual(List<int> left, List<int> right) {
    return _bytesEqual(left, right);
  }
}
