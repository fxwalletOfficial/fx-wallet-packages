import 'dart:typed_data';

import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/cbor_value.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:cbor/cbor.dart';

class CborFieldReader {
  CborFieldReader(this.map, {required this.model});

  final CborMap map;
  final String model;

  static CborFieldReader fromUr(UR ur, {required String model, required String expectedType}) {
    if (ur.type.toLowerCase() != expectedType.toLowerCase()) {
      throw InvalidTypeURException(expected: expectedType, actual: ur.type);
    }

    final CborValue decoded;
    try {
      decoded = ur.decodeCBOR();
    } on Object catch (error) {
      throw InvalidCborURException(model: model, reason: 'invalid CBOR payload', cause: error);
    }

    if (decoded is! CborMap) {
      throw InvalidCborURException(model: model, reason: 'expected top-level CborMap, got ${decoded.runtimeType}');
    }

    return CborFieldReader(decoded, model: model);
  }

  bool has(int key) => map.containsKey(CborSmallInt(key));

  CborValue? optionalValue(int key) => map[CborSmallInt(key)];

  CborValue requiredValue(int key, {required String field}) {
    final value = optionalValue(key);
    if (value == null) {
      throw InvalidCborURException(model: model, field: field, reason: 'missing required field $key');
    }
    return value;
  }

  Uint8List requiredBytes(int key, {required String field, int? length}) {
    final value = requiredValue(key, field: field);
    if (value is! CborBytes) {
      throw _wrongType(field, 'CborBytes', value);
    }
    final bytes = cborBytesOrNull(value, length: length);
    if (bytes == null) {
      throw InvalidCborURException(model: model, field: field, reason: 'expected $length bytes, got ${value.bytes.length}');
    }
    return bytes;
  }

  Uint8List? optionalBytes(int key, {required String field, int? length}) {
    return cborBytesOrNull(optionalValue(key), length: length);
  }

  CborMap requiredMap(int key, {required String field}) {
    final value = requiredValue(key, field: field);
    if (value is! CborMap) {
      throw _wrongType(field, 'CborMap', value);
    }
    return value;
  }

  CborMap? optionalMap(int key, {required String field}) {
    return cborMapOrNull(optionalValue(key));
  }

  CborList requiredList(int key, {required String field}) {
    final value = requiredValue(key, field: field);
    if (value is! CborList) {
      throw _wrongType(field, 'CborList', value);
    }
    return value;
  }

  int requiredInt(int key, {required String field, int? min, int? max}) {
    final value = requiredValue(key, field: field);
    if (value is! CborInt) {
      throw _wrongType(field, 'CborInt', value);
    }
    final number = value.toBigInt();
    if (min != null && number < BigInt.from(min)) {
      throw InvalidCborURException(model: model, field: field, reason: 'expected >= $min, got $number');
    }
    if (max != null && number > BigInt.from(max)) {
      throw InvalidCborURException(model: model, field: field, reason: 'expected <= $max, got $number');
    }
    return number.toInt();
  }

  int? optionalInt(int key, {required String field, int? min, int? max}) {
    return cborIntOrNull(optionalValue(key), min: min, max: max);
  }

  BigInt requiredBigInt(int key, {required String field, BigInt? min, BigInt? max}) {
    final value = requiredValue(key, field: field);
    if (value is! CborInt) {
      throw _wrongType(field, 'CborInt', value);
    }
    final raw = value.toBigInt();
    final number = cborBigIntOrNull(value, min: min, max: max);
    if (number == null && min != null && raw < min) {
      throw InvalidCborURException(model: model, field: field, reason: 'expected >= $min, got $raw');
    }
    if (number == null && max != null && raw > max) {
      throw InvalidCborURException(model: model, field: field, reason: 'expected <= $max, got $raw');
    }
    return number!;
  }

  String requiredText(int key, {required String field}) {
    final value = requiredValue(key, field: field);
    if (value is! CborString) {
      throw _wrongType(field, 'CborString', value);
    }
    return value.toString();
  }

  String? optionalText(int key, {required String field}) {
    return cborTextOrNull(optionalValue(key));
  }

  bool? optionalBool(int key, {required String field}) {
    return cborBoolOrNull(optionalValue(key));
  }

  int requiredEnumIndex(int key, {required String field, required int valuesLength}) {
    final index = requiredInt(key, field: field, min: 0);
    if (index >= valuesLength) {
      throw InvalidCborURException(model: model, field: field, reason: 'enum index $index out of range 0..${valuesLength - 1}');
    }
    return index;
  }

  InvalidCborURException _wrongType(String field, String expected, CborValue actual) {
    return InvalidCborURException(model: model, field: field, reason: 'expected $expected, got ${actual.runtimeType}');
  }
}
