import 'dart:io';

import 'package:crypto_wallet_util/src/transaction/ckb/tx_data.dart';
import 'package:crypto_wallet_util/src/transaction/ckb/tx_signer.dart';
import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/ckb.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

void main() async {
  const String mnemonic =
      'fly lecture gasp juice hover ice business census bless weapon polar upgrade';
  final ckb = await CkbCoin.fromMnemonic(mnemonic);

  test('short to long address', () async {
    // default short address
    final shortAddress = await ckb.mnemonicToAddress(mnemonic);
    expect(shortAddress, 'ckb1qyqq54yhj5y3fmtfu6tw6jpapp222gs94zfsns98e7');
    final longAddress = ckb.toLongAddress();
    expect(longAddress,
        'ckb1qzda0cr08m85hc8jlnfp3zer7xulejywt49kt2rr0vthywaa50xwsqg22jte2zg5a457d9hdfq7ss499ygz63ycxv2rt3');
  });
  test('test sign', () async {
    final transactionJson = json.decode(File('./test/transaction/data/ckb.json')
        .readAsStringSync(encoding: utf8));
    final txData = CkbTxData.fromJson(transactionJson);
    final txSigner = CkbTxSigner(ckb, txData);
    final signedTxData = txSigner.sign();
    assert(txSigner.verify());
    expect(signedTxData.witnesses, [
      '0x5500000010000000550000005500000041000000f434e961907533ad999daa7cd6de1aead0232a72be562bd5fa043f64f260fd337d8963799cd802502c178008b99222b265116e137c74359cf678c014361cf1f400',
      '0x'
    ]);

    final broadcastData = signedTxData.toBroadcast();
    final jsonData = signedTxData.toJson();
    expect(jsonData['hash'], broadcastData['hash']);
  });
}
