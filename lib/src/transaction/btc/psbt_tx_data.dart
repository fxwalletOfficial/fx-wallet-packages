import 'package:crypto_wallet_util/src/type/type.dart';
import 'package:crypto_wallet_util/src/config/config.dart';
import 'package:crypto_wallet_util/src/utils/utils.dart';

import 'package:crypto_wallet_util/src/forked_lib/psbt/psbt.dart';
import 'package:crypto_wallet_util/src/forked_lib/psbt/utils/address_type.dart'
    as address_type;
import 'package:crypto_wallet_util/src/forked_lib/psbt/utils/converter.dart';
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/bitcoin_flutter.dart'
    as bitcoin;

class PsbtTxData extends TxData {
  final PSBT psbt;
  final bool isTaproot;
  String unsignedPsbt = '';

  PsbtTxData(this.psbt, this.unsignedPsbt, this.isTaproot);

  /// gas fee
  int get fee => psbt.fee;

  /// get transfer amount (all outputs, not excluding change)
  int get transferAmount => psbt.transferAmount;

  /// get receive address (first non-change output)
  String get transferAddress {
    return psbt.unsignedTransaction!.outputs[0].getAddress();
  }

  Origin get origin => getOrigin(unsignedPsbt);

  static PsbtTxData fromHash(String hash, {bool isTaproot = false}) {
    return PsbtTxData(PSBT.parse(hash), hash, isTaproot);
  }

  static Origin getOrigin(String psbtHex) {
    final psbt = PSBT.parse(psbtHex);
    final unsignedTx = psbt.unsignedTransaction!;

    // Extract inputs from PSBT
    final inputs = <OriginInput>[];
    for (int i = 0; i < psbt.inputs.length; i++) {
      final psbtInput = psbt.inputs[i];
      final txInput = unsignedTx.inputs[i];
      final amount = psbtInput.witnessUtxo!.amount;
      final value = amount / 100000000;
      final address = psbtInput.witnessUtxo!.scriptPubKey.getAddress();

      inputs.add(OriginInput(
        prevout: Prevout(
          hash: txInput.transactionHash,
          index: txInput.index,
        ),
        sequence: txInput.sequence,
        // Default coin info - would need external data source for accurate info
        coin: Coin(
          version: 2,
          height: 0, // Unknown from PSBT
          value: value, // May not be available
          address: address, // May not be available
          coinbase: false, // Unknown from PSBT
        ),
        path: Path(
          account: null, // May be available in derivation path
          change: false, // Unknown from PSBT
        ),
      ));
    }

    // Extract outputs from PSBT
    final outputs = <OriginOutput>[];
    for (final output in unsignedTx.outputs) {
      outputs.add(OriginOutput(
        address: output.scriptPubKey.getAddress(),
        amount: (output.amount / 100000000), // Convert satoshis to BTC
        path: null, // May be available in PSBT output data
        value: output.amount.toString(),
      ));
    }

    return Origin(
      status: 'success',
      code: 20000,
      fee: 0.0,
      rate: 0,
      mtime: DateTime.now().millisecondsSinceEpoch ~/ 1000, // useless data
      version: Converter.littleEndianToInt(Converter.hexToBytes(unsignedTx.version)),
      inputs: inputs,
      outputs: outputs,
      locktime: Converter.littleEndianToInt(Converter.hexToBytes(unsignedTx.lockTime)),
      hex: psbtHex,
    );
  }

  String getSignedTxHex() {
    if (!isSigned) {
      throw Exception('Transaction is not signed');
    }
    final chainConf = getChainConfig('btc').mainnet;
    if (isTaproot) {
      final btcTx = bitcoin.Transaction();
      final originTx = getOrigin(unsignedPsbt);

      btcTx.setVersion(originTx.version);
      btcTx.setLocktime(originTx.locktime);

      final inputs = originTx.inputs;
      final outputs = originTx.outputs;

      List signatures = [];
      signatures = psbt.inputs.map((e) => e.taprootKeySpendSignature).toList();

      for (int i = 0; i < inputs.length; i++) {
        final prevoutHash = dynamicToUint8List(inputs[i].prevout.hash)
            .reversed
            .toList()
            .toUint8List();

        final value =
            NumberUtil.numberPowToInt(value: inputs[i].coin.value, pow: 8);
        final script = bitcoin.Address.addressToOutputScript(
            inputs[i].coin.address, chainConf.networkType);

        btcTx.addInput(prevoutHash, inputs[i].prevout.index,
            value: value, prevoutScript: script);
      }

      for (var i = 0; i < outputs.length; i++) {
        final item = outputs[i];
        final address = item.address;
        final amount = NumberUtil.numberPowToInt(value: item.amount, pow: 8);
        final outputScript = bitcoin.Address.addressToOutputScript(
            address, chainConf.networkType);
        btcTx.addOutput(outputScript, amount);
      }

      for (var i = 0; i < inputs.length; i++) {
        btcTx.signSchnorrHd(vin: i, sig: fromHex(signatures[i] as String));
      }

      return btcTx.toHex();
    } else {
      return psbt
          .getSignedTransaction(address_type.BtcAddressType.p2pkh)
          .serialize();
    }
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {
      'psbt': getSignedTxHex(),
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'fee': fee,
      'transferAmount': transferAmount,
      'transferAddress': transferAddress
    };
  }
}
