import 'package:crypto_wallet_util/src/transaction/btc/psbt_tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/utils.dart';

/// PSBT transaction signer for Bitcoin Legacy and Taproot transactions
class PsbtTxSigner extends TxSigner {
  @override
  final PsbtTxData txData;

  PsbtTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);
  @override
  PsbtTxData sign() {
    if (txData.isTaproot) {
      _signTaprootInputs();
    } else {
      _signLegacyInputs();
    }
    txData.isSigned = true;
    return txData;
  }

  /// Sign Legacy P2PKH transaction inputs
  void _signLegacyInputs() {
    for (int i = 0; i < txData.psbt.inputs.length; i++) {
      final input = txData.psbt.inputs[i];

      if (input.previousTransaction != null) {
        final prevTx = input.previousTransaction!;
        final outputIndex = txData.psbt.unsignedTransaction!.inputs[i].index;
        final prevOutput = prevTx.outputs[outputIndex];

        // Get proper signature hash using Bitcoin standard method
        final utxoSerialized = prevOutput.serialize();
        final sigHashHex = txData.psbt.unsignedTransaction!.getSigHash(
          i,
          utxoSerialized,
          false, // isSegwit - false for legacy P2PKH
        );

        // Sign transaction hash using ECDSA
        final signature = wallet.sign(sigHashHex);

        // Add signature to PSBT (use dynamicToString to avoid 0x prefix)
        txData.psbt.addSignature(i, signature, wallet.publicKey.toStr());
      }
    }
  }

  /// Sign Taproot P2TR transaction inputs
  void _signTaprootInputs() {
    for (int i = 0; i < txData.psbt.inputs.length; i++) {
      final input = txData.psbt.inputs[i];

      // Taproot transactions use witness UTXO
      if (input.witnessUtxo != null) {
        final utxo = input.witnessUtxo!;

        // Use SegWit signature hash for Taproot (SegWit v1)
        final utxoSerialized = utxo.serialize();
        final sigHashHex = txData.psbt.unsignedTransaction!.getSigHash(
          i,
          utxoSerialized,
          true, // isSegwit - true for Taproot
        );

        // Generate Schnorr signature for Taproot
        final signature = wallet.sign(sigHashHex);

        // Set taproot key spend signature
        txData.psbt.inputs[i].setTaprootKeySpendSignature(signature);
      }
    }
  }

  @override
  bool verify() {
    // Verify all inputs have been signed
    for (int i = 0; i < txData.psbt.inputs.length; i++) {
      final input = txData.psbt.inputs[i];

      if (txData.isTaproot) {
        // Check if Taproot signature exists
        if (input.taprootKeySpendSignature == null) {
          return false;
        }
      } else {
        // Check if Legacy signature exists
        if (input.partialSigs == null || input.partialSigs!.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }
}
