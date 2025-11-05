import 'dart:typed_data';

import 'package:crypto_wallet_util/src/transaction/sol/v2/tx_data.dart';
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Provide another way to sign sol message.
class SolTxSignerV2 extends TxSigner {
  @override
  final SolTxDataV2 txData;
  SolTxSignerV2(WalletType wallet, this.txData) : super(wallet: wallet);

  @override
  void sign() {
    final message = txData.solanaTransaction.message;
    final Uint8List serializedMessage = message.serialize().asUint8List();
    txData.message = dynamicToString(serializedMessage);
    txData.signature = wallet.sign(txData.message);
    txData.isSigned = true;
    txData.solanaTransaction.signatures[0] = txData.signature.toUint8List();
  }

  @override
  bool verify() {
    if (!txData.isSigned) return false;
    if (!wallet.verify(txData.signature, txData.message)) return false;
    return true;
  }
}
