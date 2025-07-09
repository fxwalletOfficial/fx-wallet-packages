import 'package:crypto_wallet_util/src/transaction/alph/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';

/// Require [AlphTxData] and wallet. 
class AlphTxSigner extends TxSigner {
  @override
  final AlphTxData txData;
  AlphTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  AlphTxData sign() {
    txData.signature = wallet.sign(txData.txId);
    txData.isSigned = true;
    return txData;
  }

  @override
  bool verify() {
    if (!txData.isSigned) return false;
    return wallet.verify(txData.signature, txData.txId);
  }
}
