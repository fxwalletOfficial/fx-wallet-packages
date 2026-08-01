import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/bip32/bip32.dart' show NetworkType;
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/utils/script.dart' show compile;
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/transaction/btc/gspl_tx_data.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart' as btc;
import 'package:crypto_wallet_util/src/wallets/doge.dart';
import 'package:crypto_wallet_util/src/wallets/ltc.dart';
import 'package:crypto_wallet_util/src/wallets/bch.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

class GsplTxSigner extends TxSigner {
  @override
  final GsplTxData txData;

  late final NetworkType networkType;

  bool get isDoge => wallet is DogeCoin;

  bool get isLtc => wallet is LtcCoin;

  bool get isBch => wallet is BchCoin;

  GsplTxSigner(WalletType wallet, this.txData) : super(wallet: wallet) {
    // Validate and identify coin type and parameters
    final isDoge = wallet is DogeCoin;
    final isLtc = wallet is LtcCoin;
    final isBch = wallet is BchCoin;
    if (!isDoge && !isLtc && !isBch) {
      throw Exception('GSPL signer only support DOGE/LTC/BCH');
    }
    if (isDoge) {
      networkType = wallet.setting.networkType!;
    } else if (isLtc) {
      networkType = wallet.setting.networkType!;
    } else if (isBch) {
      networkType = wallet.setting.networkType!;
    } else {
      throw Exception('Unsupported wallet type for GSPL signing');
    }
  }

  bool get isTaprootInput => isLtc && (wallet as LtcCoin).isTaproot;

  /// hashType for input [i], applying the same per-coin default `sign()`
  /// uses — Taproot key-path spends default to SIGHASH_DEFAULT (not ALL),
  /// and BCH always carries the BIP143 fork bit.
  int _hashTypeFor(GsplItem input) {
    if (isTaprootInput) {
      return input.signHashType ?? btc.SIGHASH_DEFAULT;
    }
    int hashType = input.signHashType ?? btc.SIGHASH_ALL;
    if (isBch) hashType |= btc.SIGHASH_BITCOINCASHBIP143;
    return hashType;
  }

  /// The sighash for input [i] of [tx], using the same prevout script (this
  /// wallet's own address, shared across every GSPL input) and BIP341
  /// all-inputs amounts/scripts that `sign()` uses.
  Uint8List _sigHashFor(btc.Transaction tx, int i, Uint8List prevOutScript,
      List<Uint8List> allPrevScripts, List<int> allValues, int hashType) {
    if (isTaprootInput) {
      return tx.hashForWitnessV1(i, allPrevScripts, allValues, hashType, null, null);
    } else if (_shouldUseSegwitSignature()) {
      return tx.hashForWitnessV0(i, prevOutScript, allValues[i], hashType);
    } else {
      return tx.hashForSignature(i, prevOutScript, hashType);
    }
  }

