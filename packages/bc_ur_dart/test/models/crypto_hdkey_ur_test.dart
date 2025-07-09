import 'package:bc_ur_dart/src/models/key/crypto_hdkey.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bip32/bip32.dart';
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
      expect(hdkey.wallet.toBase58(), wallet.toBase58());
      expect(hdkey.path, path);
      expect(hdkey.name, name);
    });

    test('should create from UR correctly', () {
      final code = 'UR:CRYPTO-HDKEY/ONAXHDCLAOMKGYVDNBDNBEBAAAUOTOGSETLOEEVASPBAHGPTEYNTAEROKGDTHTDSGLCMAAWMBDAAHDCXPECXAXDWAOVDSFHSATDNMYGUTPSPPEAYZEHYSTPSCKREBNIMGEBTLGSOBKPAKKWLAMTAADDYOEADLNCSDWYKCSFNYKAEYKAOCYZTVALKDYAYCYZTVALKDYASIEJTHSJNIHRPPAOTDM';

      final hdkey = CryptoHDKeyUR.fromUR(ur: UR.decode(code));

      expect(hdkey, isNotNull);
      expect(hdkey.path, "m/44'/60'/0'");
      expect(hdkey.name, 'name');
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
  });
}