import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/algo.dart';
import 'package:crypto_wallet_util/transaction.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final algo = await AlgoCoin.fromMnemonic(mnemonic);
  test('test sign', () async {
    final transactionJson = json.decode(
        File('./test/transaction/data/algo.json')
            .readAsStringSync(encoding: utf8));
    final txData = AlgoTxData.fromJson(transactionJson);
    final signer = AlgoTxSigner(algo, txData);
    final signedTxData = signer.sign();
    final broadcastData = signedTxData.toBroadcast();
    final jsonData = signedTxData.toJson();
    expect(broadcastData['signature'], jsonData['signature']);
    assert(signer.verify());
  });
}
