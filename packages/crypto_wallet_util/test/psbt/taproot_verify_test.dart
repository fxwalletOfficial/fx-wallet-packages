import 'package:test/test.dart';

import 'package:crypto_wallet_util/wallets.dart';
import 'package:crypto_wallet_util/src/transaction/btc/psbt_tx_data.dart';
import 'package:crypto_wallet_util/src/transaction/btc/psbt_tx_signer.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/psbt.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/transaction.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/transaction_input.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/transaction_output.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/transaction/script_public_key.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/utils/converter.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/utils/varints.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart'
    as bf;

/// Regression tests for F9: PsbtTxSigner.verify() previously only checked
/// that a `taprootKeySpendSignature`/`partialSigs` field was present, not
/// that the signature actually satisfies the input it claims to spend.
/// This builds a self-consistent one-input Taproot PSBT — the prevout's
/// witnessUtxo scriptPubKey genuinely is [wallet]'s own P2TR output key, so
/// a real end-to-end sign+verify (and a tamper negative control) is
/// possible.
void main() async {
  const mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final wallet = await BtcCoin.fromMnemonic(mnemonic, null, true);

  PsbtTxData buildTaprootTxData({int sequence = 0xffffffff}) {
    final address = wallet.publicKeyToAddress(wallet.publicKey);
    final outputScript =
        bf.Address.addressToOutputScript(address, bf.bitcoin)!;
    // ScriptPublicKey.parse() expects a varint length prefix ahead of the
    // raw script bytes (as it appears inside a serialized CTxOut).
    final prefixedScriptHex = Converter.bytesToHex(
            Varints.encode(outputScript.length)) +
        Converter.bytesToHex(outputScript);
    final scriptPubKey = ScriptPublicKey.parse(prefixedScriptHex);

    final input = TransactionInput.forSending(
      'a1' * 32, // arbitrary previous txid
      0,
      sequence: sequence,
    );
    final output = TransactionOutput(
      Converter.intToLittleEndianBytes(50000, 8),
      scriptPubKey,
    );
    final unsignedTx =
        Transaction.forSending([input], [output], false, version: 2);
    final unsignedTxHex = unsignedTx.serializeLegacy();

    final witnessUtxo = TransactionOutput(
      Converter.intToLittleEndianBytes(100000, 8),
      scriptPubKey,
    );

    final psbtMap = <String, dynamic>{
      'global': <String, dynamic>{'00': unsignedTxHex},
      'inputs': [
        <String, dynamic>{'01': witnessUtxo.serialize()}
      ],
      'outputs': [
        <String, dynamic>{}
      ],
    };

    final psbt = PSBT(psbtMap);
    // getSignedTxHex() re-derives the origin transaction from this hex
    // string (not from the in-memory `psbt` object), so it must be a
    // properly serialized PSBT for the F5 sequence-preservation test below.
    final unsignedPsbtHex = psbt.serialize();
    return PsbtTxData(psbt, unsignedPsbtHex, true);
  }

  test('sign + verify succeeds for a genuinely self-owned P2TR input', () {
    final txData = buildTaprootTxData();
    final signer = PsbtTxSigner(wallet, txData);
    signer.sign();
    expect(signer.verify(), isTrue);
  });

  test('verify fails when the taproot signature is tampered', () {
    final txData = buildTaprootTxData();
    final signer = PsbtTxSigner(wallet, txData);
    signer.sign();

    final input = txData.psbt.inputs[0];
    final sig = input.taprootKeySpendSignature!;
    final tamperedByte =
        (int.parse(sig.substring(0, 2), radix: 16) ^ 0xff).toRadixString(16).padLeft(2, '0');
    input.setTaprootKeySpendSignature(tamperedByte + sig.substring(2));

    expect(signer.verify(), isFalse);
  });

  test('verify fails when a different wallet signs someone else\'s prevout',
      () async {
    final otherWallet = await BtcCoin.fromMnemonic(
        'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        null,
        true);
    final txData = buildTaprootTxData();
    final signer = PsbtTxSigner(otherWallet, txData);
    signer.sign();
    expect(signer.verify(), isFalse);
  });

  test(
      'F5: getSignedTxHex() preserves a non-default input sequence instead '
      'of resetting it to 0xffffffff', () {
    const rbfSequence = 0xfffffffd; // signals replace-by-fee, not the default
    final txData = buildTaprootTxData(sequence: rbfSequence);
    final signer = PsbtTxSigner(wallet, txData);
    signer.sign();
    expect(signer.verify(), isTrue);

    final signedHex = txData.getSignedTxHex();
    final signedTx = bf.Transaction.fromHex(signedHex);

    expect(signedTx.ins[0].sequence, rbfSequence);
    // A regression here would silently invalidate the signature too — the
    // BIP341 sighash commits to sequence, and getSignedTxHex() must emit
    // exactly the sequence that was signed over.
  });
}
