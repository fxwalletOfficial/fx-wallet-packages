import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/tweetnacl-dart/tweetnacl.dart';

void main() {
	group('Hash', () {
		test('sha512 length and determinism', () {
			final Uint8List a = Uint8List.fromList('abc'.codeUnits);
			final Uint8List b = Uint8List.fromList('abc'.codeUnits);
			final out1 = Hash.sha512(a)!;
			final out2 = Hash.sha512(b)!;
			expect(out1.length, equals(Hash.hashLength));
			expect(out1, equals(out2));
		});
	});

	group('ScalarMult', () {
		test('base and mult lengths', () {
			final n = Uint8List.fromList(List<int>.generate(32, (i) => i));
			final q1 = ScalarMult.scalseMult_base(n)!;
			expect(q1.length, equals(ScalarMult.groupElementLength));

			final p = Uint8List.fromList(List<int>.filled(32, 1));
			final q2 = ScalarMult.scalseMult(n, p)!;
			expect(q2.length, equals(ScalarMult.groupElementLength));
		});
	});
} 