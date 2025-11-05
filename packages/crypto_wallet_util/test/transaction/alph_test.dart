import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/alph.dart';
import 'package:crypto_wallet_util/transaction.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final alph = await AlphCoin.fromMnemonic(mnemonic);
  test('test sign', () async {
    final transactionJson = json.decode(
        File('./test/transaction/data/alph.json')
            .readAsStringSync(encoding: utf8));
    final txData = AlphTxData.fromJson(transactionJson);
    final signer = AlphTxSigner(alph, txData);
    final signedTxData = signer.sign();
    final broadcastData = signedTxData.toBroadcast();
    final jsonData = signedTxData.toJson();
    expect(broadcastData['signature'], jsonData['signature']);
    assert(signer.verify());
  });
}
