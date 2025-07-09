import 'package:crypto_wallet_util/src/type/tx_data_type.dart';

import 'fil_lib.dart';

/// [FilTxData] requires [transaction], [to_sign],
/// [to_sign] is the parameter to be signed.
class FilTxData extends TxData {
  final FilTransaction transaction;
  final String to_sign;

  FilTxData({required this.transaction, required this.to_sign});

  factory FilTxData.fromJson(Map<String, dynamic> json) {
    return FilTxData(
      transaction: FilTransaction.fromJson(json['transaction']),
      to_sign: json['to_sign'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "transaction": transaction.toJson(),
      "to_sign": to_sign,
    };
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {
      "transaction": transaction.toJson(),
      "signature": signature,
    };
  }
}
