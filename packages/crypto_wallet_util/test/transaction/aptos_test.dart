import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/aptos.dart';
import 'package:crypto_wallet_util/transaction.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final wallet = await AptosCoin.fromMnemonic(mnemonic);
  test('test transfer', () async {
    final transactionJson = json.decode(
        File('./test/transaction/data/aptos.json')
            .readAsStringSync(encoding: utf8));
    final txData = AptosTxData.fromJson(transactionJson);
    final signer = AptosTxSigner(wallet, txData);
    final signedTxData = signer.sign();
    final broadcastData = signedTxData.toBroadcast();
    final jsonData = signedTxData.toJson();
    expect(broadcastData['rawPublicKey'], jsonData['rawPublicKey']);
    assert(signer.verify());
  });
}
