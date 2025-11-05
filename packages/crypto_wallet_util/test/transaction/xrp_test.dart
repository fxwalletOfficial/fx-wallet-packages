import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/xrp.dart';
import 'package:crypto_wallet_util/transaction.dart';

void main() async {
  const String mnemonic =
      'cost leave absorb violin blur crack attack pig rice glide orient employ';
  final xrp = await XrpCoin.fromMnemonic(mnemonic);

  group('test xrp signature', () {
    final transactionJson = json.decode(File('./test/transaction/data/xrp.json')
        .readAsStringSync(encoding: utf8));
    test('transaction', () async {
      final txJson = transactionJson['payment_xrp'];
      final txResult = txJson['txSignature'];
      final txData = XrpTxData.fromJson(txJson);
      final signer = XrpTxSigner(xrp, txData);
      final XrpTxData tx = signer.sign();
      expect(tx.signedBlob, txResult);
      assert(signer.verify());

      final broadcastData = tx.toBroadcast();
      assert(broadcastData.isNotEmpty);
    });

    test('token transaction', () async {
      final txJson = transactionJson['payment_token'];
      final txResult = txJson['txSignature'];
      final txData = XrpTxData.fromJson(txJson);
      final signer = XrpTxSigner(xrp, txData);
      final XrpTxData tx = signer.sign();
      expect(tx.signedBlob, txResult);
      assert(signer.verify());
    });

    test('trust set transaction', () async {
      final txJson = transactionJson['trust_set'];
      final txResult = txJson['txSignature'];
      final txData = XrpTxData.fromJson(txJson);
      final signer = XrpTxSigner(xrp, txData);
      final XrpTxData tx = signer.sign();
      expect(tx.signedBlob, txResult);
      assert(signer.verify());
    });

    test('test XrpTxData class', () {
      final txJson = transactionJson['payment_xrp'];
      final errorAmountType = ErrorAmount();
      ErrorAmount().toJson();
      final XrpTxData errorAmount = XrpTxData(
          account: txJson['Account'],
          transactionType: txJson['TransactionType'],
          sequence: txJson['Sequence'],
          fee: txJson['Fee'],
          lastLedgerSequence: txJson['LastLedgerSequence'],
          destination: txJson['Destination'],
          amount: errorAmountType);
      try {
        errorAmount.toJson();
      } catch (error) {
        assert(error.toString().contains('unsupported amount format'));
      }
      final XrpTxData errorType = XrpTxData(
          account: txJson['Account'],
          transactionType: 'error_type',
          sequence: txJson['Sequence'],
          fee: txJson['Fee'],
          lastLedgerSequence: txJson['LastLedgerSequence'],
          destination: txJson['Destination'],
          amount: XrpAmount(amount: txJson['Amount']));
      try {
        errorType.toJson();
      } catch (error) {
        assert(error.toString().contains('unsupported transaction type'));
      }
    });
  });
}

class ErrorAmount extends XrpAmountType {}
