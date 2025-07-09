import 'package:crypto_wallet_util/src/type/tx_data_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';

/// [wallet] contains the necessary tools for signing, such as private key, public key and signature scheme.
/// [txData] includes the fields required for sending transactions. After [sign], [txData] will includes serialized message and signature.
/// Then, broadcast [TxData.toBroadcast].
abstract class TxSigner {
  final WalletType wallet;
  TxData? txData;
  TxSigner({required this.wallet, this.txData});

  sign();
  bool verify() {
    if (txData!.isSigned) {
      final result = wallet.verify(txData!.signature, txData!.message);
      if (result) {
        // Reserve an interface to verify whether the broadcast transaction data is correct
        return checkTxData();
      }
    }
    return false;
  }

  bool safeVerify() {
    try {
      return verify();
    } catch (error) {
      return false;
    }
  }

  bool checkTxData() {
    return true;
  }
}
