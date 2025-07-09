import 'package:crypto_wallet_util/src/transaction/eth/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Require [EthTxData] and wallet.
class EthTxSigner extends TxSigner {
  @override
  final EthTxData txData;
  EthTxSigner(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  EthTxData sign() {
    Uint8List msg = txData.getMessageToSign();
    txData.message = msg.toStr();
    EcdaSignature result =
        EcdaSignature.signForEth(dynamicToUint8List(msg), wallet.privateKey);
    txData.data.r = hexToBigInt(dynamicToHex(result.r));
    txData.data.s = hexToBigInt(dynamicToHex(result.s));
    txData.isSigned = true;

    /// Set v value
    switch (txData.txType) {
      case EthTxType.eip1559:
      case EthTxType.eip7702:
        txData.data.v = result.v - 27;
        break;
      case EthTxType.legacy:
        txData.data.v = result.v + txData.network.chainId * 2 + 8;
        break;
    }

    txData.signature = txData.serialize().toStr();
    return txData;
  }

  @override
  bool verify() {
    if (!txData.isSigned) return false;

    return EcdaSignature.isValidEthSignature(
        txData.data.r!, txData.data.s!, txData.data.v!,
        chainId: txData.network.chainId);
  }
}
