import 'package:crypto_wallet_util/src/wallets/icp.dart';
import 'package:test/test.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final wallet = await IcpCoin.fromMnemonic(mnemonic);
  final message =
      "e1de639fbc3ad565b5e1b9060e50ecb87d74e9c7a0935bc828d4d81c9ff49ec5";
  group('test icp ', () {
    final exceptPrincipal =
        '6klka-3nfza-fg422-cjlid-lbe6o-jnw3i-dasqq-lk4xg-373q4-djsih-3qe';
    test('principal', () async {
      expect(wallet.principal!.toText(), exceptPrincipal);
    });

    // test('pem to private key', () async {
    //   final path = './test/data/test.pem';
    //   final pem = await IcpPem.readPemFile(path);
    //   final privateKey = pem.getEcPrivateKey();
    //   expect(privateKey, wallet.privateKey);
    // });

    test('sign', () async {
      final target =
          "af900dc14e829ba28c588152a759e9be151803a167d6f1c630777d057c225b0d4d1c1bec88d468ca9b668fe9490221c885c220f54790b1a35fefd1bc61c28a8e";

      final signature = wallet.sign(message);
      expect(signature, target);
    });
    test('stoic private key wallet', () async {
      final privateKey =
          "f4867c4aa3b154f05f185f46257c3233e05ee0651a205e09b4c64e1d1ab213a9";
      final stoicWallet =
          IcpCoin.fromPrivateKey(privateKey, null, IcpWalletType.stoic);
      final exceptPrincipal =
          'ksypc-qy7kq-u5kbq-5o7dh-yilab-ziagq-kmgbd-xmidk-riyzn-rfytu-yae';
      final exceptAddress =
          'ea51d00ce4616c53d1fd9e4aae3a6e67dafea33f5dcda80a54e805b21c046e8c';
      expect(stoicWallet.address, exceptAddress);
      expect(stoicWallet.principal!.toText(), exceptPrincipal);
      final signature = stoicWallet.sign(message);
      final targetSignature =
          '7d18b48f8c007aa63c7f334f60cd59f16c3eb298d7584de76cdbe85531100fea2a64dfeef583d73762f5f6624916d5d91baf3f41157d0d7b2afe6c323296f404';
      expect(signature, targetSignature);
    });
  });
}
