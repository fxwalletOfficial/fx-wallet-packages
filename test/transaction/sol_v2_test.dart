import 'dart:io';

import 'package:crypto_wallet_util/transaction.dart';
import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  test('test sign', () async {
    final transactionsJson = json.decode(
        File('./test/transaction/data/sol_v2.json')
            .readAsStringSync(encoding: utf8));
    final transactionData = transactionsJson["transaction"];

    final target = transactionsJson['message'];
    
    final solTx = SolanaTransaction.fromBase64(transactionData);
    final message = base64.decode(solTx.message.toString()).toStr();

    expect(message, target);
  });
}
