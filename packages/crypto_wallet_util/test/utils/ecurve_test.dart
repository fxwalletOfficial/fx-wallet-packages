import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/ecurve.dart'
    as ecc;
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Regression tests for F1: `sign()` used to write the shortest big-endian
/// encoding of `s` straight into a fixed 32-byte window without padding
/// (unlike `r`, which was padded). Whenever the low-S normalized `s` needed
/// only 31 bytes, `Uint8List.setRange` threw `Bad state: Too few elements`
/// and the signing pipeline crashed. `r` was already padded, but is covered
/// here too so both fields stay pinned.
void main() {
  final priv = fromHex(
    '64a0d0de1e0ad3b371476db54c85ef374695137aee3af3f2766dfa81e55877cb',
  );

  group('sign() fixed-width output', () {
    test('always returns exactly 64 bytes for a normal hash', () {
      final hash = fromHex(
        'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
      );
      final sig = ecc.sign(hash, priv);
      expect(sig.length, 64);
      expect(ecc.isSignature(sig), isTrue);
    });

    test('pads a 31-byte low-S value to 32 bytes instead of throwing', () {
      // Deterministically produces an ECDSA `s` whose shortest big-endian
      // encoding (after low-S normalization) is 31 bytes.
      final hash = fromHex(
        '482f455477d9fa22134c3c6567754b04994434a130e7dcc351557cd53efb3534',
      );
      final sig = ecc.sign(hash, priv);

      expect(sig.length, 64);
      // The s-half's top byte must be the explicit zero pad byte.
      expect(sig[32], 0);
      expect(ecc.isSignature(sig), isTrue);

      final pub = ecc.pointFromScalar(priv, true)!;
      expect(ecc.verify(hash, pub, sig), isTrue);
    });

    test('pads a 31-byte r value to 32 bytes instead of throwing', () {
      final hash = fromHex(
        'c2bb2b5e16be11d0f07e476d67fc7948ed1dbd1729d408fa305289cc56e10e9c',
      );
      final sig = ecc.sign(hash, priv);

      expect(sig.length, 64);
      expect(sig[0], 0);
      expect(ecc.isSignature(sig), isTrue);

      final pub = ecc.pointFromScalar(priv, true)!;
      expect(ecc.verify(hash, pub, sig), isTrue);
    });
  });

  group('isSignature() boundary checks', () {
    Uint8List sigOf(Uint8List r, Uint8List s) =>
        Uint8List.fromList([...r, ...s]);

    test('rejects wrong length before slicing', () {
      expect(ecc.isSignature(Uint8List(63)), isFalse);
      expect(ecc.isSignature(Uint8List(65)), isFalse);
      expect(ecc.isSignature(Uint8List(0)), isFalse);
    });

    test('rejects zero r or s', () {
      final one = encodeBigIntBe(BigInt.one, length: 32);
      final zero = encodeBigIntBe(BigInt.zero, length: 32);
      expect(ecc.isSignature(sigOf(zero, one)), isFalse);
      expect(ecc.isSignature(sigOf(one, zero)), isFalse);
    });

    test('rejects r or s == curve order n', () {
      final one = encodeBigIntBe(BigInt.one, length: 32);
      final nBytes = encodeBigIntBe(ecc.n, length: 32);
      expect(ecc.isSignature(sigOf(nBytes, one)), isFalse);
      expect(ecc.isSignature(sigOf(one, nBytes)), isFalse);
    });

    test('accepts a valid 64-byte signature', () {
      final one = encodeBigIntBe(BigInt.one, length: 32);
      final two = encodeBigIntBe(BigInt.two, length: 32);
      expect(ecc.isSignature(sigOf(one, two)), isTrue);
    });
  });
}
