import 'package:crypto_wallet_util/src/type/tx_data_type.dart';

/// [SolTxData] requires [initTokenAddress], [transaction], [blockhash], [lastValidBlockHeight], [fee]
/// [transaction] is the parameter to be signed.
class SolTxData extends TxData {
  String? initTokenAddress;
  String? initTokenAddressSignature;
  String transaction;
  String blockhash;
  String lastValidBlockHeight;
  double fee;

  SolTxData({
    required this.initTokenAddress,
    required this.transaction,
    required this.blockhash,
    required this.lastValidBlockHeight,
    required this.fee,
  });

  factory SolTxData.fromJson(Map<String, dynamic> json) {
    return SolTxData(
      initTokenAddress: json['messageToSign']['initTokenAddress'],
      transaction: json['messageToSign']['transaction'],
      blockhash: json['messageToSign']['blockhash'],
      lastValidBlockHeight: json['messageToSign']['lastValidBlockHeight'],
      fee: json['fee'].toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'messageToSign': {
        'initTokenAddress': initTokenAddress,
        'transaction': transaction,
        'blockhash': blockhash,
        'lastValidBlockHeight': lastValidBlockHeight,
      },
      'fee': fee,
    };
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {
      'messageToSign': {
        'initTokenAddress': initTokenAddressSignature,
        'transaction': signature,
        'blockhash': blockhash,
        'lastValidBlockHeight': lastValidBlockHeight,
      },
      'fee': fee,
    };
  }
}
