import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart'
    as bitcoin;
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/partially_signed_bitcoin_transaction.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

PSBT _buildBtcPsbtFixture(String xpubkey) {
  final fixtures =
      json.decode(
            File('./test/psbt/data.json').readAsStringSync(encoding: utf8),
          )
          as List<dynamic>;
  final transferJson =
      json.decode(json.encode(fixtures.first['data'])) as Map<String, dynamic>;
  transferJson['xpubkey'] = xpubkey;
  return PSBT.fromTransferPsbt(BtcTransferInfo.fromJson(transferJson));
}

String _btcAccountXpubForVersion(String mnemonic, int publicVersion) {
  final standardTestnet = BTCChain().testnet.networkType!;
  final legacyNetwork = NetworkType(
    messagePrefix: standardTestnet.messagePrefix,
    bech32: standardTestnet.bech32,
    bip32: Bip32Type(
      public: publicVersion,
      private: standardTestnet.bip32.private,
    ),
    pubKeyHash: standardTestnet.pubKeyHash,
    scriptHash: standardTestnet.scriptHash,
    wif: standardTestnet.wif,
  );
  return bitcoin.HDWallet.fromSeed(
    HDWallet.mnemonicToSeed(mnemonic),
    network: legacyNetwork,
  ).derivePath("m/44'/0'/0'").base58!;
}

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

  group('test extended-key network compatibility', () {
    test('2.0.2 BTC testnet key builds a PSBT after upgrading', () {
      const legacyTestnetPublicVersion = 0x04358a68;
      final legacyTestnetXpub = _btcAccountXpubForVersion(
        mnemonic,
        legacyTestnetPublicVersion,
      );

      expect(legacyTestnetXpub, startsWith('tpw'));

      final psbt = _buildBtcPsbtFixture(legacyTestnetXpub);

      expect(psbt.serialize(), isNotEmpty);
    });

    test('unknown checksum-valid extended-key version fails closed', () {
      final unknownVersionXpub = _btcAccountXpubForVersion(
        mnemonic,
        0x01020304,
      );

      expect(
        () => _buildBtcPsbtFixture(unknownVersionXpub),
        throwsArgumentError,
      );
    });

    for (final invalidXpub in ['', 'not-an-extended-key']) {
      test('invalid extended key "$invalidXpub" fails closed', () {
        expect(() => _buildBtcPsbtFixture(invalidXpub), throwsArgumentError);
      });
    }
  });

  group('test psbt tx signer', () {
    test('legacy verification rejects non-owner wallet', () {
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
      expect(jsonData, isNotEmpty);
      expect(broadcastData, isNotEmpty);

      // The fixture belongs to another key, so a correct verifier rejects it.
      final psbtInput = psbtTxData.psbt.inputs[0];
      final prevout = psbtInput
          .previousTransaction!
          .outputs[psbtTxData.psbt.unsignedTransaction!.inputs[0].index];
      expect(psbtInput.partialSigs, hasLength(2));
      expect(prevout.scriptPubKey.isP2PKH(), isTrue);
      expect(
        dynamicToHex(sha160fromByte(fromHex(psbtInput.partialSigs![1]))),
        isNot(dynamicToHex(prevout.scriptPubKey.commands[2])),
      );
      expect(signer.verify(), isFalse);
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
      expect(jsonData, isNotEmpty);
      expect(broadcastData, isNotEmpty);

      // Verify a signature was added.
      expect(psbtTxData.psbt.inputs[0].taprootKeySpendSignature, isNotNull);

      // `verify()` now does real BIP340 verification against each input's
      // *own* prevout output key (see F9 in the signature review). This
      // fixture's witnessUtxo belongs to a different xpub
      // (m/86'/0'/0'/0/0 under xpub6DTyU...) than `taprootWallet`, so a
      // signature from `taprootWallet` correctly fails to verify against
      // it — the same way a real Bitcoin node would reject it. See
      // test/psbt/taproot_verify_test.dart for a self-consistent
      // sign+verify (and tamper) round trip.
      expect(signer.verify(), isFalse);
      expect(signer.safeVerify(), isFalse);
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
      final script = bitcoin.Address.addressToOutputScript(
        wallet.address,
        BTCChain().mainnet.networkType,
      );

      expect(
        wallet.address,
        'bc1p5cyxnuxmeuwuvkwfem96lqzszd02n6xdcjrs20cac6yqjjwudpxqkedrcr',
      );
      expect(
        script!.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(),
        '5120a60869f0dbcf1dc659c9cecbaf8050135ea9e8cdc487053f1dc6880949dc684c',
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
      'Taproot address follows later network changes on a shared setting',
      () async {
        // The Taproot constructor keeps the caller's setting by reference
        // instead of snapshotting it, so switching the shared setting's
        // network propagates to existing and freshly derived wallets alike
        // (regression for state splitting between mainnet/testnet).
        final setting = WalletSetting(
          bip44Path: BTC_PATH,
          addressType: AddressType.BTC,
          networkType: BTCChain().mainnet.networkType,
        );
        final wallet = await BtcCoin.fromMnemonic(bip86Mnemonic, setting, true);
        final originalMainnetAddress = wallet.address;
        expect(originalMainnetAddress, startsWith('bc1p'));

        setting.networkType = BTCChain().testnet.networkType;
        expect(wallet.address, startsWith('tb1p'));

        final fresh = await BtcCoin.fromMnemonic(bip86Mnemonic, setting, true);
        expect(fresh.address, equals(wallet.address));

        setting.networkType = BTCChain().mainnet.networkType;
        expect(wallet.address, originalMainnetAddress);
        expect(fresh.address, originalMainnetAddress);
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

    test('Taproot validation rejects non-canonical witness padding', () async {
      final btcChain = BTCChain();
      final wallet = await getMnemonicWallet('taproot', bip86Mnemonic);
      final decoded = bitcoin.bech32.decode(
        wallet.address,
        encoding: 'bech32m',
      );
      final dataWithNonZeroPadding = List<int>.from(decoded.data);
      dataWithNonZeroPadding[dataWithNonZeroPadding.length - 1] |= 1;
      final nonCanonicalAddress = bitcoin.bech32.encode(
        bitcoin.Bech32(decoded.hrp, dataWithNonZeroPadding),
        encoding: 'bech32m',
      );

      expect(
        AddressUtils.checkAddressValid(nonCanonicalAddress, btcChain.mainnet),
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
      final emptyHrpWallet = await BtcCoin.fromMnemonic(
        bip86Mnemonic,
        settingForHrp(''),
        true,
      );

      expect(() => missingHrpWallet.address, throwsArgumentError);
      expect(() => invalidHrpWallet.address, throwsA(isA<Exception>()));
      expect(() => emptyHrpWallet.address, throwsA(isA<Exception>()));
    });
  });
}
