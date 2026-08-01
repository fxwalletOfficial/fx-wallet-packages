import 'dart:typed_data';

import 'package:crypto_wallet_util/src/transaction/btc/psbt_tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/utils.dart';

class _Prevout {
  final String scriptHex;
  final String fullOutputHex;
  final int value;
  final Uint8List? taprootOutputKey;
  final Uint8List? p2pkhPublicKeyHash;
  _Prevout(
    this.scriptHex,
    this.fullOutputHex,
    this.value,
    this.taprootOutputKey,
    this.p2pkhPublicKeyHash,
  );
}

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

  /// Gather every input's prevout scriptPubKey/amount (and, for Taproot,
  /// the tweaked x-only output key straight out of the P2TR scriptPubKey).
  /// BIP341 key-path sighash commits to every spent output, not just the
  /// one being signed, so this must cover *all* inputs regardless of which
  /// one is being signed or verified.
  List<_Prevout> _gatherPrevouts() {
    final psbtInputs = txData.psbt.inputs;
    final unsignedInputs = txData.psbt.unsignedTransaction!.inputs;
    final prevouts = <_Prevout>[];

    for (int i = 0; i < psbtInputs.length; i++) {
      final input = psbtInputs[i];
      if (input.witnessUtxo != null) {
        final scriptPubKey = input.witnessUtxo!.scriptPubKey;
        prevouts.add(_Prevout(
          scriptPubKey.serialize(),
          input.witnessUtxo!.serialize(),
          input.witnessUtxo!.amount,
          scriptPubKey.isP2TR()
              ? Uint8List.fromList(scriptPubKey.commands[1])
              : null,
          scriptPubKey.isP2PKH()
              ? Uint8List.fromList(scriptPubKey.commands[2])
              : null,
        ));
      } else if (input.previousTransaction != null) {
        final prevTx = input.previousTransaction!;
        final outputIndex = unsignedInputs[i].index;
        final prevOutput = prevTx.outputs[outputIndex];
        final scriptPubKey = prevOutput.scriptPubKey;
        prevouts.add(_Prevout(
          scriptPubKey.serialize(),
          prevOutput.serialize(),
          prevOutput.amount,
          scriptPubKey.isP2TR()
              ? Uint8List.fromList(scriptPubKey.commands[1])
              : null,
          scriptPubKey.isP2PKH()
              ? Uint8List.fromList(scriptPubKey.commands[2])
              : null,
        ));
      } else {
        throw Exception('No UTXO information found for input $i');
      }
    }
    return prevouts;
  }

  /// Sign Taproot P2TR transaction inputs
  void _signTaprootInputs() {
    final psbtInputs = txData.psbt.inputs;
    final prevouts = _gatherPrevouts();
    final prevOutScripts = prevouts.map((p) => p.scriptHex).toList();
    final prevOutValues = prevouts.map((p) => p.value).toList();

    for (int i = 0; i < psbtInputs.length; i++) {
      // BIP341 TapSighash (SIGHASH_DEFAULT key-path spend).
      final sigHashHex = txData.psbt.unsignedTransaction!.getTaprootSigHash(
        i,
        prevOutScripts,
        prevOutValues,
      );

      // Generate Schnorr signature for Taproot
      final signature = wallet.sign(sigHashHex);

      // Set taproot key spend signature
      txData.psbt.inputs[i].setTaprootKeySpendSignature(signature);
    }
  }

  @override
  bool verify() {
    final psbtInputs = txData.psbt.inputs;
    if (psbtInputs.isEmpty) return false;

    final List<_Prevout> prevouts;
    try {
      prevouts = _gatherPrevouts();
    } catch (_) {
      return false;
    }
    final prevOutScripts = prevouts.map((p) => p.scriptHex).toList();
    final prevOutValues = prevouts.map((p) => p.value).toList();

    for (int i = 0; i < psbtInputs.length; i++) {
      final input = psbtInputs[i];

      if (txData.isTaproot) {
        final sig = input.taprootKeySpendSignature;
        final outputKey = prevouts[i].taprootOutputKey;
        if (sig == null || outputKey == null) return false;

        final sigHashHex =
            txData.psbt.unsignedTransaction!.getTaprootSigHash(
          i,
          prevOutScripts,
          prevOutValues,
        );
        if (!Schnorr.verify(outputKey, sig, sigHashHex)) return false;
      } else {
        final partialSigs = input.partialSigs;
        if (partialSigs == null || partialSigs.length != 2) return false;
        final signature = partialSigs[0];
        final publicKey = fromHex(partialSigs[1]);
        final expectedPublicKeyHash = prevouts[i].p2pkhPublicKeyHash;
        if (expectedPublicKeyHash == null ||
            dynamicToString(sha160fromByte(publicKey)) !=
                dynamicToString(expectedPublicKeyHash)) {
          return false;
        }

        final sigHashHex = txData.psbt.unsignedTransaction!.getSigHash(
          i,
          prevouts[i].fullOutputHex,
          false,
        );
        if (!EcdaSignature.verifyDerWithHashType(
            sigHashHex, publicKey, signature)) {
          return false;
        }
      }
    }
    return true;
  }
}
