import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CryptoMultiAccountsUR', () {
    test('wraps invalid hdkey entries as format exceptions', () {
      final ur = CryptoMultiAccountsUR.fromWallet(
        masterFingerprint: BigInt.from(0x21d0ae26),
        device: 'FxWallet',
        walletName: 'FxWallet',
        chains: [
          CryptoHDKeyUR.fromWallet(
            name: 'invalid-wallet',
            path: "m/44'/60'/0'",
            publicKey: Uint8List(33),
            chainCode: Uint8List(32),
          ),
        ],
        xfpFormat: 'canonical',
      );

      expect(
        () => CryptoMultiAccountsUR.fromUR(ur: UR.decode(ur.encode())),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Invalid crypto-multi-accounts key entry at index 0'),
          ),
        ),
      );
    });
  });
}
