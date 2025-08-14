import 'dart:math';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/cosmos_dart.dart';
import 'package:crypto_wallet_util/crypto_utils.dart';

void main() {
  const String TEST_MNEMONIC =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  test('atom', () async {
    final wallet = await Cosmos.fromMnemonic(TEST_MNEMONIC);
    expect(wallet.address, 'cosmos1qdr230h75w6clmqvzwagsu3s5e6mlsynhh200x');
  });
  test('sei', () async {
    final setting = WalletSetting(bip44Path: ATOM_PATH, prefix: 'sei');
    final wallet = await Cosmos.fromMnemonic(TEST_MNEMONIC, setting);
    expect(wallet.address, 'sei1qdr230h75w6clmqvzwagsu3s5e6mlsyn6mmef8');
  });

  test('kava', () async {
    final setting = WalletSetting(bip44Path: KAVA_PATH, prefix: 'kava');
    final wallet = await Cosmos.fromMnemonic(TEST_MNEMONIC, setting);
    expect(wallet.address, 'kava16cmj4yxnqllcx2e480j2tgw43tvd753x7l9tfk');
  });
  test('cosmos transaction', () async {
    final message = MsgSend.create()
      ..fromAddress = 'kava1qu252p5jwrafawgmns47wzgqfrjg3qp5ugg8rs'
      ..toAddress = 'kava1qu252p5jwrafawgmns47wzgqfrjg3qp5ugg8rs';
    message.amount.add(
      CosmosCoin.create()
        ..denom = 'ukava'
        ..amount = (1 * pow(10, 6)).toInt().toString(),
    );
    final signerData = SignerData(
        accountNumber: 2292857.toInt64(),
        chainId: 'kava_2222-10',
        sequence: 37.toInt64());
    Fee fee = Fee();
    fee.gasLimit = 109963.toInt64();
    fee.amount.add(
      CosmosCoin.create()
        ..amount = '2750'
        ..denom = 'ukava',
    );

    final mnemonic =
        'number vapor draft title message quarter hour other hotel leave shrug donor';
    final wallet = await getMnemonicWallet('kava', mnemonic);
    final CosmosTxData txData =
        CosmosTxData(msgs: [message], data: signerData, fee: fee);

    final jsonData = txData.toJson();
    expect(jsonData, isEmpty);
    final broadcastData = txData.toBroadcast();
    expect(broadcastData, isEmpty);

    final CosmosTxSigner signer = CosmosTxSigner(wallet, txData);
    signer.sign();
    expect(signer.sign(),
        '0a8f010a8c010a1c2f636f736d6f732e62616e6b2e763162657461312e4d736753656e64126c0a2b6b61766131717532353270356a777261666177676d6e733437777a677166726a6733717035756767387273122b6b61766131717532353270356a777261666177676d6e733437777a677166726a67337170357567673872731a100a05756b61766112073130303030303012670a500a460a1f2f636f736d6f732e63727970746f2e736563703235366b312e5075624b657912230a21027957eb8ee7710fdd7db15ba71651c6e8598d1bff74da348726b85fb349511d7012040a020801182512130a0d0a05756b617661120432373530108bdb061a40a53cb6135b922c535b26ead8e4a963017058ea2200510914e1090138976c67041fca8a343b68439fbd41ee1677d75e86ce0ec62ee700abe6a38ac4a3b869bda1');
    assert(signer.verify());
  });
}
