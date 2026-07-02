import 'dart:typed_data';

import 'package:bc_ur_dart/src/models/key/crypto_coin_info.dart';
import 'package:bc_ur_dart/src/models/key/crypto_hdkey.dart';
import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bc_ur_dart/src/utils/error.dart';
import 'package:bc_ur_dart/src/utils/utils.dart';
import 'package:cbor/cbor.dart';
import 'package:crypto_wallet_util/crypto_utils.dart' show BIP32;
import 'package:test/test.dart';

void main() {
  group('CryptoHDKeyUR', () {
    test('should create from wallet correctly', () {
      final wallet = BIP32.fromBase58('xpub6DWambFddujzpn3rhPxjGgCTB15BMSx7yoQPzDoAS7rYnputj3srC8QnRRu24qu3Q9dKytTkAGrsbLvmQD6KT2rNhFFoA3EZLpYxyJ3mNfB');
      final path = "m/44'/60'/0'";
      final name = 'test-wallet';

      final hdkey = CryptoHDKeyUR.fromWallet(
        name: name,
        path: path,
        wallet: wallet,
      );

      expect(hdkey, isNotNull);
      expect(hdkey.wallet!.toBase58(), wallet.toBase58());
      expect(hdkey.path, path);
      expect(hdkey.name, name);
      expect(hdkey.hasXfpFormatMarker, isFalse);
    });

    test('should create from UR correctly', () {
      final code =
          'UR:CRYPTO-HDKEY/ONAXHDCLAOMKGYVDNBDNBEBAAAUOTOGSETLOEEVASPBAHGPTEYNTAEROKGDTHTDSGLCMAAWMBDAAHDCXPECXAXDWAOVDSFHSATDNMYGUTPSPPEAYZEHYSTPSCKREBNIMGEBTLGSOBKPAKKWLAMTAADDYOEADLNCSDWYKCSFNYKAEYKAOCYZTVALKDYAYCYZTVALKDYASIEJTHSJNIHRPPAOTDM';

      final hdkey = CryptoHDKeyUR.fromUR(ur: UR.decode(code));

      expect(hdkey, isNotNull);
      expect(hdkey.path, "m/44'/60'/0'");
      expect(hdkey.name, 'name');
      expect(hdkey.xfpFormat, 'canonical');
      expect(hdkey.hasXfpFormatMarker, isFalse);
    });

    test('should encode to UR correctly', () {
      final wallet = BIP32.fromBase58('xpub6DWambFddujzpn3rhPxjGgCTB15BMSx7yoQPzDoAS7rYnputj3srC8QnRRu24qu3Q9dKytTkAGrsbLvmQD6KT2rNhFFoA3EZLpYxyJ3mNfB');
      final path = "m/44'/60'/0'";
      final name = 'test-wallet';

      final hdkey = CryptoHDKeyUR.fromWallet(
        name: name,
        path: path,
        wallet: wallet,
      );

      final urString = hdkey.encode();

      expect(urString, startsWith('UR:CRYPTO-HDKEY/'));
      expect(urString, isNotEmpty);
    });

    test('should preserve non secp256k1 public keys with chain code', () {
      final ur = CryptoHDKeyUR.fromWallet(
        name: 'ed25519-wallet',
        path: "m/44'/501'/0'",
        publicKey: Uint8List(33),
        chainCode: Uint8List(32),
      );

      final parsed = CryptoHDKeyUR.fromUR(ur: UR.decode(ur.encode()));

      expect(parsed.wallet, isNull);
      expect(parsed.publicKey, Uint8List(33));
      expect(parsed.chainCode, Uint8List(32));
      expect(parsed.path, "m/44'/501'/0'");
    });

    test('should reject malformed secp256k1 public keys with chain code', () {
      final ur = UR.fromCBOR(
        type: RegistryType.CRYPTO_HDKEY.type,
        value: CborMap({
          CborSmallInt(3): CborBytes(Uint8List(33)),
          CborSmallInt(4): CborBytes(Uint8List(32)),
          CborSmallInt(5): CryptoCoinInfo(
            coinType: CoinType.BTC,
            network: CoinType.MAINNET,
          ).toCborValue(),
          CborSmallInt(6): CborMap({
            CborSmallInt(1): CborList(getPath("m/44'/0'/0'")),
          }, tags: [
            304
          ]),
          CborSmallInt(9): CborString('bad-btc-wallet'),
        }),
      );

      expect(
        () => CryptoHDKeyUR.fromUR(ur: ur),
        throwsA(isA<FormatException>()),
      );
    });

    test('toString should keep empty keys and JSON escape note', () {
      final hdkey = CryptoHDKeyUR.fromWallet(
        name: '',
        path: "m/44'/501'/0'",
        publicKey: Uint8List(33),
        chainCode: Uint8List(32),
        note: 'line "one"\\two',
      );

      final parsed = CryptoHDKeyUR.fromUR(ur: UR.decode(hdkey.encode()));
      final text = parsed.toString();

      expect(text, contains('"name":""'));
      expect(text, contains('"note":"line \\"one\\"\\\\two"'));
      expect(text, contains('"childrenPath":""'));
    });

    test('should preserve xfp format marker', () {
      final wallet = BIP32.fromBase58('xpub6DWambFddujzpn3rhPxjGgCTB15BMSx7yoQPzDoAS7rYnputj3srC8QnRRu24qu3Q9dKytTkAGrsbLvmQD6KT2rNhFFoA3EZLpYxyJ3mNfB');
      final hdkey = CryptoHDKeyUR.fromWallet(
        name: 'test-wallet',
        path: "m/44'/60'/0'",
        wallet: wallet,
        xfpFormat: 'canonical',
      );

      final parsed = CryptoHDKeyUR.fromUR(ur: UR.decode(hdkey.encode()));

      expect(hdkey.hasXfpFormatMarker, isTrue);
      expect(parsed.xfpFormat, 'canonical');
      expect(parsed.hasXfpFormatMarker, isTrue);
    });

    test('rejects missing required public key with explicit CBOR error', () {
      final ur = UR.fromCBOR(
        type: RegistryType.CRYPTO_HDKEY.type,
        value: CborMap({
          CborSmallInt(6): CborMap({
            CborSmallInt(1): CborList(getPath("m/44'/60'/0'")),
          }, tags: [
            304
          ]),
        }),
      );

      expect(
        () => CryptoHDKeyUR.fromUR(ur: ur),
        throwsA(
          isA<InvalidCborURException>().having((e) => e.message, 'message', contains('crypto-hdkey.public_key')),
        ),
      );
    });

    test('skips malformed optional use_info when present', () {
      final ur = CryptoHDKeyUR.fromWallet(
        name: 'bad-use-info',
        path: "m/44'/501'/0'",
        publicKey: Uint8List(33),
        chainCode: Uint8List(32),
      );
      final map = ur.decodeCBOR() as CborMap;
      map[CborSmallInt(5)] = CborString('not-coin-info');

      final parsed = CryptoHDKeyUR.fromUR(
        ur: UR.fromCBOR(type: RegistryType.CRYPTO_HDKEY.type, value: map),
      );

      expect(parsed.useInfo, isNull);
      expect(parsed.path, "m/44'/501'/0'");
    });

    test('skips malformed optional children path when present', () {
      final ur = CryptoHDKeyUR.fromWallet(
        name: 'bad-children',
        path: "m/44'/501'/0'",
        publicKey: Uint8List(33),
        chainCode: Uint8List(32),
      );
      final map = ur.decodeCBOR() as CborMap;
      map[CborSmallInt(7)] = CborString('not-keypath');

      final parsed = CryptoHDKeyUR.fromUR(
        ur: UR.fromCBOR(type: RegistryType.CRYPTO_HDKEY.type, value: map),
      );

      expect(parsed.childrenPath, isNull);
      expect(parsed.path, "m/44'/501'/0'");
    });
  });
}
