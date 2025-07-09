import 'package:crypto_wallet_util/src/wallets/near.dart';
import 'package:test/test.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final near = await NearCoin.fromMnemonic(mnemonic);

  group('test near base58PrivateKey import', () {
    test('test', () async {
      final pkWallet = NearCoin.fromPrivateKey(near.base58PrivateKey);
      expect(near.address, pkWallet.address);
    });
  });
}
