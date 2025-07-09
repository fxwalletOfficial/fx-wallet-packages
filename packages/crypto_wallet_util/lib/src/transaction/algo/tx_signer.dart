import 'package:crypto_wallet_util/src/transaction/algo/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';

/// Require [AlgoTxData] and wallet. 
class AlgoTxSigner extends TxSigner {
  @override
  final AlgoTxData txData;
  AlgoTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  AlgoTxData sign() {
    txData.signature = wallet.sign(txData.to_sign);
    txData.isSigned = true;
    return txData;
  }

  @override
  bool verify() {
    if (!txData.isSigned) return false;
    return wallet.verify(txData.signature, txData.to_sign);
  }
}
