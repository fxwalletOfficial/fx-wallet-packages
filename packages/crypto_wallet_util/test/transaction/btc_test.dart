import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';

void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final legacyWallet = await BtcCoin.fromMnemonic(mnemonic);
  final taprootWallet = await BtcCoin.fromMnemonic(mnemonic, null, true);

  final psbtJson = json.decode(
    File('./test/psbt/data.json').readAsStringSync(encoding: utf8),
  );

  final legacyUnsignedPsbt = psbtJson[0]['psbt'];
  final taprootUnsignedPsbt = psbtJson[1]['psbt'];

  group('test psbt tx signer', () {
    test('legacy signature generation', () {
      // Create PSBT transaction data and signer
      final psbtTxData = PsbtTxData.fromHash(
        legacyUnsignedPsbt,
        isTaproot: false,
      );

      final signer = PsbtTxSigner(legacyWallet, psbtTxData);

      // Sign the transaction
      final signedTxData = signer.sign();
      final jsonData = signedTxData.toJson();
      final broadcastData = signedTxData.toBroadcast();
      assert(jsonData.isNotEmpty);
      assert(broadcastData.isNotEmpty);

      // Verify signatures were added
      expect(signer.verify(), isTrue);
    });

    test('taproot signature generation', () {
      // Create PSBT transaction data and signer
      final psbtTxData = PsbtTxData.fromHash(
        taprootUnsignedPsbt,
        isTaproot: true,
      );
      final signer = PsbtTxSigner(taprootWallet, psbtTxData);

      // Sign the transaction
      final signedTxData = signer.sign();
      final jsonData = signedTxData.toJson();
      final broadcastData = signedTxData.toBroadcast();
      assert(jsonData.isNotEmpty);
      assert(broadcastData.isNotEmpty);

      // Verify signatures were added
      expect(signer.verify(), isTrue);
      expect(signer.safeVerify(), isTrue);
    });
  });

  test('psbt to origin', () {
    final psbtTxData = PsbtTxData.fromHash(
      taprootUnsignedPsbt,
      isTaproot: true,
    );
    final originTx = psbtTxData.origin;
    final originData = psbtJson[1]['data']['origin'];
    // compare origin data
    // expect(originTx.version, originData['version']);
    expect(originTx.locktime, originData['locktime']);
    for (var i = 0; i < originTx.inputs.length; i++) {
      expect(
        originTx.inputs[i].prevout.hash,
        originData['inputs'][i]['prevout']['hash'],
      );
      expect(
        originTx.inputs[i].prevout.index,
        originData['inputs'][i]['prevout']['index'],
      );
      expect(
        originTx.inputs[i].coin.value,
        originData['inputs'][i]['coin']['value'],
      );
      expect(
        originTx.inputs[i].coin.address,
        originData['inputs'][i]['coin']['address'],
      );
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

      final psbtTxData = PsbtTxData.fromHash(
        signedPsbt,
        isTaproot: txType == 'TxType.TAPROOT',
      );
      psbtTxData.isSigned = true;
      final signature = psbtTxData.getSignedTxHex();

      // expect(signaturePsbt, signature);
      expect(signature, txHash);
    }
  });

  // Regression test for #74: BTC testnet address should not be misidentified as BCH
  group('testnet address generation and detection', () {
    test('BTC testnet address should use correct version byte (0x6f)', () async {
      const mnemonic =
          'assault assault assault assault assault assault assault assault assault assault assault about';
      final btcChain = BTCChain();
      final wallet = await BtcCoin.fromMnemonic(mnemonic, btcChain.testnet);
      final address = wallet.address;

      // Should generate testnet format address (m/n... for legacy, tb1... for segwit)
      expect(
        address.startsWith('m') ||
            address.startsWith('n') ||
            address.startsWith('tb1'),
        isTrue,
        reason: 'BTC testnet address should start with m/n/tb1, got: $address',
      );
    });

    test('BTC testnet legacy address is assigned to BTC, not BCH', () async {
      const mnemonic =
          'assault assault assault assault assault assault assault assault assault assault assault about';
      final btcChain = BTCChain();
      final bchChain = BCHChain();

      final wallet = await BtcCoin.fromMnemonic(mnemonic, btcChain.testnet);
      final address = wallet.address;

      // Should be valid for BTC testnet
      final isBtcValid = AddressUtils.checkAddressValid(
        address,
        btcChain.testnet,
      );
      expect(
        isBtcValid,
        isTrue,
        reason: 'BTC testnet address should be valid for BTC testnet',
      );

      // BTC and BCH testnet legacy addresses share version 0x6f. BCH
      // classification therefore requires a network-qualified CashAddr.
      final isBchValid = AddressUtils.checkAddressValid(
        address,
        bchChain.testnet,
      );
      expect(
        isBchValid,
        isFalse,
        reason: 'BTC testnet address should NOT be valid for BCH testnet',
      );
    });

    test('BTC mainnet address format unchanged', () async {
      const mnemonic =
          'assault assault assault assault assault assault assault assault assault assault assault about';
      final btcChain = BTCChain();
      final wallet = await BtcCoin.fromMnemonic(mnemonic, btcChain.mainnet);
      final address = wallet.address;

      // Mainnet should still generate 1.../bc1... addresses
      expect(
        address.startsWith('1') ||
            address.startsWith('3') ||
            address.startsWith('bc1'),
        isTrue,
        reason: 'BTC mainnet address should start with 1/3/bc1, got: $address',
      );
    });
  });

  group('BIP86 Taproot network handling', () {
    const bip86Mnemonic =
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

    test('public factory matches the first BIP86 mainnet vector', () async {
      final wallet = await getMnemonicWallet('taproot', bip86Mnemonic);

      expect(
        wallet.address,
        'bc1p5cyxnuxmeuwuvkwfem96lqzszd02n6xdcjrs20cac6yqjjwudpxqkedrcr',
      );
    });

    test(
      'public factory keeps BIP86 derivation when selecting testnet',
      () async {
        final btcChain = BTCChain();
        final legacyWallet = await BtcCoin.fromMnemonic(
          bip86Mnemonic,
          btcChain.testnet,
        );
        final taprootWallet = await getMnemonicWallet(
          'taproot',
          bip86Mnemonic,
          walletSetting: btcChain.testnet,
        );

        expect(taprootWallet.publicKey, isNot(equals(legacyWallet.publicKey)));
        expect(
          taprootWallet.address,
          'tb1p5cyxnuxmeuwuvkwfem96lqzszd02n6xdcjrs20cac6yqjjwudpxqp3mvzv',
        );
      },
    );

    test(
      'Taproot validation rejects addresses from the other network',
      () async {
        final btcChain = BTCChain();
        final mainnetWallet = await getMnemonicWallet('taproot', bip86Mnemonic);
        final testnetWallet = await getMnemonicWallet(
          'taproot',
          bip86Mnemonic,
          walletSetting: btcChain.testnet,
        );

        expect(
          AddressUtils.checkAddressValid(
            mainnetWallet.address,
            btcChain.mainnet,
          ),
          isTrue,
        );
        expect(
          AddressUtils.checkAddressValid(
            mainnetWallet.address,
            btcChain.testnet,
          ),
          isFalse,
        );
        expect(
          AddressUtils.checkAddressValid(
            testnetWallet.address,
            btcChain.testnet,
          ),
          isTrue,
        );
        expect(
          AddressUtils.checkAddressValid(
            testnetWallet.address,
            btcChain.mainnet,
          ),
          isFalse,
        );
      },
    );

    test('Taproot validation rejects an invalid bech32m checksum', () async {
      final btcChain = BTCChain();
      final wallet = await getMnemonicWallet('taproot', bip86Mnemonic);
      final address = wallet.address;
      final corruptedAddress = '${address.substring(0, address.length - 1)}q';

      expect(
        AddressUtils.checkAddressValid(corruptedAddress, btcChain.mainnet),
        isFalse,
      );
    });

    test('custom regtest and signet-compatible HRPs are supported', () async {
      WalletSetting settingForHrp(String hrp) => WalletSetting(
        bip44Path: BTC_PATH,
        addressType: AddressType.BTC,
        networkType: NetworkType(
          messagePrefix: '\u0018Bitcoin Signed Message:\n',
          bech32: hrp,
          wif: 239,
          pubKeyHash: 0x6f,
          scriptHash: 0xc4,
          bip32: Bip32Type(public: 70617704, private: 70615956),
        ),
      );

      final regtestSetting = settingForHrp('bcrt');
      final signetSetting = settingForHrp('tb');
      final regtestWallet = await BtcCoin.fromMnemonic(
        bip86Mnemonic,
        regtestSetting,
        true,
      );
      final signetWallet = await BtcCoin.fromMnemonic(
        bip86Mnemonic,
        signetSetting,
        true,
      );

      expect(regtestWallet.address, startsWith('bcrt1p'));
      expect(
        AddressUtils.checkAddressValid(regtestWallet.address, regtestSetting),
        isTrue,
      );
      expect(signetWallet.address, startsWith('tb1p'));
      expect(
        AddressUtils.checkAddressValid(signetWallet.address, signetSetting),
        isTrue,
      );
    });

    test('explicit networks without a valid HRP fail closed', () async {
      WalletSetting settingForHrp(String? hrp) => WalletSetting(
        bip44Path: BTC_PATH,
        addressType: AddressType.BTC,
        networkType: NetworkType(
          messagePrefix: '\u0018Bitcoin Signed Message:\n',
          bech32: hrp,
          wif: 239,
          pubKeyHash: 0x6f,
          scriptHash: 0xc4,
          bip32: Bip32Type(public: 70617704, private: 70615956),
        ),
      );

      final missingHrpWallet = await BtcCoin.fromMnemonic(
        bip86Mnemonic,
        settingForHrp(null),
        true,
      );
      final invalidHrpWallet = await BtcCoin.fromMnemonic(
        bip86Mnemonic,
        settingForHrp(' '),
        true,
      );

      expect(() => missingHrpWallet.address, throwsArgumentError);
      expect(() => invalidHrpWallet.address, throwsA(isA<Exception>()));
    });
  });
}
