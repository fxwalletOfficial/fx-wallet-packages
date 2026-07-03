import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:crypto_wallet_util/crypto_utils.dart' show BIP32;
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

    test('keeps a mixed secp + non-SOL non-secp bundle without aborting import', () {
      // Regression for the real Keystone failure: keys[N] was a non-secp256k1
      // chain (not SOL), which used to throw and take down the entire bundle.
      final ur = CryptoMultiAccountsUR.fromWallet(
        masterFingerprint: BigInt.from(0x21d0ae26),
        device: 'Keystone',
        chains: [
          CryptoHDKeyUR.fromWallet(
            name: 'btc-wallet',
            path: "m/44'/0'/0'",
            wallet: BIP32.fromBase58('xpub6DWambFddujzpn3rhPxjGgCTB15BMSx7yoQPzDoAS7rYnputj3srC8QnRRu24qu3Q9dKytTkAGrsbLvmQD6KT2rNhFFoA3EZLpYxyJ3mNfB'),
          ),
          // Exotic non-secp entry (Sui coin type 784) — must be preserved, not fatal.
          CryptoHDKeyUR.fromWallet(
            name: 'sui-wallet',
            path: "m/44'/784'/0'",
            publicKey: Uint8List(33),
            chainCode: Uint8List(32),
          ),
        ],
      );

      final parsed = CryptoMultiAccountsUR.fromUR(ur: UR.decode(ur.encode()));

      expect(parsed.chains.length, 2);
      expect(parsed.chains[0].wallet, isNotNull); // secp entry still resolves to a BIP32 wallet
      expect(parsed.chains[1].wallet, isNull); // exotic non-secp entry preserved, not fatal
      expect(parsed.chains[1].publicKey, Uint8List(33));
      expect(parsed.chains[1].path, "m/44'/784'/0'");
    });
  });
}
