import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  /**
   * test common function in coin_type.  
   * (1) generate wallet
   * (2) sign message and verify signature
   */
  group('test', () {
    final jsonData = json.decode(File('./test/wallet/data/wallet.json')
        .readAsStringSync(encoding: utf8));
    // ignore: avoid_print
    print(supportCrypto().join(', '));
    for (final data in jsonData['example']) {
      final String name = data['name'];
      final String mnemonic = data['mnemonic'];
      final String private_key = data['private_key'];
      final String public_key = data['public_key'];
      final String address = data['address'];
      final String message = data['message'];
      final privateKeyWallet = getPrivateKeyWallet(name, private_key);

      late final mnemonicWallet;
      group(name, () {
        test('address', () async {
          mnemonicWallet = await getMnemonicWallet(name, mnemonic);
          expect(mnemonicWallet.address, address);
          expect(privateKeyWallet.address, address);
        });
        test('private_key', () {
          expect(dynamicToString(mnemonicWallet.privateKey), private_key);
          expect(dynamicToString(privateKeyWallet.privateKey), private_key);
        });
        test('public_key', () {
          expect(dynamicToString(mnemonicWallet.publicKey), public_key);
          expect(dynamicToString(privateKeyWallet.publicKey), public_key);
        });
        test('sign', () {
          String signedMessage = mnemonicWallet.sign(message);
          assert(mnemonicWallet.verify(signedMessage, message));
          signedMessage = privateKeyWallet.sign(message);
          assert(privateKeyWallet.verify(signedMessage, message));
        });
      });
    }
  });
}
