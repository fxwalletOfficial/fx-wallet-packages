import 'dart:convert';
import 'dart:io';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  final transactions = json.decode(File('./test/gspl/data.json').readAsStringSync(encoding: utf8));

  group('GSPL Transaction Tests', () {
    for (final transactionJson in transactions) {
      test('${transactionJson['description']}', () async {
        final type = transactionJson['type'];
        final mnemonic = transactionJson['mnemonic'];
        final data = transactionJson['data'];
        final expected = transactionJson['expected'];

        // Create wallet based on type
        WalletType wallet;
        switch (type) {
          case 'doge':
            wallet = await DogeCoin.fromMnemonic(mnemonic);
            break;
          case 'ltc_legacy':
            wallet = await LtcCoin.fromMnemonic(mnemonic, null, false);
            break;
          case 'ltc_taproot':
            wallet = await LtcCoin.fromMnemonic(mnemonic, null, true);
            break;
          case 'bch':
            wallet = await BchCoin.fromMnemonic(mnemonic);
            break;
          default:
            throw Exception('Unsupported wallet type: $type');
        }

        // Create GSPL transaction data
        final inputs = (data['inputs'] as List)
            .map((input) => GsplItem(
                  path: input['path'],
                  amount: input['amount'],
                  signHashType: input['signHashType'],
                ))
            .toList();

        final change = data['change'] != null
            ? GsplItem(
                path: data['change']['path'],
                amount: data['change']['amount'],
                signHashType: data['change']['signHashType'],
              )
            : null;

        final txData = GsplTxData(
          inputs: inputs,
          hex: data['hex'],
          change: change,
          dataType: BtcSignDataType.values.firstWhere(
            (e) => e.name == data['dataType'],
          ),
        );

        // Test transaction data parsing
        final jsonData = txData.toJson();
        expect(jsonData['amount'], expected['amount']);
        expect(jsonData['fee'], expected['fee']);
        expect(jsonData['paymentAddress'], expected['paymentAddress']);

        // Test signing
        final signer = GsplTxSigner(wallet, txData);
        final signedTxData = signer.sign();

        // Verify the transaction is signed
        expect(signer.verify(), true);
        expect(signedTxData.isSigned, true);
        expect(signedTxData.message, isNotEmpty);

        // Verify all inputs have signatures
        for (final input in signedTxData.inputs) {
          expect(input.signature, isNotNull);
          expect(input.signature!.isNotEmpty, true);
        }
      });
    }
  });

  group('GSPL Error Handling Tests', () {
    test('should throw exception for unsupported wallet type', () async {
      final mnemonic = 'few tag video grain jealous light tired vapor shed festival shine tag';
      
      // Create a mock wallet that's not supported by GSPL
      final unsupportedWallet = await AptosCoin.fromMnemonic(mnemonic);
      
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/3'/0'/0/0",
            amount: 100000000,
            signHashType: 1,
          )
        ],
        hex: '020000000162c938f33daedcdef74ffe74ab94433825feace0b31cc7cd426a65968674c58c0100000000ffffffff0210270000000000001976a914e8df6b4293962bcde0c39e59bd3371981897392b88ac94310000000000001976a914e8df6b4293962bcde0c39e59bd3371981897392b88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      expect(
        () => GsplTxSigner(unsupportedWallet, txData),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for null input path', () async {
      final mnemonic = 'few tag video grain jealous light tired vapor shed festival shine tag';
      final wallet = await DogeCoin.fromMnemonic(mnemonic);
      
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: null, // This should cause an exception
            amount: 100000000,
            signHashType: 1,
          )
        ],
        hex: '020000000162c938f33daedcdef74ffe74ab94433825feace0b31cc7cd426a65968674c58c0100000000ffffffff0210270000000000001976a914e8df6b4293962bcde0c39e59bd3371981897392b88ac94310000000000001976a914e8df6b4293962bcde0c39e59bd3371981897392b88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(wallet, txData);
      expect(
        () => signer.sign(),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for null input amount', () async {
      final mnemonic = 'few tag video grain jealous light tired vapor shed festival shine tag';
      final wallet = await DogeCoin.fromMnemonic(mnemonic);
      
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/3'/0'/0/0",
            amount: null, // This should cause an exception
            signHashType: 1,
          )
        ],
        hex: '020000000162c938f33daedcdef74ffe74ab94433825feace0b31cc7cd426a65968674c58c0100000000ffffffff0210270000000000001976a914e8df6b4293962bcde0c39e59bd3371981897392b88ac94310000000000001976a914e8df6b4293962bcde0c39e59bd3371981897392b88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(wallet, txData);
      expect(
        () => signer.sign(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('GSPL Signature Hash Type Tests', () {
    test('BCH should use BIP143 signature hash', () async {
      final mnemonic = 'few tag video grain jealous light tired vapor shed festival shine tag';
      final wallet = await BchCoin.fromMnemonic(mnemonic);
      
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/145'/0'/0/0",
            amount: 100000000,
            signHashType: 65, // SIGHASH_ALL | SIGHASH_BITCOINCASHBIP143
          )
        ],
        hex: '020000000162c938f33daedcdef74ffe74ab94433825feace0b31cc7cd426a65968674c58c0100000000ffffffff0210270000000000001976a914e8df6b4293962bcde0c39e59bd3371981897392b88ac94310000000000001976a914e8df6b4293962bcde0c39e59bd3371981897392b88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(wallet, txData);
      final signedTxData = signer.sign();
      
      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
    });

    test('DOGE should use legacy signature hash', () async {
      final mnemonic = 'number vapor draft title message quarter hour other hotel leave shrug donor';
      final wallet = await DogeCoin.fromMnemonic(mnemonic);
      
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/3'/0'/0/0",
            amount: 100000000,
            signHashType: 1,
          )
        ],
        hex: '020000000162c938f33daedcdef74ffe74ab94433825feace0b31cc7cd426a65968674c58c0100000000ffffffff0210270000000000001976a914e8df6b4293962bcde0c39e59bd3371981897392b88ac94310000000000001976a914e8df6b4293962bcde0c39e59bd3371981897392b88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(wallet, txData);
      final signedTxData = signer.sign();
      
      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
    });
  });
}
