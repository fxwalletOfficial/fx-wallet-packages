import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/tweetnacl-dart/tweetnacl.dart';

void main() {
	group('Box', () {
		test('box/open with explicit nonce (roundtrip)', () {
			final kpAlice = Box.keyPair();
			final kpBob = Box.keyPair();

			final Uint8List nonce = Uint8List.fromList(List<int>.generate(24, (i) => i));
			final Uint8List message = Uint8List.fromList('hello box'.codeUnits);

			// 使用底层 crypto_box 完成与 Box 等价的加密
			final Uint8List m = Uint8List(message.length + Box.zerobytesLength);
			for (int i = 0; i < message.length; i++) {
				m[i + Box.zerobytesLength] = message[i];
			}
			final Uint8List c = Uint8List(m.length);
			final encRet = TweetNaclFast().crypto_box(
				c,
				m,
				m.length,
				nonce,
				kpBob.publicKey,
				kpAlice.secretKey,
			);
			expect(encRet, equals(0));
			final Uint8List cipher = Uint8List(c.length - Box.boxzerobytesLength);
			for (int i = 0; i < cipher.length; i++) {
				cipher[i] = c[i + Box.boxzerobytesLength];
			}

			// 使用底层 crypto_box_open 解密
			final Uint8List c2 = Uint8List(cipher.length + Box.boxzerobytesLength);
			for (int i = 0; i < cipher.length; i++) {
				c2[i + Box.boxzerobytesLength] = cipher[i];
			}
			final Uint8List m2 = Uint8List(c2.length);
			final decRet = TweetNaclFast().crypto_box_open(
				m2,
				c2,
				c2.length,
				nonce,
				kpAlice.publicKey,
				kpBob.secretKey,
			);
			expect(decRet, equals(0));
			final Uint8List plain = Uint8List(m2.length - Box.zerobytesLength);
			for (int i = 0; i < plain.length; i++) {
				plain[i] = m2[i + Box.zerobytesLength];
			}
			expect(String.fromCharCodes(plain), 'hello box');
		});

		test('open fails with wrong key', () {
			final kpAlice = Box.keyPair();
			final kpBob = Box.keyPair();
			final kpEve = Box.keyPair();

			final Uint8List nonce = Uint8List.fromList(List<int>.filled(24, 9));
			final Uint8List message = Uint8List.fromList([9,8,7,6,5,4,3,2,1]);

			// 加密
			final Uint8List m = Uint8List(message.length + Box.zerobytesLength);
			for (int i = 0; i < message.length; i++) {
				m[i + Box.zerobytesLength] = message[i];
			}
			final Uint8List c = Uint8List(m.length);
			final encRet = TweetNaclFast().crypto_box(
				c,
				m,
				m.length,
				nonce,
				kpBob.publicKey,
				kpAlice.secretKey,
			);
			expect(encRet, equals(0));
			final Uint8List cipher = Uint8List(c.length - Box.boxzerobytesLength);
			for (int i = 0; i < cipher.length; i++) {
				cipher[i] = c[i + Box.boxzerobytesLength];
			}

			// 用错误的密钥解密应失败
			final Uint8List c2 = Uint8List(cipher.length + Box.boxzerobytesLength);
			for (int i = 0; i < cipher.length; i++) {
				c2[i + Box.boxzerobytesLength] = cipher[i];
			}
			final Uint8List m2 = Uint8List(c2.length);
			final decRet = TweetNaclFast().crypto_box_open(
				m2,
				c2,
				c2.length,
				nonce,
				kpAlice.publicKey,
				kpEve.secretKey,
			);
			expect(decRet != 0, isTrue);
		});
	});
} 