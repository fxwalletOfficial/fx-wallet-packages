import './origin.dart';

enum BtcTxType { TAPROOT, BTC }

class BtcTransferInfo {
  final String chain;
  final String xpubkey;
  final String inputAddress;
  final String outputAddress;
  final String path;
  final BtcTxType txType;
  final String masterFingerprint;
  final Origin origin;

  BtcTransferInfo(
      {required this.chain,
      required this.xpubkey,
      required this.inputAddress,
      required this.outputAddress,
      required this.path,
      required this.txType,
      required this.masterFingerprint,
      required this.origin});

  factory BtcTransferInfo.fromJson(Map<String, dynamic> json) {
    BtcTxType txType = BtcTxType.BTC;
    if (json["txType"] == "TxType.TAPROOT") txType = BtcTxType.TAPROOT;
    return BtcTransferInfo(
        chain: json["chain"].toLowerCase(),
        path: json["path"],
        txType: txType,
        xpubkey: json["xpubkey"],
        origin: Origin.fromJson(json["origin"]),
        masterFingerprint: json["masterFingerprint"],
        inputAddress: json['inputAddress'],
        outputAddress: json['outputAddress']);
  }
}
