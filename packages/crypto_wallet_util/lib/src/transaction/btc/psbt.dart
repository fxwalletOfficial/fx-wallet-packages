import 'package:crypto_wallet_util/src/config/config.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/psbt.dart';
import 'package:crypto_wallet_util/src/type/wallet_type.dart';
import 'package:crypto_wallet_util/utils.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/address.dart';

import '../../forked_lib/bitcoin_flutter/bitcoin_flutter.dart' as bitcoin;
import 'package:crypto_wallet_util/src/forked_lib/psbt/utils/address_type.dart'
    as address_type;

class PSBTSigner {
  String psbtSignature;
  BtcTransferInfo tx;

  PSBTSigner(this.psbtSignature, this.tx);

  WalletSetting get chainConf => getChainConfig(tx.chain).mainnet;

  static String serializeTxToPsbtData(BtcTransferInfo tx) {
    return PSBT.fromTransferPsbt(tx).serialize();
  }

  sign() {
    String signature = '';
    PSBT psbtData = PSBT.parse(psbtSignature);
    if (tx.txType == BtcTxType.TAPROOT) {
      final btcTx = bitcoin.Transaction();
      btcTx.setVersion(tx.origin.version);
      btcTx.setLocktime(tx.origin.locktime);
      final inputs = tx.origin.inputs;
      final outputs = tx.origin.outputs;

      List signatures = [];
      signatures =
          psbtData.inputs.map((e) => e.taprootKeySpendSignature).toList();

      for (int i = 0; i < inputs.length; i++) {
        final prevoutHash = dynamicToUint8List(inputs[i].prevout.hash)
            .reversed
            .toList()
            .toUint8List();

        final value =
            NumberUtil.numberPowToInt(value: inputs[i].coin.value, pow: 8);
        final script = Address.addressToOutputScript(
            inputs[i].coin.address, chainConf.networkType);
        btcTx.addInput(prevoutHash, inputs[i].prevout.index,
            value: value, prevoutScript: script);
      }

      for (var i = 0; i < outputs.length; i++) {
        final item = outputs[i];
        final address = item.address;
        final amount = NumberUtil.numberPowToInt(value: item.amount, pow: 8);
        final outputScript =
            Address.addressToOutputScript(address, chainConf.networkType);
        btcTx.addOutput(outputScript, amount);
      }

      for (var i = 0; i < inputs.length; i++) {
        btcTx.signSchnorrHd(vin: i, sig: fromHex(signatures[i] as String));
      }

      signature = btcTx.toHex();
    } else {
      signature = psbtData
          .getSignedTransaction(address_type.BtcAddressType.p2pkh)
          .serialize();
    }

    return signature;
  }
}
