import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:bs58check/bs58check.dart';
import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/script_public_key.dart'
    as psbt;
import 'package:crypto_wallet_util/src/forked_lib/psbt/utils/converter.dart';

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

  group('LTC address parsing', () {
    // LTC version bytes: pubKeyHash=0x30, scriptHash=0x32, bech32Hrp='ltc'
    const ltcPubKeyHash = 0x30;
    const ltcScriptHash = 0x32;
    const ltcBech32Hrp = 'ltc';

    test('P2PKH script produces LTC L-address', () {
      final hash160 = Converter.hexToBytes('e8df6b4293962bcde0c39e59bd3371981897392b');
      final script = psbt.ScriptPublicKey([0x76, 0xa9, hash160, 0x88, 0xac]);
      final address = script.getAddress(
          pubKeyHashVersion: ltcPubKeyHash, bech32Hrp: ltcBech32Hrp);
      expect(address.startsWith('L'), isTrue);
    });

    test('P2SH script produces LTC M-address', () {
      final hash160 = Converter.hexToBytes('f1a0e4682c80c932a225b448644366e106712a22');
      final script = psbt.ScriptPublicKey([0xa9, hash160, 0x87]);
      final address = script.getAddress(
          scriptHashVersion: ltcScriptHash, bech32Hrp: ltcBech32Hrp);
      expect(address.startsWith('M'), isTrue);
    });

    test('P2WPKH script produces LTC ltc1-address', () {
      final hash160 = Converter.hexToBytes('751e76e8199196d454941c45d1b3a323f1433bd6');
      final script = psbt.ScriptPublicKey([0x00, hash160]);
      final address = script.getAddress(bech32Hrp: ltcBech32Hrp);
      expect(address.startsWith('ltc1'), isTrue);
    });

    test('PsbtTxData.fromHash with chain ltc returns LTC addresses', () {
      final transactions = json.decode(
          File('./test/psbt/data.json').readAsStringSync(encoding: utf8));
      final psbtHex = transactions[0]['psbt'];
      final psbtTxData = PsbtTxData.fromHash(psbtHex, chain: 'ltc');
      // Access raw output addresses (unfiltered) via the unsigned transaction
      final outputs = psbtTxData.psbt.unsignedTransaction!.outputs;
      expect(outputs, isNotEmpty);
      for (final output in outputs) {
        final addr = output.getAddress(chain: 'ltc');
        // BTC P2PKH addresses start with '1', LTC P2PKH with 'L'
        expect(addr.startsWith('L'), isTrue,
            reason: 'LTC address should start with L, got $addr');
      }
    });

    test('LTC testnet P2WPKH script produces tltc1-address', () {
      final hash160 = Converter.hexToBytes('751e76e8199196d454941c45d1b3a323f1433bd6');
      final script = psbt.ScriptPublicKey([0x00, hash160]);
      final mainnetAddr = script.getAddress(
          pubKeyHashVersion: 0x30, scriptHashVersion: 0x32, bech32Hrp: 'ltc');
      final testnetAddr = script.getAddress(
          pubKeyHashVersion: 0x6f, scriptHashVersion: 0x3a, bech32Hrp: 'tltc');
      expect(mainnetAddr.startsWith('ltc1'), isTrue);
      expect(testnetAddr.startsWith('tltc1'), isTrue);
      expect(mainnetAddr, isNot(equals(testnetAddr)));
    });

    test('LTC testnet P2SH uses 0x3a version byte (not BTC 0xc4)', () {
      // Per blockchain_utils CoinConf.litecoinTestNet: p2shStdNetVer = [0x3a]
      final hash160 = Converter.hexToBytes('f1a0e4682c80c932a225b448644366e106712a22');
      final script = psbt.ScriptPublicKey([0xa9, hash160, 0x87]);
      final ltcTestnetAddr = script.getAddress(
          pubKeyHashVersion: 0x6f, scriptHashVersion: 0x3a, bech32Hrp: 'tltc');
      final btcTestnetAddr = script.getAddress(
          pubKeyHashVersion: 0x6f, scriptHashVersion: 0xc4, bech32Hrp: 'tb');
      // The two addresses must differ — if they're the same, version byte is
      // being collapsed somewhere upstream.
      expect(ltcTestnetAddr, isNot(equals(btcTestnetAddr)),
          reason: 'LTC testnet P2SH (0x3a) and BTC testnet P2SH (0xc4) must '
              'produce different addresses. Got: $ltcTestnetAddr');
      // Decode base58 to confirm version byte is 0x3a.
      final decoded = base58.decode(ltcTestnetAddr);
      expect(decoded.first, 0x3a,
          reason: 'LTC testnet P2SH address must encode with version byte 0x3a');
    });
  });
}
