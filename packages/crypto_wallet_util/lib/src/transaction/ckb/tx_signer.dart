import 'package:crypto_wallet_util/src/transaction/ckb/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';

/// Require [CkbTxData] and wallet.
class CkbTxSigner extends TxSigner {
  @override
  final CkbTxData txData;
  CkbTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  CkbTxData sign() {
    txData.message = txData.getMessage();
    txData.signature = wallet.sign(txData.message);
    txData.setWitnesses();
    txData.isSigned = true;
    return txData;
  }
}
