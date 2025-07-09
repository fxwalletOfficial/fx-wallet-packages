import 'package:crypto_wallet_util/src/type/tx_data_type.dart';
import 'near_lib.dart';

/// [NearTxData] requires [transaction], [hash],
/// [hash] is the parameter to be signed.
class NearTxData extends TxData {
  Transaction transaction;
  String hash;

  NearTxData({required this.transaction, required this.hash});

  factory NearTxData.fromJson(Map<String, dynamic> json) {
    return NearTxData(
      transaction: Transaction.fromJson(json['transaction']),
      hash: json['hash'],
    );
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {'signature': signature, 'transaction': transaction.toJson()};
  }

  @override
  Map<String, dynamic> toJson() {
    return {'transaction': transaction.toJson(), 'hash': hash};
  }
}
