import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';

void main() async {
  final transactions = json
      .decode(File('./test/psbt/data.json').readAsStringSync(encoding: utf8));
  group('psbt', () {
    for (final transactionJson in transactions) {
      test('test sign', () async {
        final txData = transactionJson['data'];
        final BtcTransferInfo tx = BtcTransferInfo.fromJson(txData);
        final psbt = PSBTSigner.serializeTxToPsbtData(tx);

        expect(psbt, transactionJson["psbt"]);

        final psbtSinger = PSBTSigner(transactionJson["hd_signature"], tx);
        String signature = psbtSinger.sign();

        expect(signature, transactionJson["fl_signature"]);
      });

      test('test psbt to transaction conversion', () async {
        final psbtHex = transactionJson['psbt'];
        final psbtTxData = PsbtTxData.fromHash(psbtHex);

        final tx = psbtTxData.psbt.unsignedTransaction!;
        final originTx = transactionJson['data']['origin'];

        // test basic info
        expect(tx.inputs.length, originTx['inputs'].length);
        expect(tx.outputs.length, originTx['outputs'].length);

        for (var i = 0; i < tx.outputs.length; i++) {
          var output = tx.outputs[i];
          var targetAmount = originTx['outputs'][i]['amount'];
          expect(output.amount, (targetAmount * 100000000).toInt());

          String targetAddress = originTx['outputs'][i]['address'];
          expect(output.getAddress(), targetAddress);
        }

        // test fee
        final originData = transactionJson['data']['origin'];
        final expectedFee = (originData['fee'] * 100000000).round();
        expect(psbtTxData.fee, expectedFee);

        // test transfer amount
        final jsonData = psbtTxData.toJson();
        assert(jsonData.isNotEmpty);
      });
    }
  });
}
