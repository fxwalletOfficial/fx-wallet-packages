import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/utils/bip32/src/utils/ecpair.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/utils/script.dart'
    show toXOnly;
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Regression tests for F4: `ECPair.signSchnorr()` and `ECPair.ToTweak()`
/// encoded BIP340 coordinates/scalars (`t`, `P.x`, `R.x`, final `s`, and the
/// tweaked private key) with the shortest big-endian encoding instead of a
/// fixed 32 bytes. Whenever one of those values had a leading zero byte,
/// this silently shortened the value fed into a tagged hash (changing the
/// nonce/challenge) or produced a signature/private key shorter than 32
/// bytes, which `ECPair.fromPrivateKey` then rejected outright.
///
/// Verification uses the independent `bip340` package (via [Schnorr]), not
/// `ECPair.verify()` — that method calls the ECDSA verifier on a Schnorr
/// signature and is unrelated to this fix.
void main() {
  final priv = fromHex(
    '64a0d0de1e0ad3b371476db54c85ef374695137aee3af3f2766dfa81e55877cb',
  );
  final kp = ECPair.fromPrivateKey(priv);
  final xOnlyPubkey = toXOnly(kp.publicKey!);

  bool verifiesIndependently(Uint8List message, Uint8List sig) {
    return Schnorr.verify(
      xOnlyPubkey,
      dynamicToString(sig),
      dynamicToString(message),
    );
  }

  group('signSchnorr() fixed-width output', () {
    test('always returns exactly 64 bytes and verifies, for a normal message',
        () {
      final message = fromHex(
        'deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
      );
      final sig = kp.signSchnorr(message: message, aux: '00' * 32);
      expect(sig.length, 64);
      expect(verifiesIndependently(message, sig), isTrue);
    });

    test(
        'pads a coordinate/scalar with a leading zero byte to 32 bytes '
        'instead of producing a short signature', () {
      // With aux='00'*32, this message deterministically produces at least
      // one of {t, P.x, R.x, s} with a leading zero byte (31-byte shortest
      // encoding) under the pre-fix `bigToBytes` (no padding) code path.
      final message = fromHex(
        '2a74f75553e1cc08471ccc59fc9dbb89eb27ffa93a6a1b7c0fab526dfa8a7989',
      );
      final sig = kp.signSchnorr(message: message, aux: '00' * 32);

      expect(sig.length, 64);
      expect(verifiesIndependently(message, sig), isTrue);
    });
  });

  group('ToTweak() fixed-width private key output', () {
    test('always returns a 32-byte tweaked private key', () {
      final tweaked = kp.ToTweak();
      expect(tweaked.privateKey!.length, 32);
    });

    test('pads a tweaked private key with a leading zero instead of '
        'throwing "Expected property privateKey of type Buffer(Length: 32)"',
        () {
      // This private key's tweak sum has a shortest big-endian encoding of
      // 31 bytes under the pre-fix `bigToBytes` (no padding) code path.
      final leadingZeroTweakPriv = fromHex(
        'fd4962a79b4a49424cb86ba38502a21b8a79f1fe705775c92ad64165dd50868e',
      );
      final leadingZeroKp = ECPair.fromPrivateKey(leadingZeroTweakPriv);

      final tweaked = leadingZeroKp.ToTweak();
      expect(tweaked.privateKey!.length, 32);
    });
  });
}
