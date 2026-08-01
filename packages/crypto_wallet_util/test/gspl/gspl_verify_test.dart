import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';

/// Regression tests for F9: GsplTxSigner.verify() previously only checked
/// that each input had a non-null `signature`, not that the signature
/// actually satisfies the sighash. A tampered signature must now be
/// rejected for DOGE (legacy DER), BCH (BIP143 DER) and LTC Taproot
/// (BIP341 Schnorr).
void main() async {
  const mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';

  GsplTxData buildTxData() => GsplTxData(
        inputs: [
          GsplItem(path: "m/44'/2'/0'/0/0", amount: 62926),
          GsplItem(path: "m/44'/2'/0'/0/0", amount: 82787),
        ],
        hex:
            '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff02f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac91b20000000000001976a9146e13c072a8c2d3216566f710a7d975fb8e593cea88ac00000000',
        change: null,
        dataType: BtcSignDataType.TRANSACTION,
      );

  void tamperFirstInputSignature(GsplTxData txData) {
    final original = txData.inputs[0];
    final sig = Uint8List.fromList(original.signature!);
    sig[0] ^= 0xff;
    txData.inputs[0] = GsplItem(
      path: original.path,
      amount: original.amount,
      address: original.address,
      signHashType: original.signHashType,
      signature: sig,
    );
  }

  test('LTC Taproot: verify() accepts a genuine signature, rejects tampered',
      () async {
    final wallet = await LtcCoin.fromMnemonic(mnemonic, null, true);
    final signer = GsplTxSigner(wallet, buildTxData());
    signer.sign();
    expect(signer.verify(), isTrue);

    tamperFirstInputSignature(signer.txData);
    expect(signer.verify(), isFalse);
  });

  test('DOGE: verify() accepts a genuine signature, rejects tampered',
      () async {
    final wallet = await DogeCoin.fromMnemonic(mnemonic);
    final signer = GsplTxSigner(wallet, buildTxData());
    signer.sign();
    expect(signer.verify(), isTrue);

    tamperFirstInputSignature(signer.txData);
    expect(signer.verify(), isFalse);
  });

  test('BCH: verify() accepts a genuine signature, rejects tampered',
      () async {
    final wallet = await BchCoin.fromMnemonic(mnemonic);
    final signer = GsplTxSigner(wallet, buildTxData());
    signer.sign();
    expect(signer.verify(), isTrue);

    tamperFirstInputSignature(signer.txData);
    expect(signer.verify(), isFalse);
  });

  test('LTC legacy: verify() accepts a genuine signature, rejects tampered',
      () async {
    final wallet = await LtcCoin.fromMnemonic(mnemonic);
    final signer = GsplTxSigner(wallet, buildTxData());
    signer.sign();
    expect(signer.verify(), isTrue);

    tamperFirstInputSignature(signer.txData);
    expect(signer.verify(), isFalse);
  });
}
