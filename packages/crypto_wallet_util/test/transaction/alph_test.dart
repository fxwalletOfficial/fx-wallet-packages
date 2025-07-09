import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/alph.dart';
import 'package:crypto_wallet_util/transaction.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

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
    // ignore: avoid_print
    print(signedTxData.toBroadcast());
    assert(signer.verify());
  });
}
