import 'package:crypto_wallet_util/src/type/type.dart';

/// [SuiTxData] requires [messageToSign], [fee], [feeRefund]
/// [messageToSign] is the parameter to be signed.
class SuiTxData extends TxData {
  MessageToSign messageToSign;
  String fee;
  String feeRefund;
  String publickey = '';

  SuiTxData(this.messageToSign, this.fee, this.feeRefund);

  factory SuiTxData.fromJson(Map<String, dynamic> json) {
    return SuiTxData(
      MessageToSign.fromJson(json['messageToSign']),
      json['fee'],
      json['fee_refund'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'messageToSign': messageToSign.toJson(),
      'fee': fee,
      'fee_refund': feeRefund,
    };
  }

  @override
  Map<String, dynamic> toBroadcast() {
    return {
      'tx': {
        'tx_bytes': messageToSign.txByte,
        'publicKey': publickey,
        'signature': signature
      }
    };
  }
}

class MessageToSign {
  String transaction;
  String txByte;

  MessageToSign({required this.transaction, required this.txByte});

  factory MessageToSign.fromJson(Map<String, dynamic> json) {
    return MessageToSign(
      transaction: json['transaction'],
      txByte: json['tx_byte'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction': transaction,
      'tx_byte': txByte,
    };
  }
}
