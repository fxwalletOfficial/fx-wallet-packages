import 'package:bc_ur_dart/src/models/key/crypto_hdkey.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:bip32/bip32.dart';
import 'package:test/test.dart';

void main() {
  final code = 'UR:CRYPTO-HDKEY/ONAXHDCLAOMKGYVDNBDNBEBAAAUOTOGSETLOEEVASPBAHGPTEYNTAEROKGDTHTDSGLCMAAWMBDAAHDCXPECXAXDWAOVDSFHSATDNMYGUTPSPPEAYZEHYSTPSCKREBNIMGEBTLGSOBKPAKKWLAMTAADDYOEADLNCSDWYKCSFNYKAEYKAOCYZTVALKDYAYCYZTVALKDYASIEJTHSJNIHRPPAOTDM';
  final path = "m/44'/60'/0'";
  final name = 'name';
  final wallet = BIP32.fromBase58('xpub6DWambFddujzpn3rhPxjGgCTB15BMSx7yoQPzDoAS7rYnputj3srC8QnRRu24qu3Q9dKytTkAGrsbLvmQD6KT2rNhFFoA3EZLpYxyJ3mNfB');

  test('Crypto hdkey encode', () {
    final ur = CryptoHDKeyUR.fromWallet(name: name, path: path, wallet: wallet);

    expect(ur.encode(), code);
  });

  test('Crypto hdkey decode', () {
    final ur = CryptoHDKeyUR.fromUR(ur: UR.decode(code));

    expect(ur.wallet.toBase58(), wallet.toBase58());
    expect(ur.path, ur.path);
    expect(ur.name, name);
  });
}
