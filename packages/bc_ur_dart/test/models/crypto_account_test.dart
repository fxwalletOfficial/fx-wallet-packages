import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:crypto_wallet_util/crypto_utils.dart' show BIP32;
import 'package:test/test.dart';

const _canonicalXfp = '21d0ae26';
const _xpub = 'xpub6DWambFddujzpn3rhPxjGgCTB15BMSx7yoQPzDoAS7rYnputj3srC8QnRRu24qu3Q9dKytTkAGrsbLvmQD6KT2rNhFFoA3EZLpYxyJ3mNfB';

void main() {
  group('CryptoAccountUR', () {
    test('encodes and decodes account container with hdkey outputs', () {
      final wallet = BIP32.fromBase58(_xpub);
      final output = CryptoHDKeyUR.fromWallet(
        name: 'btc-native-segwit',
        path: "m/84'/0'/0'/0/0",
        wallet: wallet,
        useInfo: CryptoCoinInfo(coinType: CoinType.BTC),
      );

      final account = CryptoAccountUR.fromWallet(
        masterFingerprint: BigInt.parse(_canonicalXfp, radix: 16),
        outputs: [output],
        xfpFormat: 'canonical',
      );

      final decoded = CryptoAccountUR.fromUR(ur: account);

      expect(decoded.masterFingerprint, equals(_canonicalXfp));
      expect(decoded.outputs, hasLength(1));
      expect(decoded.outputs.single.path, equals("m/84'/0'/0'/0/0"));
      expect(decoded.outputs.single.name, equals('btc-native-segwit'));
      expect(decoded.outputs.single.publicKey, isNotNull);
      expect(decoded.hasXfpFormatMarker, isTrue);
      expect(decoded.xfpFormat, equals('canonical'));
    });

    test('rejects master fingerprint outside uint32 range', () {
      final ur = UR.fromCBOR(
        type: accountType,
        value: CborMap({
          CborSmallInt(1): CborInt(BigInt.from(0x100000000)),
          CborSmallInt(2): CborList([]),
        }),
      );

      expect(
        () => CryptoAccountUR.fromUR(ur: ur),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('crypto-account.master_fingerprint')),
        ),
      );
    });

    test('rejects non-map output entries', () {
      final ur = UR.fromCBOR(
        type: accountType,
        value: CborMap({
          CborSmallInt(1): CborInt(BigInt.from(0x21d0ae26)),
          CborSmallInt(2): CborList([CborString('not-hdkey')]),
        }),
      );

      expect(
        () => CryptoAccountUR.fromUR(ur: ur),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('crypto-account.outputs[0]')),
        ),
      );
    });
  });
}
