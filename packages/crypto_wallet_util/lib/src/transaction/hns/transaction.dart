import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'data_type.dart';

/// Hns hash type.
class HnsHashType {
  static const int ALL = 1;
  static const int NONE = 2;
  static const int SINGLE = 3;
  static const int SINGLE_REVERSE = 4;
  static const int NO_INPUT = 0x40;
  static const int ANYONE_CAN_PAY = 0x80;
}

/// Provide hns tx data.
class MTX {
  final String hash;
  final String witnessHash;
  final double fee;
  final int rate;
  final int mtime;
  final int version;
  final List<UTXO> inputs;
  final List<Vout> outputs;
  final int locktime;
  final String hex;
  final Map<dynamic, dynamic> raw;

  /// TRX
  final TrxMessageToSign messageToSign;

  MTX.fromJson(Map<dynamic, dynamic> json)
      : raw = json,
        hash = json['hash'] ?? '',
        witnessHash = json['witnessHash'] ?? '',
        fee = NumberUtil.toDouble(json['fee']),
        rate = NumberUtil.toInt(json['rate']),
        mtime = NumberUtil.toInt(json['mtime']),
        version = NumberUtil.toInt(json['version']),
        inputs = ((json['inputs'] ?? []) as List)
            .map((e) => UTXO.fromJson(e))
            .toList(),
        outputs = ((json['outputs'] ?? []) as List)
            .map((e) => Vout.fromJson(e))
            .toList(),
        locktime = NumberUtil.toInt(json['locktime']),
        hex = json['hex'] ?? '',

        /// TRX
        messageToSign = TrxMessageToSign.fromJson(json['messageToSign'] ?? {});
}
