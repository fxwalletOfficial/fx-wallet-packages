import 'dart:convert';

import 'package:crypto_wallet_util/src/transaction/sc/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Signs a [ScTxData] by producing Ed25519 signatures for each digest in
/// [ScTxData.toSign] and writing them into the V2 transaction's
/// `satisfiedPolicy.signatures` slots.
class ScTxSigner extends TxSigner {
  @override
  final ScTxData txData;

  ScTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  ScTxData sign() {
    final inputs =
        (txData.transaction['siacoinInputs'] as List<dynamic>?) ?? [];
    if (inputs.length != txData.toSign.length) {
      throw StateError(
          'siacoinInputs length (${inputs.length}) must match '
          'toSign length (${txData.toSign.length})');
    }

    for (int i = 0; i < txData.toSign.length; i++) {
      // wallet.sign() returns base64-encoded ed25519 signature.
      // The V2 transaction expects hex-encoded signatures.
      final base64Sig = wallet.sign(txData.toSign[i]);
      final sigBytes = base64.decode(base64Sig);
      final sigHex = dynamicToString(sigBytes);

      (inputs[i]['satisfiedPolicy'] as Map)['signatures'] = [sigHex];
    }

    if (txData.toSign.isNotEmpty) {
      txData.message = txData.toSign.first;
      final firstSigs =
          (inputs.first['satisfiedPolicy'] as Map)['signatures'] as List;
      txData.signature = firstSigs.first as String;
    }
    txData.isSigned = true;
    return txData;
  }

  @override
  bool verify() {
    if (!txData.isSigned) return false;
    final inputs =
        (txData.transaction['siacoinInputs'] as List<dynamic>?) ?? [];
    if (inputs.length != txData.toSign.length) return false;

    for (int i = 0; i < txData.toSign.length; i++) {
      final sigs =
          (inputs[i]['satisfiedPolicy'] as Map)['signatures'] as List;
      if (sigs.isEmpty) return false;
      final sigHex = sigs.first as String;
      final sigBytes = dynamicToUint8List(sigHex);
      final sigBase64 = base64.encode(sigBytes);
      if (!wallet.verify(sigBase64, txData.toSign[i])) {
        return false;
      }
    }
    return true;
  }
}
