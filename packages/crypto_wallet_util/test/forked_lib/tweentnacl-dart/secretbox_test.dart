import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/tweetnacl-dart/tweetnacl.dart';

void main() {
	group('SecretBox', () {
		test('box/open with explicit nonce (roundtrip)', () {
			final Uint8List key = Uint8List.fromList(List<int>.generate(32, (i) => i));
			final Uint8List nonce = Uint8List.fromList(List<int>.generate(24, (i) => 24 - i));
			final Uint8List message = Uint8List.fromList('hello tweentnacl'.codeUnits);

			final box = SecretBox(key);
			final Uint8List? cipher = box.box_nonce(message, nonce);
			expect(cipher, isNotNull);

			final Uint8List? plain = box.open_nonce(cipher!, nonce);
			expect(plain, isNotNull);
			expect(String.fromCharCodes(plain!), 'hello tweentnacl');
		});

		test('open fails on wrong nonce', () {
			final Uint8List key = Uint8List.fromList(List<int>.generate(32, (i) => i));
			final Uint8List nonce = Uint8List.fromList(List<int>.filled(24, 7));
			final Uint8List badNonce = Uint8List.fromList(List<int>.filled(24, 8));
			final Uint8List message = Uint8List.fromList([1, 2, 3, 4, 5]);

			final box = SecretBox(key);
			final Uint8List? cipher = box.box_nonce(message, nonce);
			expect(cipher, isNotNull);

			final Uint8List? plain = box.open_nonce(cipher!, badNonce);
			expect(plain, isNull);
		});
	});
} 