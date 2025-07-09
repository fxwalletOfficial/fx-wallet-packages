import 'package:crypto_wallet_util/src/type/tx_data_type.dart';

/// [AptosTxData] requires [to_sign_message], [transaction],
/// [to_sign_message] is the parameter to be signed.
class AptosTxData extends TxData {
  final String to_sign_message;
  final String transaction;
  String? rawPublicKey;

  AptosTxData({
    required this.to_sign_message,
    required this.transaction,
  });

  factory AptosTxData.fromJson(Map<String, dynamic> json) {
    return AptosTxData(
      to_sign_message: json['to_sign_message'],
      transaction: json['transaction'],
    );
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {
      'rawPublicKey': rawPublicKey,
      'signature': signature,
      'transaction': transaction
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'to_sign_message': to_sign_message,
      'rawPublicKey': rawPublicKey,
      'transaction': transaction
    };
  }
}
