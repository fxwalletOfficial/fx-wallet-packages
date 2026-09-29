import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';

/// Regression tests for issue #87: GsplItem serialized a null amount as the
/// string 'null' and could not hold amounts above int64 (ALPH uses 1e18
/// attoALPH units, so 10 ALPH already overflows).
void main() {
  final int64Max = BigInt.parse('9223372036854775807');
  final tenAlph = BigInt.parse('10000000000000000000');

  group('GsplItem.toJson amount', () {
    test('null amount serializes as null, not the string "null"', () {
      final json = GsplItem(address: 'addr').toJson();
      expect(json.containsKey('amount'), isTrue);
      expect(json['amount'], isNull);
    });

    test('int amount serializes as a decimal string', () {
      expect(GsplItem(amount: 62926).toJson()['amount'], '62926');
    });

    test('amount exactly at int64 max serializes exactly', () {
      final item = GsplItem(amountBigInt: int64Max);
      expect(item.toJson()['amount'], '9223372036854775807');
      expect(item.amountBigInt, int64Max);
    });

    test('amount above int64 (10 ALPH) serializes exactly', () {
      final item = GsplItem(amountBigInt: tenAlph);
      expect(item.toJson()['amount'], '10000000000000000000');
      expect(item.amountBigInt, tenAlph);
    });
  });

  group('GsplItem amount accessors', () {
    test('int amount is mirrored as amountBigInt', () {
      final item = GsplItem(amount: 82787);
      expect(item.amount, 82787);
      expect(item.amountBigInt, BigInt.from(82787));
    });

    test('small BigInt amount is readable as int', () {
      expect(GsplItem(amountBigInt: BigInt.from(100)).amount, 100);
    });

    test('null amount stays null on both accessors', () {
      final item = GsplItem();
      expect(item.amount, isNull);
      expect(item.amountBigInt, isNull);
    });

    test('reading an above-int64 amount as int throws instead of truncating',
        () {
      final item = GsplItem(amountBigInt: tenAlph);
      expect(() => item.amount, throwsStateError);
    });

    test('passing both amount and amountBigInt is rejected', () {
      expect(
        () => GsplItem(amount: 1, amountBigInt: BigInt.one),
        throwsArgumentError,
      );
    });
  });
}
