import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final dogeWallet = await DogeCoin.fromMnemonic(mnemonic);

  group('DOGE Basic Wallet Tests', () {
    test('doge address generation', () {
      final address = dogeWallet.publicKeyToAddress(dogeWallet.publicKey);
      expect(address, equals('DGzWEPnBNmxWokA39gYHWENywwydBkuSFx'));
    });

    test('doge sign/verify', () {
      const message = '509e115a79d13dbaf43e03f944328453e4d81f443ce35eaa2f5c0432e1903483';
      final signature = dogeWallet.sign(message);
      expect(signature, equals('304402204b3f4453b1ee7373028829b3c79644c86732bc221ce18bc3a3876087015de1b2022056c0aeee761c7ee2dc015ebed83b54c1337c6ca262ef5ac9a9e5c328791c121101'));
    });

    test('doge private key to public key', () {
      final publicKey = dogeWallet.privateKeyToPublicKey(dogeWallet.privateKey);
      expect(publicKey, isNotEmpty);
      expect(publicKey.length, 33); // Compressed public key (default)
    });

    test('doge from private key', () {
      final privateKeyHex = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      final wallet = DogeCoin.fromPrivateKey(privateKeyHex);
      expect(wallet.privateKey, isNotEmpty);
      expect(wallet.publicKey, isNotEmpty);
    });
  });

  group('DOGE GSPL Transaction Tests', () {
    test('doge gspl transaction signing', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/3'/0'/0/0",
            amount: 4196482751,
            signHashType: 1,
          )
        ],
        hex: '0200000001da575bcc3c25925f568ad894c76d7b7be140593f3ede0627d219b16ee3ffb1500100000000ffffffff02802b530b000000001976a9141a0dfffc07f5be9d3f44d4f4c9accd83e2ea240b88ac1b21caee000000001976a914dad255442a5da048efdbdba67f8c5d0a09c769af88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(dogeWallet, txData);
      final signedTxData = signer.sign();

      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
      expect(signedTxData.message, isNotEmpty);

      // Verify all inputs have signatures
      for (final input in signedTxData.inputs) {
        expect(input.signature, isNotNull);
        expect(input.signature!.isNotEmpty, true);
      }
    });

    test('doge gspl transaction with change output', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/3'/0'/0/0",
            amount: 4196482751,
            signHashType: 1,
          )
        ],
        hex: '0200000001da575bcc3c25925f568ad894c76d7b7be140593f3ede0627d219b16ee3ffb1500100000000ffffffff02802b530b000000001976a9141a0dfffc07f5be9d3f44d4f4c9accd83e2ea240b88ac1b21caee000000001976a914dad255442a5da048efdbdba67f8c5d0a09c769af88ac00000000',
        change: GsplItem(
          path: "m/44'/3'/0'/1/0",
          amount: 4006224155,
          signHashType: 1,
        ),
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(dogeWallet, txData);
      final signedTxData = signer.sign();

      expect(signer.verify(), true);
      expect(signedTxData.change, isNotNull);
    });
  });

  group('DOGE Error Handling Tests', () {
    test('should throw exception for invalid private key', () {
      expect(
        () => DogeCoin.fromPrivateKey('invalid'),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for null input path in GSPL', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: null,
            amount: 100000000,
            signHashType: 1,
          )
        ],
        hex: '0200000001da575bcc3c25925f568ad894c76d7b7be140593f3ede0627d219b16ee3ffb1500100000000ffffffff02802b530b000000001976a9141a0dfffc07f5be9d3f44d4f4c9accd83e2ea240b88ac1b21caee000000001976a914dad255442a5da048efdbdba67f8c5d0a09c769af88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(dogeWallet, txData);
      expect(
        () => signer.sign(),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for null input amount in GSPL', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/3'/0'/0/0",
            amount: null,
            signHashType: 1,
          )
        ],
        hex: '0200000001da575bcc3c25925f568ad894c76d7b7be140593f3ede0627d219b16ee3ffb1500100000000ffffffff02802b530b000000001976a9141a0dfffc07f5be9d3f44d4f4c9accd83e2ea240b88ac1b21caee000000001976a914dad255442a5da048efdbdba67f8c5d0a09c769af88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(dogeWallet, txData);
      expect(
        () => signer.sign(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('DOGE Signature Hash Type Tests', () {
    test('doge should use legacy signature hash', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/3'/0'/0/0",
            amount: 100000000,
            signHashType: 1, // SIGHASH_ALL
          )
        ],
        hex: '0200000001da575bcc3c25925f568ad894c76d7b7be140593f3ede0627d219b16ee3ffb1500100000000ffffffff02802b530b000000001976a9141a0dfffc07f5be9d3f44d4f4c9accd83e2ea240b88ac1b21caee000000001976a914dad255442a5da048efdbdba67f8c5d0a09c769af88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(dogeWallet, txData);
      final signedTxData = signer.sign();

      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
    });
  });
}
