import 'package:test/test.dart';

import 'package:crypto_wallet_util/crypto_utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart'
    as btc;
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Regression tests for F3: GSPL LTC Taproot inputs used to be hashed with
/// BIP143 (`hashForWitnessV0`) and the resulting "signature" was compiled
/// into `scriptSig`, which is wrong on both counts for a P2TR key-path
/// spend (wrong sighash algorithm, and P2TR has no scriptSig at all — the
/// signature belongs in the witness stack). These tests check the fixed
/// output structurally (empty scriptSig, one witness element) and
/// cryptographically: the witness signature must be a valid BIP340 Schnorr
/// signature over the BIP341 TapSighash, verified against the address's
/// tweaked output key with the `bip340` package (an independent verifier,
/// not the codebase's own signer).
void main() async {
  const String mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final ltcTaprootWallet = await LtcCoin.fromMnemonic(mnemonic, null, true);

  final txData = GsplTxData(
    inputs: [
      GsplItem(path: "m/44'/2'/0'/0/0", amount: 62926),
      GsplItem(path: "m/44'/2'/0'/0/0", amount: 82787),
    ],
    hex:
        '0200000002d2bc522ea66a05ba9227b412b2aec5d4d2e98b6d3c84bfabf631154ed83ca7290100000000ffffffffda4b00c6bcc8e12b34906e26cf640e6c604ea5166a6bd15e8b8bf23366b528870100000000ffffffff02f9840100000000001976a9142eb6d82fc6e056c5ae7b98c8fb64e15ce3e8de1288ac91b20000000000001976a9146e13c072a8c2d3216566f710a7d975fb8e593cea88ac00000000',
    change: null,
    dataType: BtcSignDataType.TRANSACTION,
  );

  test('taproot input: empty scriptSig, single witness element', () {
    final signer = GsplTxSigner(ltcTaprootWallet, txData);
    final signed = signer.sign();

    final signedTx = btc.Transaction.fromHex(signed.hex);
    for (final input in signedTx.ins) {
      expect(input.script, isEmpty,
          reason: 'P2TR key-path spend must not use scriptSig');
      expect(input.witness, isNotNull);
      expect(input.witness!.length, 1,
          reason: 'key-path spend witness is just the signature');
      final sig = input.witness![0]!;
      expect(sig.length, anyOf(64, 65));
    }
  });

  test('witness signature verifies against BIP341 sighash + tweaked pubkey',
      () {
    final address = ltcTaprootWallet.publicKeyToAddress(ltcTaprootWallet.publicKey);
    final outputScript =
        btc.Address.addressToOutputScript(address, ltcTaprootWallet.setting.networkType!)!;
    // P2TR scriptPubKey = OP_1 (0x51) + push32 (0x20) + 32-byte tweaked x-only key.
    final tweakedPubkey = outputScript.sublist(2);

    final signer = GsplTxSigner(ltcTaprootWallet, txData);
    final signed = signer.sign();
    final signedTx = btc.Transaction.fromHex(signed.hex);

    // Recompute the sighash independently from the *unsigned* transaction,
    // mirroring what a real verifier (or a different wallet) would compute.
    final unsignedTx = btc.Transaction.fromHex(txData.hex);
    final scripts = [outputScript, outputScript];
    final values = [62926, 82787];

    for (int i = 0; i < signedTx.ins.length; i++) {
      final witnessSig = signedTx.ins[i].witness![0]!;
      final hashType = witnessSig.length == 65 ? witnessSig[64] : 0x00;
      final rawSig = witnessSig.length == 65
          ? witnessSig.sublist(0, 64)
          : witnessSig;

      final sigHash =
          unsignedTx.hashForWitnessV1(i, scripts, values, hashType, null, null);

      final verified = Schnorr.verify(
        tweakedPubkey,
        dynamicToString(rawSig),
        dynamicToString(sigHash),
      );
      expect(verified, isTrue, reason: 'input $i witness signature must verify');
    }
  });
}
