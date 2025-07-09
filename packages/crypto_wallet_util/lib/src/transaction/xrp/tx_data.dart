import 'package:crypto_wallet_util/src/type/type.dart';
import 'xrp_lib.dart';

/// [XrpTxData] requires [account], [transactionType], [destination], [amount], [limitAmount], [sequence], [fee], [lastLedgerSequence]
/// [XrpTxData] is the parameter to be signed.
class XrpTxData extends TxData {
  XrpTxData({
    required this.account,
    required this.transactionType,
    this.destination,
    this.amount,
    this.limitAmount,
    this.flags = 0,
    required this.sequence,
    required this.fee,
    required this.lastLedgerSequence,
  });
  final String account;
  final String transactionType;
  final String? destination;
  final XrpAmountType? amount;
  final XrpTokenAmount? limitAmount;
  final int flags;
  final int sequence;
  final String fee;
  final int lastLedgerSequence;
  String? signingPubKey;
  String? signedBlob;
  String? txHash;

  factory XrpTxData.fromJson(Map<String, dynamic> txJson) {
    if (txJson['TransactionType'] == XrpTransactionType.trustSet) {
      final limitAmount = XrpTokenAmount(
          currency: txJson['LimitAmount']['currency'],
          issuer: txJson['LimitAmount']['issuer'],
          value: txJson['LimitAmount']['value']);
      return XrpTxData(
          account: txJson['Account'],
          transactionType: txJson['TransactionType'],
          sequence: txJson['Sequence'],
          fee: txJson['Fee'],
          lastLedgerSequence: txJson['LastLedgerSequence'],
          limitAmount: limitAmount,
          flags: txJson['Flags']);
    } else if (txJson['Amount'] is String) {
      final XrpAmountType xrpAmount = XrpAmount(amount: txJson['Amount']);
      return XrpTxData(
          account: txJson['Account'],
          transactionType: txJson['TransactionType'],
          sequence: txJson['Sequence'],
          fee: txJson['Fee'],
          lastLedgerSequence: txJson['LastLedgerSequence'],
          destination: txJson['Destination'],
          amount: xrpAmount,
          flags: txJson['Flags']);
    } else if (txJson['Amount'] is Object) {
      final XrpAmountType tokenAmount = XrpTokenAmount(
          currency: txJson['Amount']['currency'],
          issuer: txJson['Amount']['issuer'],
          value: txJson['Amount']['value']);
      return XrpTxData(
          account: txJson['Account'],
          transactionType: txJson['TransactionType'],
          sequence: txJson['Sequence'],
          fee: txJson['Fee'],
          lastLedgerSequence: txJson['LastLedgerSequence'],
          destination: txJson['Destination'],
          amount: tokenAmount,
          flags: txJson['Flags']);
    } else {
      throw Exception('Error transaction type');
    }
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      'Account': account,
      'TransactionType': transactionType,
      'Flags': flags,
      'Sequence': sequence,
      'Fee': fee,
      'LastLedgerSequence': lastLedgerSequence,
      'SigningPubKey': signingPubKey
    };
    switch (transactionType) {
      case XrpTransactionType.payment:
        json = {...json, 'Destination': destination};
        if (amount is XrpAmount) {
          return {...json, 'Amount': amount!.amount};
        } else if (amount is XrpTokenAmount) {
          return {...json, 'Amount': amount!.toJson()};
        } else {
          throw Exception('unsupported amount format');
        }
      case XrpTransactionType.trustSet:
        return {...json, 'LimitAmount': limitAmount!.toJson()};
      default:
        throw Exception('unsupported transaction type');
    }
  }

  @override
  Map<String, dynamic> toBroadcast() {
    if (!isSigned) return {};
    Map<String, dynamic> json = {
      'tx_blob': signature,
    };
    return json;
  }
}
