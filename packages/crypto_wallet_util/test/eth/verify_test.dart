import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/utils.dart';

/// Regression tests for F7 (EthTxSigner.verify() misinterpreted `v` for
/// typed transactions) and F8 (isValidEthSignature rejected legitimate
/// short r/s encodings and allowed r/s == curve order n).
void main() {
  const privateKey =
      '3c9229289a6125f7fdf1885a77bb12c37a8d3b4962d936f7e3084dece32a3ca1';
  final wallet = EthCoin.fromPrivateKey(privateKey);
  final txNetwork = TxNetwork(chainId: 1);

  EthTxDataRaw freshTxData() => EthTxDataRaw(
        nonce: 0,
        gasLimit: 21000,
        value: BigInt.from(10),
        to: '0x1234567890abcdef',
      );

  group('F7: EthTxSigner.verify() for typed transactions', () {
    test('accepts a genuine EIP-1559 signature', () {
      final tx = Eip1559TxData(data: freshTxData(), network: txNetwork);
      final signer = EthTxSigner(wallet, tx);
      signer.sign();
      expect(signer.verify(), isTrue);
    });

    test('accepts a genuine legacy (EIP-155) signature', () {
      final tx = LegacyTxData(data: freshTxData(), network: txNetwork);
      final signer = EthTxSigner(wallet, tx);
      signer.sign();
      expect(signer.verify(), isTrue);
    });

    test('rejects an EIP-1559 signature tampered after signing (wrong s)', () {
      final tx = Eip1559TxData(data: freshTxData(), network: txNetwork);
      final signer = EthTxSigner(wallet, tx);
      signer.sign();
      tx.data.s = tx.data.s! ^ BigInt.one;
      expect(signer.verify(), isFalse);
    });

    test('rejects an EIP-1559 signature with the wrong y-parity bit', () {
      final tx = Eip1559TxData(data: freshTxData(), network: txNetwork);
      final signer = EthTxSigner(wallet, tx);
      signer.sign();
      tx.data.v = tx.data.v == 0 ? 1 : 0;
      expect(signer.verify(), isFalse);
    });
  });

  group('F8: isValidEthSignature scalar bounds', () {
    final n = hexToBigInt(
        'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141');

    test('accepts r/s whose shortest encoding is under 32 bytes', () {
      // 31-byte value: top byte is non-zero (0x11), so its shortest
      // big-endian encoding is exactly 31 bytes, not 32.
      final short = hexToBigInt('11' * 31);
      expect(encodeBigInt(short).length, 31);

      final valid = EcdaSignature.isValidEthSignature(
          short, short, 0,
          chainId: 1, vIsBareRecoveryId: true);
      expect(valid, isTrue);
    });

    test('rejects r == n and s == n', () {
      expect(
        EcdaSignature.isValidEthSignature(n, BigInt.one, 0,
            chainId: 1, vIsBareRecoveryId: true),
        isFalse,
      );
      expect(
        EcdaSignature.isValidEthSignature(BigInt.one, n, 0,
            chainId: 1, vIsBareRecoveryId: true),
        isFalse,
      );
    });

    test('rejects r == 0 and s == 0', () {
      expect(
        EcdaSignature.isValidEthSignature(BigInt.zero, BigInt.one, 0,
            chainId: 1, vIsBareRecoveryId: true),
        isFalse,
      );
      expect(
        EcdaSignature.isValidEthSignature(BigInt.one, BigInt.zero, 0,
            chainId: 1, vIsBareRecoveryId: true),
        isFalse,
      );
    });

    test('accepts r/s == n - 1 (largest valid scalar)', () {
      final nMinus1 = n - BigInt.one;
      // s must additionally be <= n/2 for the homestead low-S rule; use a
      // small s here so only the r boundary is under test.
      final valid = EcdaSignature.isValidEthSignature(
          nMinus1, BigInt.one, 0,
          chainId: 1, vIsBareRecoveryId: true);
      expect(valid, isTrue);
    });
  });
}
