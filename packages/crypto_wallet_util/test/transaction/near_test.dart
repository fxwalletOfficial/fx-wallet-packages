import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/near.dart';
import 'package:crypto_wallet_util/transaction.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final alph = await NearCoin.fromMnemonic(mnemonic);
  test('test transfer', () async {
    final transactionJson = json.decode(
        File('./test/transaction/data/near.json')
            .readAsStringSync(encoding: utf8));
    final txData = NearTxData.fromJson(transactionJson['transfer']);
    final signer = NearTxSigner(alph, txData);
    final signedTxData = signer.sign();
    assert(signer.verify());
    final jsonData = signedTxData.toJson();
    final broadcastData = signedTxData.toBroadcast();
    assert(jsonData.isNotEmpty);
    assert(broadcastData.isNotEmpty);
  });

  test('test token transfer', () async {
    final transactionJson = json.decode(
        File('./test/transaction/data/near.json')
            .readAsStringSync(encoding: utf8));
    final txData = NearTxData.fromJson(transactionJson['functionCall']);
    final signer = NearTxSigner(alph, txData);
    final signedTxData = signer.sign();
    assert(signer.verify());
    final broadcastData = signedTxData.toBroadcast();
    assert(broadcastData.isNotEmpty);
  });
}
