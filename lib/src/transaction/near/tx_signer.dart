import 'package:crypto_wallet_util/src/transaction/near/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';

/// Require [NearTxData] and wallet. 
class NearTxSigner extends TxSigner {
  @override
  final NearTxData txData;
  NearTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  NearTxData sign() {
    txData.signature = wallet.sign(txData.hash);
    txData.isSigned = true;
    return txData;
  }

  @override
  bool verify() {
    if (!txData.isSigned) return false;
    return wallet.verify(txData.signature, txData.hash);
  }
}
