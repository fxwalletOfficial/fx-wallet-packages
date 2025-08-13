import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/forked_lib/tweetnacl-dart/tweetnacl.dart';

void main() {
	group('Signature', () {
		test('keyPair_fromSeed produces deterministic keys', () {
			final Uint8List seed = Uint8List.fromList(List<int>.generate(32, (i) => i));
			final kp1 = Signature.keyPair_fromSeed(seed);
			final kp2 = Signature.keyPair_fromSeed(seed);
			expect(kp1.publicKey, equals(kp2.publicKey));
			expect(kp1.secretKey, equals(kp2.secretKey));
			// 长度校验
			expect(kp1.publicKey.length, equals(Signature.publicKeyLength));
			expect(kp1.secretKey.length, equals(Signature.secretKeyLength));
		});

		test('detached sign/verify', () {
			final Uint8List seed = Uint8List.fromList(List<int>.generate(32, (i) => i * 7 % 256));
			final kp = Signature.keyPair_fromSeed(seed);
			final signer = Signature(null, kp.secretKey);
			final verifier = Signature(kp.publicKey, null);
			final Uint8List message = Uint8List.fromList('sign me please'.codeUnits);

			final Uint8List sig = signer.detached(message);
			expect(sig.length, equals(Signature.signatureLength));
			expect(verifier.detached_verify(message, sig), isTrue);

			// 修改消息应校验失败
			final Uint8List tampered = Uint8List.fromList('sign me please!'.codeUnits);
			expect(verifier.detached_verify(tampered, sig), isFalse);
		});

		test('open returns null on invalid signature', () {
			final Uint8List seed = Uint8List(32);
			final kp = Signature.keyPair_fromSeed(seed);
			final signer = Signature(null, kp.secretKey);
			final verifier = Signature(kp.publicKey, null);

			final Uint8List message = Uint8List.fromList([0,1,2,3,4,5]);
			final Uint8List signed = signer.sign(message)!;
			// 破坏签名第一个字节
			signed[0] ^= 0xFF;
			expect(verifier.open(signed), isNull);
		});
	});
} 