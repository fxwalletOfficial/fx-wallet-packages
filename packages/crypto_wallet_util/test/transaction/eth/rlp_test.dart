import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/rlp.dart' as rlp;

Uint8List u(List<int> a) => Uint8List.fromList(a);

void main() {
	group('RLP encode basic', () {
		test('encode single byte (<0x80) returns itself', () {
			final out = rlp.encode(u([0x7f]));
			expect(out, equals(u([0x7f])));
		});

		test('encode zero -> 0x80 (empty string)', () {
			final out = rlp.encode(0);
			expect(out, equals(u([0x80])));
		});

		test('encode list of two single bytes', () {
			final out = rlp.encode([u([0x01]), u([0x02])]);
			expect(out[0] >= 0xc0, isTrue); // list prefix
			final decoded = rlp.decode(out) as List;
			expect(decoded.length, 2);
			expect((decoded[0] as Uint8List), equals(u([0x01])));
			expect((decoded[1] as Uint8List), equals(u([0x02])));
		});

		test('encodeLength short and long', () {
			final short = rlp.encodeLength(55, 0x80);
			expect(short, equals(u([0x80 + 55])));
			final long = rlp.encodeLength(56, 0x80);
			expect(long[0], 0x80 + 55 + 1);
			expect(long.length, 1 + 1);
		});
	});

	group('RLP decode cases', () {
		test('decode empty input -> []', () {
			expect(rlp.decode(u([])), equals(<dynamic>[]));
		});

		test('decode single byte and 0x80 empty', () {
			expect(rlp.decode(u([0x7f])), equals(u([0x7f])));
			expect(rlp.decode(u([0x80])), equals(u([])));
		});

		test('decode short string ("cat") and long string (>55)', () {
			final cat = u([0x63, 0x61, 0x74]);
			final encCat = rlp.encode(cat);
			final decCat = rlp.decode(encCat) as Uint8List;
			expect(decCat, equals(cat));

			final longBytes = Uint8List(60);
			for (int i = 0; i < longBytes.length; i++) longBytes[i] = 0x61;
			final encLong = rlp.encode(longBytes);
			final decLong = rlp.decode(encLong) as Uint8List;
			expect(decLong.length, 60);
		});

		test('decode short list and long list (>55) roundtrip', () {
			final shortList = rlp.encode([u([0x01]), u([0x02])]);
			final decShort = rlp.decode(shortList) as List;
			expect((decShort[0] as Uint8List), equals(u([0x01])));
			final longItem = Uint8List(60);
			final longList = rlp.encode([longItem]);
			final decLong = rlp.decode(longList) as List;
			expect((decLong[0] as Uint8List).length, 60);
		});

		test('decode stream=true returns Decoded with remainder', () {
			final a = rlp.encode(u([0x01]));
			final b = rlp.encode(u([0x02]));
			final concatenated = Uint8List.fromList([...a, ...b]);
			final decoded = rlp.decode(concatenated, true) as rlp.Decoded;
			expect(decoded.data, equals(u([0x01])));
			expect(decoded.remainder.isNotEmpty, isTrue);
		});

		test('decode invalid remainder throws', () {
			final a = rlp.encode(u([0x01]));
			final b = rlp.encode(u([0x02]));
			final concatenated = Uint8List.fromList([...a, ...b]);
			expect(() => rlp.decode(concatenated), throwsA(isA<FormatException>()));
		});
	});

	group('RLP error paths', () {
		test('safeParseInt leading zeros throws', () {
			expect(() => rlp.safeParseInt('00', 16), throwsA(isA<FormatException>()));
		});

		test('invalid short string encoding throws', () {
			expect(() => rlp.decode(u([0x81, 0x01])), throwsA(isA<FormatException>()));
		});

		test('invalid long list inner length zero throws', () {
			expect(() => rlp.decode(u([0xf8, 0x00])), throwsA(isA<FormatException>()));
		});
	});

	group('RLP buffer conversions', () {
		test('_toBuffer BigInt zero/non-zero behavior via encode', () {
			final encZero = rlp.encode(BigInt.zero);
			expect(encZero, equals(u([0x80])));
			final encVal = rlp.encode(BigInt.parse('0102', radix: 16));
			final decVal = rlp.decode(encVal) as Uint8List;
			expect(decVal, equals(u([0x01, 0x02])));
		});
	});
} 