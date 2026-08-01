import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/kas.dart';
import 'package:crypto_wallet_util/transaction.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Regression test for F9: KasTxSigner.verify() previously only checked
/// `txData.inputs.first` / `txData.messages.first`, so a tampered signature
/// on any input *after* the first went undetected. This builds a
/// two-input transaction (by duplicating the fixture's single input) and
/// confirms tampering the *second* input's signature is caught.
void main() async {
  const mnemonic =
      'fly lecture gasp juice hover ice business census bless weapon polar upgrade';
  final kas = await KasCoin.fromMnemonic(mnemonic);

  test('verify() catches a tampered second input, not just the first', () async {
    final transactionJson = json.decode(
        File('./test/transaction/data/kas.json').readAsStringSync(encoding: utf8));
    final inputs = transactionJson['transaction_kaspa']['inputs'] as List;
    // Duplicate the single fixture input so there are two inputs to sign.
    inputs.add(Map<String, dynamic>.from(inputs[0]));

    final txData = KasTxData.fromJson(transactionJson);
    final signer = KasTxSigner(kas, txData);
    signer.sign();
    expect(signer.verify(), isTrue);

    // Tamper the *second* input's signature only.
    final tampered = dynamicToUint8List(txData.inputs[1].signatureScript);
    tampered[1] ^= 0xff; // byte 0 is the 0x41 prefix; flip a signature byte
    txData.inputs[1].signatureScript = dynamicToString(tampered);

    expect(signer.verify(), isFalse);
  });
}
