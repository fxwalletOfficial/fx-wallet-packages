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

/// Regression tests for F9: PsbtTxSigner.verify() previously only checked
/// that `partialSigs` was non-empty for legacy P2PKH inputs, not that the
/// DER signature actually satisfies the sighash. This builds a
/// self-consistent one-input legacy PSBT so a real sign+verify (and tamper
/// negative control) is possible.
void main() async {
  const mnemonic =
      'few tag video grain jealous light tired vapor shed festival shine tag';
  final wallet = await BtcCoin.fromMnemonic(mnemonic);

  PsbtTxData buildLegacyTxData() {
    final address = wallet.publicKeyToAddress(wallet.publicKey);
    final scriptPubKey = ScriptPublicKey.p2pkh(address);

    final input = TransactionInput.forSending('a1' * 32, 0);
    final output = TransactionOutput(
      Converter.intToLittleEndianBytes(50000, 8),
      scriptPubKey,
    );
    final unsignedTx =
        Transaction.forSending([input], [output], false, version: 2);
    final unsignedTxHex = unsignedTx.serializeLegacy();

    final prevTx = Transaction.forSending(
      [TransactionInput.forSending('b2' * 32, 0)],
      [
        TransactionOutput(
            Converter.intToLittleEndianBytes(100000, 8), scriptPubKey)
      ],
      false,
      version: 2,
    );

    final psbtMap = {
      'global': {'00': unsignedTxHex},
      'inputs': [
        {'00': prevTx.serializeLegacy()}
      ],
      'outputs': [
        {}
      ],
    };

    final psbt = PSBT(psbtMap);
    return PsbtTxData(psbt, '', false);
  }

  test('sign + verify succeeds for a genuine P2PKH input', () {
    final txData = buildLegacyTxData();
    final signer = PsbtTxSigner(wallet, txData);
    signer.sign();
    expect(signer.verify(), isTrue);
  });

  test('verify fails when the DER signature is tampered', () {
    final txData = buildLegacyTxData();
    final signer = PsbtTxSigner(wallet, txData);
    signer.sign();

    final input = txData.psbt.inputs[0];
    final sig = input.partialSigs![0];
    final tamperedByte =
        (int.parse(sig.substring(0, 2), radix: 16) ^ 0xff).toRadixString(16).padLeft(2, '0');
    // Overwrite the partial sig directly (bypasses re-deriving from a key).
    input.partialSigs![0] = tamperedByte + sig.substring(2);

    expect(signer.verify(), isFalse);
  });
}
