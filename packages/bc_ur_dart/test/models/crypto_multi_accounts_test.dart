import 'dart:typed_data';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:test/test.dart';

void main() {
  group('CryptoMultiAccountsUR', () {
    test('preserves non secp256k1 hdkey entries without rejecting the account set', () {
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

    test('rejects missing chains list with explicit CBOR error', () {
      final ur = UR.fromCBOR(
        type: mtiType,
        value: CborMap({
          CborSmallInt(1): CborInt(BigInt.from(0x21d0ae26)),
        }),
      );

      expect(
        () => CryptoMultiAccountsUR.fromUR(ur: ur),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('crypto-multi-accounts.keys')),
        ),
      );
    });

    test('wraps malformed nested hdkey entry with entry index', () {
      final ur = UR.fromCBOR(
        type: mtiType,
        value: CborMap({
          CborSmallInt(1): CborInt(BigInt.from(0x21d0ae26)),
          CborSmallInt(2): CborList([
            CborMap({
              CborSmallInt(6): CborMap({
                CborSmallInt(1): CborList(getPath("m/44'/60'/0'")),
              }, tags: [
                304
              ]),
            }),
          ]),
        }),
      );

      expect(
        () => CryptoMultiAccountsUR.fromUR(ur: ur),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('crypto-multi-accounts.keys[0]')),
        ),
      );
    });
  });
}
