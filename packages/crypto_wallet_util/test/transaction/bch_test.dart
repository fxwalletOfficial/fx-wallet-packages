import 'dart:convert';
import 'dart:io';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart'
    as bitcoin;
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/partially_signed_bitcoin_transaction.dart';
import 'package:test/test.dart';

PSBT _buildBchPsbtFixture({
  required String inputAddress,
  required String changeAddress,
}) {
  final fixtures =
      json.decode(
            File('./test/psbt/data.json').readAsStringSync(encoding: utf8),
          )
          as List<dynamic>;
  final transferJson =
      json.decode(json.encode(fixtures.first['data'])) as Map<String, dynamic>;
  final origin = transferJson['origin'] as Map<String, dynamic>;
  final outputs = origin['outputs'] as List<dynamic>;
  transferJson['chain'] = 'bch';
  transferJson['inputAddress'] = inputAddress;
  outputs[1]['address'] = changeAddress;
  outputs[1]['path'] = "m/44'/145'/0'/1/0";
  return PSBT.fromTransferPsbt(BtcTransferInfo.fromJson(transferJson));
}

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final bchWallet = await BchCoin.fromMnemonic(mnemonic);

  group('BCH Basic Wallet Tests', () {
    test('bch address generation', () {
      final address = bchWallet.publicKeyToAddress(bchWallet.publicKey);
      expect(
        address,
        equals('bitcoincash:qq0xhc4ndukzq3xsrqt26vpp2ker49h5t5qp85fg5p'),
      );
    });

    test('bch sign/verify', () {
      const message =
          '509e115a79d13dbaf43e03f944328453e4d81f443ce35eaa2f5c0432e1903483';
      final signature = bchWallet.sign(message);
      expect(
        signature,
        equals(
          '3043021f1e7def81da639baf2cf3ec58cbbd43bd3c7576bf6064cf5d72759642b818e202205f3e413d1ae0bae0c305c8855c504399c5db680fecc3953b2af1c03b4ad14f9241',
        ),
      );
    });

    test('bch private key to public key', () {
      final publicKey = bchWallet.privateKeyToPublicKey(bchWallet.privateKey);
      expect(publicKey, isNotEmpty);
      expect(publicKey.length, 33); // Compressed public key (default)
    });

    test('bch from private key', () {
      final privateKeyHex =
          '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
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
          ),
        ],
        hex:
            '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
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
    });

    test('bch gspl transaction with change output', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(
            path: "m/44'/145'/0'/0/0",
            amount: 3979484,
            signHashType: 65,
          ),
        ],
        hex:
            '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
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
        inputs: [GsplItem(path: null, amount: 100000000, signHashType: 65)],
        hex:
            '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(bchWallet, txData);
      expect(() => signer.sign(), throwsA(isA<Exception>()));
    });

    test('should throw exception for null input amount in GSPL', () async {
      final txData = GsplTxData(
        inputs: [
          GsplItem(path: "m/44'/145'/0'/0/0", amount: null, signHashType: 65),
        ],
        hex:
            '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

      final signer = GsplTxSigner(bchWallet, txData);
      expect(() => signer.sign(), throwsA(isA<Exception>()));
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
          ),
        ],
        hex:
            '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
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
            signHashType:
                67, // SIGHASH_ALL | SIGHASH_BITCOINCASHBIP143 | SIGHASH_ANYONECANPAY
          ),
        ],
        hex:
            '02000000013b12abfd3a60fbe75f79f71dceeb07c665704d8ad46ff419a223f80b2565fd900100000000ffffffff020e260000000000001976a9146a624a6ee30c77e5da3d49c53a54b92544e9a57888accc913c00000000001976a914a4c0b3134c06f28a7c00a70518e1bd2bbb4ec05c88ac00000000',
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
      expect(
        bchWallet.sighashType,
        equals(65),
      ); // SIGHASH_ALL | SIGHASH_BITCOINCASHBIP143
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
      final privateKeyHex =
          '1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
      final wallet = BchCoin.fromPrivateKey(privateKeyHex);
      final address = wallet.publicKeyToAddress(wallet.publicKey);

      expect(address.startsWith('bitcoincash:'), isTrue);
    });

    test('BCH testnet generates and validates bchtest CashAddr', () async {
      final bchChain = BCHChain();
      final wallet = await BchCoin.fromMnemonic(mnemonic, bchChain.testnet);
      final address = wallet.address;

      expect(address, startsWith('bchtest:'));
      expect(AddressUtils.checkAddressValid(address, bchChain.testnet), isTrue);
      expect(
        bitcoin.Address.addressToOutputScript(
          address,
          bchChain.testnet.networkType,
        ),
        isNotEmpty,
      );
      expect(
        AddressUtils.checkAddressValid(address, bchChain.mainnet),
        isFalse,
      );
    });

    test('BCH testnet P2SH conversion preserves type and network', () {
      const legacyTestnetP2sh = '2NBFNJTktNa7GZusGbDbGKRZTxdK9VVez3n';
      final bchChain = BCHChain();
      final cashAddress = bitcoin.Address.legacyToBch(
        address: legacyTestnetP2sh,
        prefix: 'bchtest',
      );

      expect(cashAddress, startsWith('bchtest:p'));
      expect(
        bitcoin.Address.bchToLegacy(cashAddress, prefix: 'bchtest'),
        legacyTestnetP2sh,
      );
      expect(
        bitcoin.Address.addressToOutputScript(
          cashAddress,
          bchChain.testnet.networkType,
        ),
        isNotEmpty,
      );
    });

    test(
      'BCH mainnet and testnet CashAddr prefixes do not cross-validate',
      () async {
        final bchChain = BCHChain();
        final mainnetWallet = await BchCoin.fromMnemonic(
          mnemonic,
          bchChain.mainnet,
        );
        final testnetWallet = await BchCoin.fromMnemonic(
          mnemonic,
          bchChain.testnet,
        );

        expect(
          AddressUtils.checkAddressValid(
            mainnetWallet.address,
            bchChain.mainnet,
          ),
          isTrue,
        );
        expect(
          AddressUtils.checkAddressValid(
            mainnetWallet.address,
            bchChain.testnet,
          ),
          isFalse,
        );
        expect(
          AddressUtils.checkAddressValid(
            testnetWallet.address,
            bchChain.mainnet,
          ),
          isFalse,
        );
      },
    );

    test('BCH testnet CashAddr identifies legacy PSBT change output', () async {
      final wallet = await BchCoin.fromMnemonic(mnemonic, BCHChain().testnet);
      final cashAddress = wallet.address;
      final legacyAddress = bitcoin.Address.bchToLegacy(cashAddress);
      expect(cashAddress, startsWith('bchtest:'));
      expect(legacyAddress, anyOf(startsWith('m'), startsWith('n')));

      // Exercise the real PSBT change-detection call chain with a bchtest input
      // and its equivalent legacy m/n output. Before the fix this threw because
      // the conversion was forced through the bitcoincash mainnet prefix.
      final psbt = _buildBchPsbtFixture(
        inputAddress: cashAddress,
        changeAddress: legacyAddress,
      );

      expect(psbt.outputs[0].derivationPath, isNull);
      expect(psbt.outputs[1].derivationPath, isNotNull);
      expect(psbt.outputs[1].isChange, isTrue);
    });

    test('BCH PSBT does not mark a cross-network address as change', () async {
      final chain = BCHChain();
      final testnetWallet = await BchCoin.fromMnemonic(mnemonic, chain.testnet);
      final mainnetWallet = await BchCoin.fromMnemonic(mnemonic, chain.mainnet);
      final mainnetLegacy = bitcoin.Address.bchToLegacy(mainnetWallet.address);

      final psbt = _buildBchPsbtFixture(
        inputAddress: testnetWallet.address,
        changeAddress: mainnetLegacy,
      );

      expect(psbt.outputs[1].derivationPath, isNull);
      expect(psbt.outputs[1].isChange, isFalse);
    });

    for (final inputAddress in ['', 'bchtest:not-valid']) {
      test('BCH PSBT fails closed for input "$inputAddress"', () async {
        final wallet = await BchCoin.fromMnemonic(mnemonic, BCHChain().testnet);
        final legacyAddress = bitcoin.Address.bchToLegacy(wallet.address);

        final psbt = _buildBchPsbtFixture(
          inputAddress: inputAddress,
          changeAddress: legacyAddress,
        );

        expect(psbt.outputs[1].derivationPath, isNull);
        expect(psbt.outputs[1].isChange, isFalse);
      });
    }

    test(
      'BCH validation rejects legacy testnet ambiguity and bad checksum',
      () async {
        final btcChain = BTCChain();
        final bchChain = BCHChain();
        final btcWallet = await BtcCoin.fromMnemonic(
          mnemonic,
          btcChain.testnet,
        );
        final bchWallet = await BchCoin.fromMnemonic(
          mnemonic,
          bchChain.testnet,
        );
        final cashAddress = bchWallet.address;
        final corruptedCashAddress =
            '${cashAddress.substring(0, cashAddress.length - 1)}q';

        expect(
          AddressUtils.checkAddressValid(btcWallet.address, btcChain.testnet),
          isTrue,
        );
        expect(
          AddressUtils.checkAddressValid(btcWallet.address, bchChain.testnet),
          isFalse,
        );
        expect(
          AddressUtils.checkAddressValid(
            corruptedCashAddress,
            bchChain.testnet,
          ),
          isFalse,
        );
        expect(
          () => bitcoin.Address.bchToLegacy(corruptedCashAddress),
          throwsArgumentError,
        );
      },
    );
  });
}
