import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/aptos.dart';
import 'package:crypto_wallet_util/transaction.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

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
    // ignore: avoid_print
    print(jsonEncode(signedTxData.toBroadcast()));
    assert(signer.verify());
  });
}
