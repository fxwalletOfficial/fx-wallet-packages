import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/kas.dart';
import 'package:crypto_wallet_util/transaction.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  const String mnemonic =
      'fly lecture gasp juice hover ice business census bless weapon polar upgrade';
  final kas = await KasCoin.fromMnemonic(mnemonic);
  test('test sign', () async {
    final transactionJson = json.decode(
        File('./test/transaction/data/kas.json')
            .readAsStringSync(encoding: utf8));
    final txData = KasTxData.fromJson(transactionJson);
    final signer = KasTxSigner(kas, txData);
    final signedTxData = signer.sign();
    // ignore: avoid_print
    print(signedTxData.toBroadcast());
    assert(signer.verify());
  });
}
