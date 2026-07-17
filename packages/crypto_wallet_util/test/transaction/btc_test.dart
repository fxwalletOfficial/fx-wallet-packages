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
      final jsonData = signedTxData.toJson();
      final broadcastData = signedTxData.toBroadcast();
      assert(jsonData.isNotEmpty);
      assert(broadcastData.isNotEmpty);

      // Verify signatures were added
      expect(signer.verify(), isTrue);
    });

    test('taproot signature generation', () {
      // Create PSBT transaction data and signer
      final psbtTxData =
          PsbtTxData.fromHash(taprootUnsignedPsbt, isTaproot: true);
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

  // Regression test for #74: BTC testnet address should not be misidentified as BCH
  group('testnet address generation and detection', () {
    test('BTC testnet address should use correct version byte (0x6f)', () async {
      const mnemonic = 'assault assault assault assault assault assault assault assault assault assault assault about';
      final btcChain = BTCChain();
      final wallet = await BtcCoin.fromMnemonic(mnemonic, btcChain.testnet);
      final address = wallet.address;

      // Should generate testnet format address (m/n... for legacy, tb1... for segwit)
      expect(address.startsWith('m') || address.startsWith('n') || address.startsWith('tb1'), isTrue,
          reason: 'BTC testnet address should start with m/n/tb1, got: $address');
    });

    test('BTC testnet address should be detected as BTC, not BCH', () async {
      const mnemonic = 'assault assault assault assault assault assault assault assault assault assault assault about';
      final btcChain = BTCChain();
      final bchChain = BCHChain();

      final wallet = await BtcCoin.fromMnemonic(mnemonic, btcChain.testnet);
      final address = wallet.address;

      // Should be valid for BTC testnet
      final isBtcValid = AddressUtils.checkAddressValid(address, btcChain.testnet);
      expect(isBtcValid, isTrue, reason: 'BTC testnet address should be valid for BTC testnet');

      // Should NOT be valid for BCH testnet (BCH testnet uses pubKeyHash: 0x00, BTC testnet uses 0x6f)
      final isBchValid = AddressUtils.checkAddressValid(address, bchChain.testnet);
      expect(isBchValid, isFalse, reason: 'BTC testnet address should NOT be valid for BCH testnet');
    });

    test('BTC mainnet address format unchanged', () async {
      const mnemonic = 'assault assault assault assault assault assault assault assault assault assault assault about';
      final btcChain = BTCChain();
      final wallet = await BtcCoin.fromMnemonic(mnemonic, btcChain.mainnet);
      final address = wallet.address;

      // Mainnet should still generate 1.../bc1... addresses
      expect(address.startsWith('1') || address.startsWith('3') || address.startsWith('bc1'), isTrue,
          reason: 'BTC mainnet address should start with 1/3/bc1, got: $address');
    });
  });
}
