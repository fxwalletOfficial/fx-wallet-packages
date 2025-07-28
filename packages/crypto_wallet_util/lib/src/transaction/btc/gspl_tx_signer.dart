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

  late final btc.NetworkType networkType;

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

  @override
  GsplTxData sign() {
    // Deserialize and identify transaction information, get readable transaction structure
    final transaction = btc.Transaction.fromHex(txData.hex);
    final inputAddress = wallet.publicKeyToAddress(wallet.publicKey);
    final paymentAddress = txData.toJson()['paymentAddress'];
    if (paymentAddress == null) {
      throw Exception('No valid output address found in transaction outputs');
    }

    // Iterate through inputs, use wallet.sign to sign sigHash
    final List<GsplItem> signedInputs = [];
    for (int i = 0; i < txData.inputs.length; i++) {
      final input = txData.inputs[i];
      if (input.path == null) {
        throw Exception('Input path cannot be null');
      }
      int hashType = input.signHashType ?? btc.SIGHASH_ALL;
      if (isBch) {
        hashType |= btc.SIGHASH_BITCOINCASHBIP143;
      }
      if (input.amount == null) {
        throw Exception('Input amount required for sigHash');
      }

      final prevOutScript = btc.Address.addressToOutputScript(inputAddress, networkType)!;
      final value = input.amount!;

      // Choose correct signature hash method based on wallet type and configuration
      Uint8List sigHash;
      if (_shouldUseSegwitSignature()) {
        sigHash = transaction.hashForWitnessV0(i, prevOutScript, value, hashType);
      } else {
        sigHash = transaction.hashForSignature(i, prevOutScript, hashType);
      }

      String sigResult;
      final sigHashHex = dynamicToString(sigHash);
      if (isLtc && (wallet as LtcCoin).isTaproot) {
        sigResult = (wallet as LtcCoin).sign(sigHashHex);
      } else if (isDoge) {
        sigResult = (wallet as DogeCoin).sign(sigHashHex);
      } else if (isBch) {
        sigResult = (wallet as BchCoin).sign(sigHashHex);
      } else {
        sigResult = wallet.sign(sigHashHex);
      }

      final Uint8List signatureBytes = Uint8List.fromList(hexToBytes(sigResult));

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
      final pubkey = wallet.publicKey;
      final scriptSig = compile([sig, pubkey]);
      transactionSigned.ins[i].script = scriptSig;
    }
    final newHex = transactionSigned.toHex();
    
    txData.hex = newHex;
    txData.inputs = signedInputs;
    txData.isSigned = true;
    txData.message = newHex;
    txData.signature = "";

    return txData;
  }

  /// Determine whether to use SegWit signature method
  bool _shouldUseSegwitSignature() {
    // BCH uses BIP143 signature hash method
    if (isBch) {
      return true;  // ✅ BCH should use BIP143
    }

    // DOGE doesn't support SegWit, use Legacy signature
    if (isDoge) {
      return false;
    }

    // LTC case: Taproot uses BIP143, regular uses Legacy
    if (isLtc) {
      return (wallet as LtcCoin).isTaproot;
    }

    return false;
  }

  @override
  bool verify() {
    final inputs = txData.inputs;
    for (var i = 0; i < inputs.length; i++) {
      final input = inputs[i];
      final signature = input.signature;
      if (signature == null) {
        return false;
      }
    }
    return txData.isSigned;
  }
}
