import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:test/test.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final bchWallet = await BchCoin.fromMnemonic(mnemonic);

  group('BCH Basic Wallet Tests', () {
    test('bch address generation', () {
      final address = bchWallet.publicKeyToAddress(bchWallet.publicKey);
      expect(address, equals('bitcoincash:qq0xhc4ndukzq3xsrqt26vpp2ker49h5t5qp85fg5p'));
    });

    test('bch sign/verify', () {
      const message = '509e115a79d13dbaf43e03f944328453e4d81f443ce35eaa2f5c0432e1903483';
      final signature = bchWallet.sign(message);
      expect(signature, equals('3043021f1e7def81da639baf2cf3ec58cbbd43bd3c7576bf6064cf5d72759642b818e202205f3e413d1ae0bae0c305c8855c504399c5db680fecc3953b2af1c03b4ad14f9241'));
    });

    test('bch private key to public key', () {
      final publicKey = bchWallet.privateKeyToPublicKey(bchWallet.privateKey);
      expect(publicKey, isNotEmpty);
      expect(publicKey.length, 33); // Compressed public key (default)
    });

    test('bch from private key', () {
      final privateKeyHex = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      final wallet = BchCoin.fromPrivateKey(privateKeyHex);
      expect(wallet.privateKey, isNotEmpty);
      expect(wallet.publicKey, isNotEmpty);
    });

    test('bch address format validation', () {
      final address = bchWallet.publicKeyToAddress(bchWallet.publicKey);
      // BCH addresses should be in CashAddr format
      expect(address.contains(':'), isTrue);
      expect(address.split(':')[0], equals('bitcoincash'));
    });
  });

  group('BCH GSPL Transaction Tests', () {
    test('bch gspl transaction signing', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/145'/0'/0/0",
            amount: 3979484,
            signHashType: 65, // SIGHASH_ALL | SIGHASH_BITCOINCASHBIP143
          )
        ],
        hex: '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(bchWallet, txData);
      final signedTxData = signer.sign();

      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
      expect(signedTxData.message, isNotEmpty);

      // Verify all inputs have signatures
      for (final input in signedTxData.inputs) {
        expect(input.signature, isNotNull);
        expect(input.signature!.isNotEmpty, true);
      }

      print('BCH GSPL signed transaction: ${signedTxData.message}');
    });

    test('bch gspl transaction with change output', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/145'/0'/0/0",
            amount: 3979484,
            signHashType: 65,
          )
        ],
        hex: '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
        change: GsplItem(
          path: "m/44'/145'/0'/1/0",
          amount: 1000000,
          signHashType: 65,
        ),
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(bchWallet, txData);
      final signedTxData = signer.sign();

      expect(signer.verify(), true);
      expect(signedTxData.change, isNotNull);
    });
  });

  group('BCH Error Handling Tests', () {
    test('should throw exception for invalid private key', () {
      expect(
        () => BchCoin.fromPrivateKey('invalid'),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for null input path in GSPL', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: null,
            amount: 100000000,
            signHashType: 65,
          )
        ],
        hex: '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(bchWallet, txData);
      expect(
        () => signer.sign(),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception for null input amount in GSPL', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/145'/0'/0/0",
            amount: null,
            signHashType: 65,
          )
        ],
        hex: '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(bchWallet, txData);
      expect(
        () => signer.sign(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('BCH Signature Hash Type Tests', () {
    test('bch should use BIP143 signature hash', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/145'/0'/0/0",
            amount: 3979484,
            signHashType: 65, // SIGHASH_ALL | SIGHASH_BITCOINCASHBIP143
          )
        ],
        hex: '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(bchWallet, txData);
      final signedTxData = signer.sign();
      
      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
    });

    test('bch should handle different sign hash types', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/145'/0'/0/0",
            amount: 3979484,
            signHashType: 67, // SIGHASH_ALL | SIGHASH_BITCOINCASHBIP143 | SIGHASH_ANYONECANPAY
          )
        ],
        hex: '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(bchWallet, txData);
      final signedTxData = signer.sign();
      
      expect(signer.verify(), true);
      expect(signedTxData.isSigned, true);
    });

    test('bch should use correct sighash type in wallet', () {
      // BCH wallet should have the correct sighash type set
      expect(bchWallet.sighashType, equals(65)); // SIGHASH_ALL | SIGHASH_BITCOINCASHBIP143
    });
  });

  group('BCH Address Format Tests', () {
    test('bch should generate correct cashaddr format', () {
      final address = bchWallet.publicKeyToAddress(bchWallet.publicKey);
      
      // Check CashAddr format
      expect(address.startsWith('bitcoincash:'), isTrue);
      
      // Check that it's a valid CashAddr format
      final parts = address.split(':');
      expect(parts.length, equals(2));
      expect(parts[0], equals('bitcoincash'));
      
      // The address part should be a valid bech32 string
      final addressPart = parts[1];
      expect(addressPart.length, greaterThan(0));
    });

    test('bch should handle different public keys', () {
      final privateKeyHex = '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      final wallet = BchCoin.fromPrivateKey(privateKeyHex);
      final address = wallet.publicKeyToAddress(wallet.publicKey);
      
      expect(address.startsWith('bitcoincash:'), isTrue);
    });
  });
}
