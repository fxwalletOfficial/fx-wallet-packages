import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final legacyWallet = await BtcCoin.fromMnemonic(mnemonic);
  final taprootWallet = await BtcCoin.fromMnemonic(mnemonic, null, true);

  final psbtJson = json
      .decode(File('./test/psbt/data.json').readAsStringSync(encoding: utf8));

  final legacyUnsignedPsbt = psbtJson[0]['psbt'];
  final taprootUnsignedPsbt = psbtJson[1]['psbt'];

  group('test psbt tx signer', () {
    test('legacy signature generation', () {
      // Create PSBT transaction data and signer
      final psbtTxData =
          PsbtTxData.fromHash(legacyUnsignedPsbt, isTaproot: false);

      final signer = PsbtTxSigner(legacyWallet, psbtTxData);

      // Sign the transaction
      final signedTxData = signer.sign();

      // Verify signatures were added
      expect(signer.verify(), isTrue);

      print('Signed PSBT: ${signedTxData.psbt.serialize()}');
      print('Signed Tx Hex: ${signedTxData.getSignedTxHex()}');
    });

    test('taproot signature generation', () {
      // Create PSBT transaction data and signer
      final psbtTxData =
          PsbtTxData.fromHash(taprootUnsignedPsbt, isTaproot: true);
      final signer = PsbtTxSigner(taprootWallet, psbtTxData);

      // Sign the transaction
      final signedTxData = signer.sign();

      // Verify signatures were added
      expect(signer.verify(), isTrue);

      print('Signed PSBT: ${signedTxData.psbt.serialize()}');
      print('Signed Tx Hex: ${signedTxData.getSignedTxHex()}');
    });
  });

  test('psbt to origin', () {
    final psbtTxData =
        PsbtTxData.fromHash(taprootUnsignedPsbt, isTaproot: true);
    final originTx = psbtTxData.origin;
    final originData = psbtJson[1]['data']['origin'];
    // compare origin data
    // expect(originTx.version, originData['version']);
    expect(originTx.locktime, originData['locktime']);
    for (var i = 0; i < originTx.inputs.length; i++) {
      expect(originTx.inputs[i].prevout.hash,
          originData['inputs'][i]['prevout']['hash']);
      expect(originTx.inputs[i].prevout.index,
          originData['inputs'][i]['prevout']['index']);
      expect(originTx.inputs[i].coin.value,
          originData['inputs'][i]['coin']['value']);
      expect(originTx.inputs[i].coin.address,
          originData['inputs'][i]['coin']['address']);
    }
    for (var i = 0; i < originTx.outputs.length; i++) {
      expect(originTx.outputs[i].amount, originData['outputs'][i]['amount']);
      expect(originTx.outputs[i].address, originData['outputs'][i]['address']);
    }
  });

  test('psbt tx signer == psbt signer', () {
    for (final transactionJson in psbtJson) {
      final signedPsbt = transactionJson['hd_signature'];
      final txHash = transactionJson['fl_signature'];
      final txType = transactionJson['data']['txType'];

      final psbtTxData = PsbtTxData.fromHash(signedPsbt,
          isTaproot: txType == 'TxType.TAPROOT');
      psbtTxData.isSigned = true;
      final signature = psbtTxData.getSignedTxHex();

      // expect(signaturePsbt, signature);
      expect(signature, txHash);
    }
  });
}
