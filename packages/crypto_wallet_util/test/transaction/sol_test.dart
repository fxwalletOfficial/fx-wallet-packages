import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/sol.dart';
import 'package:crypto_wallet_util/transaction.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  const String mnemonic =
      'number vapor draft title message quarter hour other hotel leave shrug donor';
  final sol = await SolCoin.fromMnemonic(mnemonic);
  test('test sign', () async {
    final transactionsJson = json.decode(
        File('./test/transaction/data/sol.json')
            .readAsStringSync(encoding: utf8));
    for (final transactionJson in transactionsJson) {
      final txData = SolTxData.fromJson(transactionJson);
      final signer = SolTxSigner(sol, txData);
      final signedTxData = signer.sign();
      final broadcastData = signedTxData.toBroadcast();
      assert(signer.verify());
      final expectedCoin = transactionJson['excepted_coin'];
      final signature = broadcastData['messageToSign']['transaction'];
      expect(signature, expectedCoin);
      if (signedTxData.initTokenAddress != null) {
        final expectedToken = transactionJson['excepted_token'];
        final signature = broadcastData['messageToSign']['initTokenAddress'];
        expect(signature, expectedToken);
      }
      final jsonData = signedTxData.toJson();
      assert(jsonData.isNotEmpty);
    }
  });
}
