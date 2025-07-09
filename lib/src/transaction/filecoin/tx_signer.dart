import 'package:crypto_wallet_util/src/transaction/filecoin/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';

/// Require [FilTxData] and wallet. 
class FilTxSigner extends TxSigner {
  @override
  final FilTxData txData;
  FilTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  FilTxData sign() {
    txData.message = txData.to_sign;
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
