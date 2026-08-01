import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';

/// Regression tests for F9: BtcCoin/LtcCoin.verify() previously either
/// always returned `true` (BTC) or checked the Schnorr signature against
/// the *untweaked* internal public key (LTC and, once BTC's stub was
/// removed, BTC too). A P2TR key-path signature verifies against the
/// tweaked output key committed to by the address — using the internal key
/// makes verify() reject every genuine signature.
void main() {
  const mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  const message =
      '38e5964a21983da4361f4cffc0e73b94c9e3bc7d8d582f12eec64a38e0b1b4dc';

  test('BtcCoin taproot: verify() accepts a genuine signature', () async {
    final wallet = await BtcCoin.fromMnemonic(mnemonic, null, true);
    final sig = wallet.sign(message);
    expect(wallet.verify(sig, message), isTrue);
  });

  test('BtcCoin taproot: verify() rejects a tampered signature', () async {
    final wallet = await BtcCoin.fromMnemonic(mnemonic, null, true);
    final sig = wallet.sign(message);
    final bytes = Uint8List.fromList(
        List<int>.generate(sig.length ~/ 2, (i) => int.parse(sig.substring(i * 2, i * 2 + 2), radix: 16)));
    bytes[0] ^= 0xff;
    final tampered =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(wallet.verify(tampered, message), isFalse);
  });

  test('LtcCoin taproot: verify() accepts a genuine signature', () async {
    final wallet = await LtcCoin.fromMnemonic(mnemonic, null, true);
    final sig = wallet.sign(message);
    expect(wallet.verify(sig, message), isTrue);
  });
}
