import 'package:crypto_wallet_util/src/transaction/sui/tx_data.dart';
import 'package:crypto_wallet_util/src/type/type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Require [SuiTxData] and wallet. 
class SuiTxSigner extends TxSigner {
  @override
  final SuiTxData txData;
  SuiTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  sign() {
    txData.publickey = dynamicToString(wallet.publicKey);
    txData.message = txData.messageToSign.transaction;
    txData.signature = wallet.sign(txData.messageToSign.transaction);
    txData.isSigned = true;
    return txData;
  }
}
