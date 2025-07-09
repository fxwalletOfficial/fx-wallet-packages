import 'package:crypto_wallet_util/src/type/tx_data_type.dart';

/// [AlgoTxData] requires [transaction], [to_sign],
/// [to_sign] is the parameter to be signed.
class AlgoTxData extends TxData {
  String transaction;
  String to_sign;

  AlgoTxData({required this.transaction, required this.to_sign});

  factory AlgoTxData.fromJson(Map<String, dynamic> json) {
    return AlgoTxData(
      transaction: json['transaction'],
      to_sign: json['to_sign'],
    );
  }
  @override
  Map<String, dynamic> toBroadcast() {
    if (!isSigned) return {};
    return {
      'signature': signature,
      'transaction': transaction,
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'signature': signature,
      'transaction': transaction,
      'to_sign': to_sign
    };
  }
}
