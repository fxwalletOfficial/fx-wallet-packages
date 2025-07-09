import 'package:crypto_wallet_util/src/transaction/icp/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/wallets/icp.dart';

/// Require [IcpTxData] and wallet. 
class IcpTxSigner extends TxSigner {
  @override
  final IcpTxData txData;
  IcpTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  IcpTxData sign() {
    txData.signature = wallet.sign(txData.to_sign);
    txData.rawPublicKey = Principal.getRawPublicKey(wallet.publicKey);
    txData.isSigned = true;
    return txData;
  }

  @override
  bool verify() {
    if (!txData.isSigned) return false;
    return wallet.verify(txData.signature, txData.to_sign);
  }
}
