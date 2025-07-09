import 'package:crypto_wallet_util/src/type/tx_data_type.dart';

/// [IcpTxData] requires [transaction], [to_sign],
/// [to_sign] is the parameter to be signed.
class IcpTxData extends TxData {
  String transaction;
  String to_sign;
  @override
  String signature = '';
  String rawPublicKey = '';

  IcpTxData({required this.transaction, required this.to_sign});

  factory IcpTxData.fromJson(Map<String, dynamic> json) {
    return IcpTxData(
      transaction: json['transaction'],
      to_sign: json['to_sign'],
    );
  }
  @override
  Map<String, dynamic> toBroadcast() {
    if (!isSigned) return {};
    return {
      'signature': signature,
      'rawPublicKey': rawPublicKey,
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
