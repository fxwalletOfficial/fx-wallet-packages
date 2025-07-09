import '../cosmos_dart.dart';

/// Extends [TxResponse] with useful methods.
extension TxResponseExt on TxResponse {
  /// Returns true if the response is successful, and false otherwise.
  bool get isSuccessful {
    return code == 0;
  }
}
