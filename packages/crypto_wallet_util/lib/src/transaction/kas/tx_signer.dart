import 'package:crypto_wallet_util/src/transaction/kas/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Require [KasTxData] and wallet. 
class KasTxSigner extends TxSigner {
  @override
  final KasTxData txData;

  KasTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  KasTxData sign() {
    for (int i = 0; i < txData.inputs.length; i++) {
      txData.messages.add(txData.inputs[i].signatureScript);
      final signautre = wallet.sign(txData.inputs[i].signatureScript);
      txData.inputs[i].signatureScript = addFixs(signautre);
    }
    txData.isSigned = true;
    return txData;
  }

  @override
  bool verify() {
    if (txData.isSigned) {
      final result = wallet.verify(
          deleteFixs(txData.inputs.first.signatureScript),
          txData.messages.first);
      return result;
    }
    return false;
  }

  String addFixs(String signature) {
    final prefix = [0x41];
    final suffix = [1];
    final processed = [...prefix, ...dynamicToUint8List(signature), ...suffix];
    return dynamicToString(processed);
  }

  String deleteFixs(String signature) {
    final processed = dynamicToUint8List(signature);
    return dynamicToString(processed.sublist(1, processed.length - 1));
  }
}
