import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/utils.dart';
import 'package:test/test.dart';

/// Regression coverage for the raw-ECDSA fixed-width encoding defect (F1).
///
/// `DogeCoin.sign()` calls `ecurve.sign()` directly. That function used to
/// copy the *shortest* big-endian encoding of `s` into a fixed 32-byte
/// window, so any signature whose low-S value happened to fit in 31 bytes
/// threw `Bad state: Too few elements` before a transaction could be built.
///
/// Low-S normalisation reduces `s` into [1, n/2], which doubles the chance
/// of a leading zero byte compared to an un-normalised scalar: roughly 1 in
/// 128 signatures, not 1 in 256. A transaction signs once per input, so a
/// multi-input transaction (splitting or consolidating UTXOs) hit this far
/// more often than a single-input send.
void main() {
  // Found by scanning digests against this key: its low-S value encodes to
  // 31 bytes, which is exactly the case that used to throw.
  const shortSPrivateKey =
      '1111111111111111111111111111111111111111111111111111111111111111';
  const shortSDigest =
      '4238d6f99d0894490928b04b057d2144f197ef83cf45bd23c1a03f0e6d65848b';

  group('DOGE raw ECDSA fixed-width encoding', () {
    final wallet = DogeCoin.fromPrivateKey(shortSPrivateKey);

    test('signs a digest whose low-S value needs only 31 bytes', () {
      final signature = wallet.sign(shortSDigest);

      expect(wallet.verify(signature, shortSDigest), isTrue);
    });

    test('leaves the leading zero byte of a 31-byte s in place', () {
      final signature = wallet.sign(shortSDigest);
      final der = dynamicToUint8List(signature);

      // DER: 30 <len> 02 <rLen> <r...> 02 <sLen> <s...> <sighash>
      final rLength = der[3];
      final sLength = der[5 + rLength];
      final s = der.sublist(6 + rLength, 6 + rLength + sLength);

      // The scalar really is short — this is the input that used to throw,
      // not a case that silently stopped reproducing.
      expect(s.first, isNot(0),
          reason: 'DER strips the padding again; s should be 31 significant bytes');
      expect(sLength, 31);
    });

    test('signs every digest across a range that contains short scalars', () {
      // A split transaction signs once per input; one throw aborts the whole
      // transaction, so the property that matters is "never throws", not
      // "usually works".
      var shortScalars = 0;

      for (var i = 0; i < 512; i++) {
        final digest = sha256FromUTF8('fx-wallet-doge-probe-$i');
        final signature = wallet.sign(digest);

        expect(wallet.verify(signature, digest), isTrue);

        final der = dynamicToUint8List(signature);
        final rLength = der[3];
        if (der[5 + rLength] == 31) shortScalars++;
      }

      expect(shortScalars, greaterThan(0),
          reason: 'the sample must actually exercise the 31-byte s path');
    });
  });
}
