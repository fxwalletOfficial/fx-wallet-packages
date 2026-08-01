import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart'
    as btc;
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/utils/script.dart'
    show compile, decompile;

/// Regression tests for F9: GsplTxSigner.verify() previously only checked
/// that each input had a non-null `signature`, not that the signature
/// actually satisfies the sighash. A tampered signature must now be
/// rejected for DOGE (legacy DER), BCH (BIP143 DER) and LTC Taproot
/// (BIP341 Schnorr).
void main() async {
  const mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';

  GsplTxData buildTxData({int? hashType, bool singleOutput = false}) => GsplTxData(
    inputs: [
      GsplItem(path: "m/44'/2'/0'/0/0", amount: 62926, signHashType: hashType),
      GsplItem(path: "m/44'/2'/0'/0/0", amount: 82787, signHashType: hashType),
    ],
    hex: singleOutput
        ? '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff01f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac00000000'
        : '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff02f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac91b20000000000001976a9146e13c072a8c2d3216566f710a7d975fb8e593cea88ac00000000',
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

  test(
    'LTC Taproot: verify() accepts a genuine signature, rejects tampered',
    () async {
      final wallet = await LtcCoin.fromMnemonic(mnemonic, null, true);
      final signer = GsplTxSigner(wallet, buildTxData());
      signer.sign();
      expect(signer.verify(), isTrue);

      tamperFirstInputSignature(signer.txData);
      expect(signer.verify(), isFalse);
    },
  );

  test(
    'LTC Taproot: explicit sighash types are appended exactly once',
    () async {
      final wallet = await LtcCoin.fromMnemonic(mnemonic, null, true);
      final hashTypes = [
        btc.SIGHASH_ALL,
        btc.SIGHASH_NONE,
        btc.SIGHASH_SINGLE,
        btc.SIGHASH_ALL | btc.SIGHASH_ANYONECANPAY,
        btc.SIGHASH_NONE | btc.SIGHASH_ANYONECANPAY,
        btc.SIGHASH_SINGLE | btc.SIGHASH_ANYONECANPAY,
      ];

      for (final hashType in hashTypes) {
        final signer = GsplTxSigner(wallet, buildTxData(hashType: hashType));
        signer.sign();

        final signedTx = btc.Transaction.fromHex(signer.txData.hex);
        for (var i = 0; i < signedTx.ins.length; i++) {
          expect(signer.txData.inputs[i].signature, hasLength(64));
          expect(signedTx.ins[i].witness, hasLength(1));
          expect(signedTx.ins[i].witness![0], hasLength(65));
          expect(signedTx.ins[i].witness![0]!.last, hashType);
        }
        expect(signer.verify(), isTrue, reason: 'hashType=$hashType');
      }
    },
  );

  test(
    'LTC Taproot: SIGHASH_SINGLE rejects an input without a matching output',
    () async {
      final wallet = await LtcCoin.fromMnemonic(mnemonic, null, true);
      final signer = GsplTxSigner(
        wallet,
        buildTxData(
          hashType: btc.SIGHASH_SINGLE,
          singleOutput: true,
        ),
      );

      expect(signer.sign, throwsArgumentError);
    },
  );

  test(
    'LTC Taproot: verify() rejects a witness removed from signed hex',
    () async {
      final wallet = await LtcCoin.fromMnemonic(mnemonic, null, true);
      final signer = GsplTxSigner(wallet, buildTxData());
      signer.sign();

      final signedTx = btc.Transaction.fromHex(signer.txData.hex);
      signedTx.ins[0].witness = [];
      signer.txData.hex = signedTx.toHex();

      expect(signer.verify(), isFalse);
    },
  );

  test(
    'DOGE: verify() accepts a genuine signature, rejects tampered',
    () async {
      final wallet = await DogeCoin.fromMnemonic(mnemonic);
      final signer = GsplTxSigner(wallet, buildTxData());
      signer.sign();
      expect(signer.verify(), isTrue);

      tamperFirstInputSignature(signer.txData);
      expect(signer.verify(), isFalse);
    },
  );

  test('DOGE: all supported sighash types round-trip', () async {
    final wallet = await DogeCoin.fromMnemonic(mnemonic);
    final hashTypes = [
      btc.SIGHASH_ALL,
      btc.SIGHASH_NONE,
      btc.SIGHASH_SINGLE,
      btc.SIGHASH_ALL | btc.SIGHASH_ANYONECANPAY,
      btc.SIGHASH_NONE | btc.SIGHASH_ANYONECANPAY,
      btc.SIGHASH_SINGLE | btc.SIGHASH_ANYONECANPAY,
    ];

    for (final hashType in hashTypes) {
      final signer = GsplTxSigner(wallet, buildTxData(hashType: hashType));
      signer.sign();

      final signedTx = btc.Transaction.fromHex(signer.txData.hex);
      for (var i = 0; i < signedTx.ins.length; i++) {
        final chunks = decompile(signedTx.ins[i].script!);
        expect(chunks, hasLength(2));
        expect(chunks![0], signer.txData.inputs[i].signature);
        expect((chunks[0] as Uint8List).last, hashType);
      }
      expect(signer.verify(), isTrue, reason: 'hashType=$hashType');
    }
  });

  test('LTC legacy: all supported sighash types round-trip', () async {
    final wallet = await LtcCoin.fromMnemonic(mnemonic);
    final hashTypes = [
      btc.SIGHASH_ALL,
      btc.SIGHASH_NONE,
      btc.SIGHASH_SINGLE,
      btc.SIGHASH_ALL | btc.SIGHASH_ANYONECANPAY,
      btc.SIGHASH_NONE | btc.SIGHASH_ANYONECANPAY,
      btc.SIGHASH_SINGLE | btc.SIGHASH_ANYONECANPAY,
    ];

    for (final hashType in hashTypes) {
      final signer = GsplTxSigner(wallet, buildTxData(hashType: hashType));
      signer.sign();

      final signedTx = btc.Transaction.fromHex(signer.txData.hex);
      for (var i = 0; i < signedTx.ins.length; i++) {
        final chunks = decompile(signedTx.ins[i].script!);
        expect(chunks, hasLength(2));
        expect(chunks![0], signer.txData.inputs[i].signature);
        expect((chunks[0] as Uint8List).last, hashType);
      }
      expect(signer.verify(), isTrue, reason: 'hashType=$hashType');
    }
  });

  test('BCH: all supported sighash types round-trip', () async {
    final wallet = await BchCoin.fromMnemonic(mnemonic);
    final baseHashTypes = [
      btc.SIGHASH_ALL,
      btc.SIGHASH_NONE,
      btc.SIGHASH_SINGLE,
      btc.SIGHASH_ALL | btc.SIGHASH_ANYONECANPAY,
      btc.SIGHASH_NONE | btc.SIGHASH_ANYONECANPAY,
      btc.SIGHASH_SINGLE | btc.SIGHASH_ANYONECANPAY,
    ];

    for (final baseHashType in baseHashTypes) {
      final expectedHashType = baseHashType | btc.SIGHASH_BITCOINCASHBIP143;
      final signer = GsplTxSigner(wallet, buildTxData(hashType: baseHashType));
      signer.sign();

      final signedTx = btc.Transaction.fromHex(signer.txData.hex);
      for (var i = 0; i < signedTx.ins.length; i++) {
        final chunks = decompile(signedTx.ins[i].script!);
        expect(chunks, hasLength(2));
        expect(chunks![0], signer.txData.inputs[i].signature);
        expect((chunks[0] as Uint8List).last, expectedHashType);
      }
      expect(signer.verify(), isTrue, reason: 'hashType=$expectedHashType');
    }
  });

  test('DOGE: verify() rejects a scriptSig removed from signed hex', () async {
    final wallet = await DogeCoin.fromMnemonic(mnemonic);
    final signer = GsplTxSigner(wallet, buildTxData());
    signer.sign();

    final signedTx = btc.Transaction.fromHex(signer.txData.hex);
    signedTx.ins[0].script = btc.EMPTY_SCRIPT;
    signer.txData.hex = signedTx.toHex();

    expect(signer.verify(), isFalse);
  });

  test(
    'DOGE: verify() rejects a serialized sighash/metadata mismatch',
    () async {
      final wallet = await DogeCoin.fromMnemonic(mnemonic);
      final signer = GsplTxSigner(wallet, buildTxData());
      signer.sign();

      final original = signer.txData.inputs[0];
      final altered = Uint8List.fromList(original.signature!);
      altered[altered.length - 1] = btc.SIGHASH_NONE;
      signer.txData.inputs[0] = GsplItem(
        path: original.path,
        amount: original.amount,
        address: original.address,
        signHashType: original.signHashType,
        signature: altered,
      );

      final signedTx = btc.Transaction.fromHex(signer.txData.hex);
      signedTx.ins[0].script = compile([altered, wallet.publicKey]);
      signer.txData.hex = signedTx.toHex();

      expect(signer.verify(), isFalse);
    },
  );

  test('DOGE: verify() rejects signed transaction body tampering', () async {
    final wallet = await DogeCoin.fromMnemonic(mnemonic);

    final sequenceSigner = GsplTxSigner(wallet, buildTxData());
    sequenceSigner.sign();
    final sequenceTx = btc.Transaction.fromHex(sequenceSigner.txData.hex);
    sequenceTx.ins[0].sequence = sequenceTx.ins[0].sequence! - 1;
    sequenceSigner.txData.hex = sequenceTx.toHex();
    expect(sequenceSigner.verify(), isFalse);

    final outputSigner = GsplTxSigner(wallet, buildTxData());
    outputSigner.sign();
    final outputTx = btc.Transaction.fromHex(outputSigner.txData.hex);
    outputTx.outs[0].value = outputTx.outs[0].value! - 1;
    outputSigner.txData.hex = outputTx.toHex();
    expect(outputSigner.verify(), isFalse);
  });

  test('BCH: verify() accepts a genuine signature, rejects tampered', () async {
    final wallet = await BchCoin.fromMnemonic(mnemonic);
    final signer = GsplTxSigner(wallet, buildTxData());
    signer.sign();
    expect(signer.verify(), isTrue);

    tamperFirstInputSignature(signer.txData);
    expect(signer.verify(), isFalse);
  });

  test(
    'LTC legacy: verify() accepts a genuine signature, rejects tampered',
    () async {
      final wallet = await LtcCoin.fromMnemonic(mnemonic);
      final signer = GsplTxSigner(wallet, buildTxData());
      signer.sign();
      expect(signer.verify(), isTrue);

      tamperFirstInputSignature(signer.txData);
      expect(signer.verify(), isFalse);
    },
  );
}
