import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/transaction/ckb/tx_data.dart';
import 'package:crypto_wallet_util/src/transaction/ckb/tx_signer.dart';
import 'package:crypto_wallet_util/src/transaction/ckb/lib/ckb_lib.dart'
    as ckb_lib;
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

  test('ckb data', () async {
    const mnemonic =
        'few tag video grain jealous light tired vapor shed festival shine tag';
    final wallet = await CkbCoin.fromMnemonic(mnemonic);
    final longAddress = wallet.toLongAddress();
    final script =
        ckb_lib.Script.fromAddress(longAddress, ckb_lib.AddressType.LONG);
    expect(script.hashType, 'type');
    expect(ckb_lib.hashTypeToCode('data1'), 2);
    expect(() => ckb_lib.hashTypeToCode('error'), throwsArgumentError);

    expect(ckb_lib.codeToHashType(0), 'data');
    expect(ckb_lib.codeToHashType(1), 'type');
    expect(ckb_lib.codeToHashType(2), 'data1');
    expect(() => ckb_lib.codeToHashType(3), throwsArgumentError);

    final uInt32 = ckb_lib.UInt32.fromBytes(Uint8List.fromList([1,2,3,4]));
    final uInt64 = ckb_lib.UInt64.fromBytes(Uint8List.fromList([1,2,3,4,5,6,7,8]));
    final byte32 = ckb_lib.Byte32.fromHex('0x12');
    expect(uInt32.getValue(),67305985);
    expect(uInt64.getValue(),BigInt.from(578437695752307201));
    expect(byte32.getValue().toStr(),'1200000000000000000000000000000000000000000000000000000000000000');

    final emptySerializeType = ckb_lib.EmptySerializeType();
    expect(emptySerializeType.getLength(), 0);
    emptySerializeType.getValue();
    expect(emptySerializeType.toBytes(), []);
  });
}
