import 'package:crypto_wallet_util/src/transaction/scp/scp_lib.dart';
import 'package:crypto_wallet_util/src/transaction/scp/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';

/// Signs a [ScpTxData] by producing Ed25519 signatures for each digest in
/// [ScpTxData.toSign] and writing them into the transaction's
/// `transactionSignatures[*].signature` slots (base64-encoded).
class ScpTxSigner extends TxSigner {
  @override
  final ScpTxData txData;

  ScpTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  ScpTxData sign() {
    final sigs = txData.transactionSignatures;
    if (sigs.length != txData.toSign.length) {
      throw StateError(
          'transactionSignatures length (${sigs.length}) must match '
          'toSign length (${txData.toSign.length})');
    }

    // Build the mutable list of signature entries in the transaction map
    final txSigsList = (txData.transaction['transactionSignatures'] as List?) ??
        <dynamic>[];

    for (int i = 0; i < txData.toSign.length; i++) {
      // wallet.sign() returns base64-encoded ed25519 signature — exactly what
      // SCP expects in transactionSignatures[*].signature.
      final base64Sig = wallet.sign(txData.toSign[i]);

      // Update the model object
      sigs[i] = ScpTransactionSignature(
        parentID: sigs[i].parentID,
        publicKeyIndex: sigs[i].publicKeyIndex,
        coveredFields: sigs[i].coveredFields,
        signature: base64Sig,
      );

      // Update the transaction map
      if (i < txSigsList.length) {
        (txSigsList[i] as Map)['signature'] = base64Sig;
      }
    }

    if (txData.toSign.isNotEmpty) {
      txData.message = txData.toSign.first;
      txData.signature = sigs.first.signature;
    }
    txData.isSigned = true;
    return txData;
  }

  @override
  bool verify() {
    if (!txData.isSigned) return false;
    final sigs = txData.transactionSignatures;
    if (sigs.length != txData.toSign.length) return false;

    for (int i = 0; i < txData.toSign.length; i++) {
      final sig = sigs[i].signature;
      if (sig.isEmpty) return false;
      // wallet.verify expects (base64Signature, hexMessage)
      if (!wallet.verify(sig, txData.toSign[i])) {
        return false;
      }
    }
    return true;
  }
}
