import 'dart:typed_data';

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

    final r = txData.data.r!;
    final s = txData.data.s!;
    final v = txData.data.v!;

    // EIP-1559/EIP-7702 store the bare y-parity (0/1) in `v`; only legacy
    // uses the EIP-155 `recId + chainId*2 + 35` encoding. Feeding a typed
    // tx's `v` through the EIP-155 formula rejects every valid signature.
    final isTyped =
        txData.txType == EthTxType.eip1559 || txData.txType == EthTxType.eip7702;

    if (!EcdaSignature.isValidEthSignature(r, s, v,
        chainId: txData.network.chainId, vIsBareRecoveryId: isTyped)) {
      return false;
    }

    final recoveryId = isTyped
        ? v
        : EcdaSignature.calculateEthSigRecovery(v, chainId: txData.network.chainId);

    final recoveredXY =
        EcdaSignature.recoverPublicKey(r, s, recoveryId, txData.getMessageToSign());
    if (recoveredXY == null) return false;

    final recoveredAddress =
        getKeccakDigest(recoveredXY).sublist(12).toHex().toLowerCase();
    final walletAddress = wallet.publicKeyToAddress(wallet.publicKey).toLowerCase();
    // A ETH address may (or may not) carry a leading "0x" depending on the
    // caller; compare only the hex digits.
    return strip0xHex(recoveredAddress) == strip0xHex(walletAddress);
  }
}
