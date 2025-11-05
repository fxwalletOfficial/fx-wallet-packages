import 'package:crypto_wallet_util/src/transaction/aptos/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Require [AptosTxData] and wallet.
class AptosTxSigner extends TxSigner {
  @override
  final AptosTxData txData;
  AptosTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  AptosTxData sign() {
    txData.signature = wallet.sign(txData.to_sign_message);
    txData.rawPublicKey = wallet.publicKey.toStr();
    txData.isSigned = true;
    return txData;
  }

  @override
  bool verify() {
    if (!txData.isSigned) return false;
    return wallet.verify(txData.signature, txData.to_sign_message);
  }
}
