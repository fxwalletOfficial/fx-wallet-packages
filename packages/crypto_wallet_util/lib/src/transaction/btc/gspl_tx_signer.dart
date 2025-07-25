import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/utils/script.dart' show compile;
import 'package:crypto_wallet_util/src/type/tx_signer_type.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/src/transaction/btc/gspl_tx_data.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart' as btc;
import 'package:crypto_wallet_util/src/wallets/doge.dart';
import 'package:crypto_wallet_util/src/wallets/ltc.dart';
import 'package:crypto_wallet_util/src/wallets/bch.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

class GsplTxSigner extends TxSigner {
  @override
  final GsplTxData txData;

  late final btc.NetworkType networkType;

  bool get isDoge => wallet is DogeCoin;

  bool get isLtc => wallet is LtcCoin;

  bool get isBch => wallet is BchCoin;

  GsplTxSigner(WalletType wallet, this.txData) : super(wallet: wallet) {
    // 校验识别币种及参数
    final isDoge = wallet is DogeCoin;
    final isLtc = wallet is LtcCoin;
    final isBch = wallet is BchCoin;
    if (!isDoge && !isLtc && !isBch) {
      throw Exception('GSPL signer only support DOGE/LTC/BCH');
    }
    if (isDoge) {
      networkType = wallet.setting.networkType!;
    } else if (isLtc) {
      networkType = wallet.setting.networkType!;
    } else if (isBch) {
      networkType = wallet.setting.networkType!;
    } else {
      throw Exception('Unsupported wallet type for GSPL signing');
    }
  }

  @override
  GsplTxData sign() {
    // 反序列化识别交易信息，获取交易信息可读结构
    final transaction = btc.Transaction.fromHex(txData.hex);
    final inputAddress = wallet.publicKeyToAddress(wallet.publicKey);
    final paymentAddress = txData.toJson()['paymentAddress'];
    if (paymentAddress == null) {
      throw Exception('No valid output address found in transaction outputs');
    }

    // 遍历输入，使用wallet.sign对sigHash签名
    final List<GsplItem> signedInputs = [];
    for (int i = 0; i < txData.inputs.length; i++) {
      final input = txData.inputs[i];
      if (input.path == null) {
        throw Exception('Input path cannot be null');
      }
      int hashType = input.signHashType ?? btc.SIGHASH_ALL;
      if (isBch) {
        hashType |= btc.SIGHASH_BITCOINCASHBIP143;
      }
      if (input.amount == null) {
        throw Exception('Input amount required for sigHash');
      }

      final prevOutScript = btc.Address.addressToOutputScript(inputAddress, networkType)!;
      final value = input.amount!;

      // 根据钱包类型和配置选择正确的签名哈希方法
      Uint8List sigHash;
      if (_shouldUseSegwitSignature()) {
        sigHash = transaction.hashForWitnessV0(i, prevOutScript, value, hashType);
      } else {
        sigHash = transaction.hashForSignature(i, prevOutScript, hashType);
      }

      String sigResult;
      final sigHashHex = dynamicToString(sigHash);
      if (isLtc && (wallet as LtcCoin).isTaproot) {
        sigResult = (wallet as LtcCoin).sign(sigHashHex);
      } else if (isDoge) {
        sigResult = (wallet as DogeCoin).sign(sigHashHex);
      } else if (isBch) {
        sigResult = (wallet as BchCoin).sign(sigHashHex);
      } else {
        sigResult = wallet.sign(sigHashHex);
      }

      final Uint8List signatureBytes = Uint8List.fromList(hexToBytes(sigResult));

      // 构造新 GsplItem 替换
      signedInputs.add(GsplItem(
        path: input.path,
        amount: input.amount,
        address: inputAddress,
        signHashType: input.signHashType,
        signature: signatureBytes,
      ));
    }
    final transactionSigned = btc.Transaction.fromHex(txData.hex);
    for (int i = 0; i < signedInputs.length; i++) {
      final sig = signedInputs[i].signature;
      if (sig == null) {
        throw Exception('Missing signature for input $i');
      }
      final pubkey = wallet.publicKey;
      final scriptSig = compile([sig, pubkey]);
      transactionSigned.ins[i].script = scriptSig;
    }
    final newHex = transactionSigned.toHex();
    final newTxData = GsplTxData(
      inputs: signedInputs,
      hex: newHex, // 组装后的可广播hex
      change: txData.change,
      dataType: txData.dataType,
    );
    newTxData.isSigned = true;
    newTxData.message = newHex;
    newTxData.signature = "";
    return newTxData;
  }

  /// 判断是否应该使用 SegWit 签名方法
  bool _shouldUseSegwitSignature() {
    // BCH 使用 BIP143 签名哈希方法
    if (isBch) {
      return true;  // ✅ BCH 应该使用 BIP143
    }

    // DOGE 不支持 SegWit，使用 Legacy 签名
    if (isDoge) {
      return false;
    }

    // LTC 的情况：Taproot 使用 BIP143，普通使用 Legacy
    if (isLtc) {
      return (wallet as LtcCoin).isTaproot;
    }

    return false;
  }
}
