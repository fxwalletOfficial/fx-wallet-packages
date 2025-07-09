import 'package:crypto_wallet_util/src/transaction/sol/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';

/// Require [SolTxData] and wallet. 
class SolTxSigner extends TxSigner {
  @override
  final SolTxData txData;
  SolTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  SolTxData sign() {
    txData.signature = wallet.sign(txData.transaction);
    if (txData.initTokenAddress != null) {
      txData.initTokenAddressSignature = wallet.sign(txData.initTokenAddress!);
    }
    txData.isSigned = true;
    return txData;
  }

  @override
  bool verify() {
    if (!txData.isSigned) return false;
    if (!wallet.verify(txData.signature, txData.transaction)) return false;
    if (txData.initTokenAddress != null) {
      if (!wallet.verify(
          txData.initTokenAddressSignature!, txData.initTokenAddress!))
        return false;
    }
    return true;
  }
}
