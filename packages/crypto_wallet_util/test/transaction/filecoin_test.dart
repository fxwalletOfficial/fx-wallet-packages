import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/fil.dart';
import 'package:crypto_wallet_util/transaction.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final wallet = await FileCoin.fromMnemonic(mnemonic);
  test('test sign', () async {
    final transactionJson = json.decode(
        File('./test/transaction/data/filecoin.json')
            .readAsStringSync(encoding: utf8));
    final txData = FilTxData.fromJson(transactionJson);
    final signer = FilTxSigner(wallet, txData);
    final signedTxData = signer.sign();
    assert(signer.verify());
    final jsonData = signedTxData.toJson();
    final broadcastData = signedTxData.toBroadcast();
    assert(jsonData["transaction"].isNotEmpty);
    assert(broadcastData["transaction"].isNotEmpty);
  });
}
