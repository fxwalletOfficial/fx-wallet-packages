import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/transaction/xrp/tx_data.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

import 'package:crypto_wallet_util/src/forked_lib/xrpl_dart/xrpl_dart.dart';

/// Require [XrpTxData] and wallet.
class XrpTxSigner extends TxSigner {
  @override
  final XrpTxData txData;
  XrpTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  sign() {
    txData.signingPubKey = dynamicToString(wallet.publicKey);
    final tx = buildTransaction(txData);
    txData.message = tx.toBlob();
    txData.signature = wallet.sign(txData.message);
    tx.txnSignature = txData.signature;
    txData.signedBlob = tx.toBlob(forSigning: false);
    txData.isSigned = true;
    txData.txHash = tx.getHash();
    return txData;
  }

  XRPTransaction buildTransaction(XrpTxData txData) {
    return XRPTransaction.fromXrpl(txData.toJson());
  }
}
