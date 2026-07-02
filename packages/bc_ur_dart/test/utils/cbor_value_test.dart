import 'dart:typed_data';

import 'package:bc_ur_dart/src/utils/cbor_value.dart';
import 'package:cbor/cbor.dart';
import 'package:test/test.dart';

void main() {
  group('CBOR value utils', () {
    test('converts typed CBOR values', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final map = CborMap({CborSmallInt(1): CborString('value')});
      final list = CborList([CborSmallInt(1)]);

      expect(cborBytesOrNull(CborBytes(bytes)), bytes);
      expect(cborIntOrNull(CborInt(BigInt.from(7))), 7);
      expect(cborBigIntOrNull(CborInt(BigInt.parse('9223372036854775808'))), BigInt.parse('9223372036854775808'));
      expect(cborTextOrNull(CborString('text')), 'text');
      expect(cborMapOrNull(map), same(map));
      expect(cborListOrNull(list), same(list));
      expect(cborBoolOrNull(CborBool(true)), isTrue);
    });

    test('returns null for malformed optional values', () {
      expect(cborBytesOrNull(CborString('not-bytes')), isNull);
      expect(cborBytesOrNull(CborBytes(Uint8List(1)), length: 2), isNull);
      expect(cborIntOrNull(CborString('not-int')), isNull);
      expect(cborIntOrNull(CborInt(BigInt.one << 100), max: 0xffffffff), isNull);
      expect(cborBigIntOrNull(CborString('not-bigint')), isNull);
      expect(cborTextOrNull(CborBytes(Uint8List(1))), isNull);
      expect(cborMapOrNull(CborList([])), isNull);
      expect(cborListOrNull(CborMap({})), isNull);
      expect(cborBoolOrNull(CborString('not-bool')), isNull);
    });
  });
}
