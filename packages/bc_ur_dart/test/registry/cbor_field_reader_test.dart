import 'dart:typed_data';

import 'package:bc_ur_dart/src/registry/cbor_field_reader.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:cbor/cbor.dart';
import 'package:test/test.dart';

void main() {
  group('CborFieldReader', () {
    test('throws explicit error for missing required field', () {
      final reader = CborFieldReader(
        CborMap({}),
        model: 'test-model',
      );

      expect(
        () => reader.requiredBytes(1, field: 'uuid'),
        throwsA(
          isA<InvalidCborURException>()
              .having((e) => e.type, 'type', URExceptionType.invalidCbor)
              .having((e) => e.message, 'message', contains('test-model.uuid'))
              .having((e) => e.message, 'message', contains('missing required field 1')),
        ),
      );
    });

    test('throws explicit error for wrong field type', () {
      final reader = CborFieldReader(
        CborMap({CborSmallInt(1): CborString('not-bytes')}),
        model: 'test-model',
      );

      expect(
        () => reader.requiredBytes(1, field: 'uuid'),
        throwsA(
          isA<InvalidCborURException>()
              .having((e) => e.message, 'message', contains('test-model.uuid'))
              .having((e) => e.message, 'message', contains('expected CborBytes'))
              .having((e) => e.message, 'message', contains('CborString')),
        ),
      );
    });

    test('validates fixed byte lengths', () {
      final reader = CborFieldReader(
        CborMap({CborSmallInt(1): CborBytes(Uint8List(15))}),
        model: 'test-model',
      );

      expect(
        () => reader.requiredBytes(1, field: 'uuid', length: 16),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('expected 16 bytes')).having((e) => e.message, 'message', contains('got 15')),
        ),
      );
    });

    test('validates enum index ranges', () {
      final reader = CborFieldReader(
        CborMap({CborSmallInt(1): CborInt(BigInt.from(99))}),
        model: 'test-model',
      );

      expect(
        () => reader.requiredEnumIndex(1, field: 'data_type', valuesLength: 3),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('test-model.data_type')).having((e) => e.message, 'message', contains('out of range')),
        ),
      );
    });

    test('rejects oversized integers before converting to Dart int', () {
      final reader = CborFieldReader(
        CborMap({CborSmallInt(1): CborInt(BigInt.one << 100)}),
        model: 'test-model',
      );

      expect(
        () => reader.requiredInt(1, field: 'master_fingerprint', max: 0xffffffff),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('test-model.master_fingerprint')).having((e) => e.message, 'message', contains('expected <= 4294967295')),
        ),
      );
    });

    test('skips malformed optional fields', () {
      final reader = CborFieldReader(
        CborMap({
          CborSmallInt(1): CborString('not-bytes'),
          CborSmallInt(2): CborString('not-int'),
          CborSmallInt(3): CborString('not-bool'),
          CborSmallInt(4): CborString('not-map'),
          CborSmallInt(5): CborBytes(Uint8List(1)),
          CborSmallInt(6): CborInt(BigInt.one << 100),
        }),
        model: 'test-model',
      );

      expect(reader.optionalBytes(1, field: 'bytes'), isNull);
      expect(reader.optionalInt(2, field: 'int'), isNull);
      expect(reader.optionalBool(3, field: 'bool'), isNull);
      expect(reader.optionalMap(4, field: 'map'), isNull);
      expect(reader.optionalText(5, field: 'text'), isNull);
      expect(reader.optionalInt(6, field: 'bounded_int', max: 0xffffffff), isNull);
    });
  });
}
