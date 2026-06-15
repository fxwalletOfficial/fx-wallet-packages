import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CryptoMultiAccountsUR', () {
    test(
        'preserves non secp256k1 hdkey entries without rejecting the account set',
        () {
      final ur = CryptoMultiAccountsUR.fromWallet(
        masterFingerprint: BigInt.from(0x21d0ae26),
        device: 'FxWallet',
        walletName: 'FxWallet',
        chains: [
          CryptoHDKeyUR.fromWallet(
            name: 'sol-wallet',
            path: "m/44'/501'/0'",
            publicKey: Uint8List(33),
            chainCode: Uint8List(32),
          ),
        ],
        xfpFormat: 'canonical',
      );

      final parsed = CryptoMultiAccountsUR.fromUR(ur: UR.decode(ur.encode()));
      final chain = parsed.chains.single;

      expect(chain.wallet, isNull);
      expect(chain.publicKey, Uint8List(33));
      expect(chain.chainCode, Uint8List(32));
      expect(chain.path, "m/44'/501'/0'");
    });
  });
}