  @override
  GsplTxData sign() {
    // Deserialize and identify transaction information, get readable transaction structure
    final tx = btc.Transaction.fromHex(txData.hex);
    final inputAddress = wallet.publicKeyToAddress(wallet.publicKey);
    final payments = txData.toJson()['payments'];
    if (payments == null || payments.isEmpty) {
      throw Exception('No valid output found in transaction outputs');
    }

    final prevOutScript = btc.Address.addressToOutputScript(inputAddress, networkType)!;

    // BIP341 sighash commits to every spent output's scriptPubKey and
    // amount, so gather them for all inputs up front (GSPL inputs all
    // belong to the same wallet address, so the script is shared).
    final allPrevScripts = <Uint8List>[];
    final allValues = <int>[];
    for (final input in txData.inputs) {
      if (input.amount == null) throw Exception('Input amount required for sigHash');
      allPrevScripts.add(prevOutScript);
      allValues.add(input.amount!);
    }

    // Iterate through inputs, use wallet.sign to sign sigHash
    final List<GsplItem> signedInputs = [];
    for (int i = 0; i < txData.inputs.length; i++) {
      final input = txData.inputs[i];
      if (input.path == null) throw Exception('Input path cannot be null');
      if (input.amount == null) throw Exception('Input amount required for sigHash');

      final hashType = _hashTypeFor(input);
      final sigHash =
          _sigHashFor(tx, i, prevOutScript, allPrevScripts, allValues, hashType);

      String sigResult;
      final sigHashHex = dynamicToString(sigHash);
      if (isTaprootInput) {
        sigResult = (wallet as LtcCoin).signWithHashType(sigHashHex, hashType);
      } else if (isLtc) {
        sigResult = (wallet as LtcCoin).signWithHashType(sigHashHex, hashType);
      } else if (isDoge) {
        sigResult = (wallet as DogeCoin).signWithHashType(sigHashHex, hashType);
      } else if (isBch) {
        sigResult = (wallet as BchCoin).signWithHashType(sigHashHex, hashType);
      } else {
        sigResult = wallet.sign(sigHashHex);
      }

      final signatureBytes = dynamicToUint8List(sigResult);

      // Construct new GsplItem to replace
      signedInputs.add(GsplItem(
        path: input.path,
        amount: input.amount,
        address: inputAddress,
        signHashType: input.signHashType,
        signature: signatureBytes,
      ));
    }

    final transactionSigned = btc.Transaction.fromHex(txData.hex);
    for (int i = 0; i < signedInputs.length; i++) {
      final sig = signedInputs[i].signature;
      if (sig == null) {
        throw Exception('Missing signature for input $i');
      }
      if (isTaprootInput) {
        // P2TR key-path spend: the Schnorr signature goes in the witness
        // stack, and scriptSig stays empty.
        final hashType = signedInputs[i].signHashType ?? btc.SIGHASH_DEFAULT;
        final witnessSig = hashType == btc.SIGHASH_DEFAULT
            ? sig
            : Uint8List.fromList([...sig, hashType]);
        transactionSigned.ins[i].witness = [witnessSig];
        transactionSigned.ins[i].script = btc.EMPTY_SCRIPT;
      } else {
        final pubkey = wallet.publicKey;
        final scriptSig = compile([sig, pubkey]);
        transactionSigned.ins[i].script = scriptSig;
      }
    }
    final signedHex = transactionSigned.toHex();
    txData.hex = signedHex;
    txData.inputs = signedInputs;
    txData.isSigned = true;
    txData.message = signedHex;
    txData.signature = '';

    return txData;
  }

  /// Determine whether to use SegWit signature method
  bool _shouldUseSegwitSignature() {
    // BCH uses BIP143 signature hash method
    if (isBch) return true;  // ✅ BCH should use BIP143

    // DOGE doesn't support SegWit, use Legacy signature
    if (isDoge) return false;

    return false;
  }

  @override
  bool verify() {
    final inputs = txData.inputs;
    if (inputs.isEmpty || !txData.isSigned) return false;

    final btc.Transaction tx;
    try {
      tx = btc.Transaction.fromHex(txData.hex);
    } catch (_) {
      return false;
    }

    final inputAddress = wallet.publicKeyToAddress(wallet.publicKey);
    final prevOutScript = btc.Address.addressToOutputScript(inputAddress, networkType);
    if (prevOutScript == null) return false;

    final allPrevScripts = <Uint8List>[];
    final allValues = <int>[];
    for (final input in inputs) {
      if (input.amount == null) return false;
      allPrevScripts.add(prevOutScript);
      allValues.add(input.amount!);
    }

    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      final signature = input.signature;
      if (signature == null) return false;

      final hashType = _hashTypeFor(input);
      final sigHash =
          _sigHashFor(tx, i, prevOutScript, allPrevScripts, allValues, hashType);

      if (!wallet.verify(dynamicToString(signature), dynamicToString(sigHash))) {
        return false;
      }
    }
    return true;
  }
}
