import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/utils/sr25519.dart';

/// Regression tests for F12: DOT sign()/verify() prefix inconsistency.
/// sign() strips a leading 0x9c byte before signing, but verify() checked
/// the raw (unstripped) message, so a 0x9c-prefixed message signed by this
/// same wallet failed to verify against itself.
void main() async {
  const mnemonic =
      'caution juice atom organ advance problem want pledge someone senior holiday very';
  final wallet = await DotCoin.fromMnemonic(mnemonic);

  // Real fixture message (test/wallet/data/wallet.json, "dot" entry),
  // 115 bytes / 230 hex chars — kept even-length so hex decoding can't
  // silently misalign it.
  const baseMessage =
      '0500009ea0acfa4a4b5a19c512df75afc9b1d5a9e1a1acf872018f956c8526e11efa00028907003500140041420f001800000091b171bb158e2d3848fa23a9f1c25182fb8e20313b2c1eb49219da7a70ce90c3bd44f5a7b303737a78347cc54297aec16442b91f9db5f074027d152ac4d80c68';
  const prefixedMessage = '9c$baseMessage';

  test('sign/verify round-trip for a message with the 0x9c prefix', () {
    final sig = wallet.sign(prefixedMessage);
    expect(wallet.verify(sig, prefixedMessage), isTrue);
  });

  test('sign/verify round-trip for a message without the prefix', () {
    final sig = wallet.sign(baseMessage);
    expect(wallet.verify(sig, baseMessage), isTrue);
  });

  test(
      'the signature is genuinely over the stripped message, not the raw '
      'wire bytes (documents why verify() must strip too)', () {
    final sig = wallet.sign(prefixedMessage);
    expect(SR25519.verify(wallet.publicKey, sig, prefixedMessage), isFalse);
    expect(SR25519.verify(wallet.publicKey, sig, baseMessage), isTrue);
  });

  test('verify rejects a tampered prefixed message', () {
    final sig = wallet.sign(prefixedMessage);
    final tampered = prefixedMessage.substring(0, prefixedMessage.length - 1) +
        (prefixedMessage.endsWith('0') ? '1' : '0');
    expect(wallet.verify(sig, tampered), isFalse);
  });

  test('processMessage does not throw on an empty message', () {
    expect(processMessage(<int>[]), isEmpty);
  });
}
