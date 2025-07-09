/// Provide signature related basic data in transaction data.
/// [message] and [signature] filled in during the signing process for subsequent unified verification; 
/// [isSigned] indicates whether the transaction has been signed.
/// [toJson] provides a way to print transaction data, and [toBroadcast] assembles the parameters required for broadcasting.
abstract class TxData {
  bool isSigned = false;
  String message = '';
  String signature = '';
  Map<String, dynamic> toJson(); // get data
  Map<String, dynamic> toBroadcast(); // get data to broadcast
}
