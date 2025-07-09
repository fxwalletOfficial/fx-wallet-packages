import 'package:crypto_wallet_util/src/type/tx_data_type.dart';

/// [AlphTxData] requires [unsignedTx], [txId],
/// [txId] is the parameter to be signed.
class AlphTxData extends TxData {
  String unsignedTx;
  String txId;
  @override
  String signature = '';

  AlphTxData({required this.unsignedTx, required this.txId});

  factory AlphTxData.fromJson(Map<String, dynamic> json) {
    return AlphTxData(
      unsignedTx: json['rawTransaction'],
      txId: json['txId'],
    );
  }
  @override
  Map<String, dynamic> toBroadcast() {
    if (!isSigned) return {};
    return {
      'signature': signature,
      'unsignedTx': unsignedTx,
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {'signature': signature, 'unsignedTx': unsignedTx, 'txId': txId};
  }
}
