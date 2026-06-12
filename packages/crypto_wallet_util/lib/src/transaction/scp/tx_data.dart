import 'package:crypto_wallet_util/src/transaction/scp/scp_lib.dart';
import 'package:crypto_wallet_util/src/type/tx_data_type.dart';

/// Holds the assembled SCP transaction plus the signing digests.
///
/// Unlike [ScTxData], SCP does not use WASM — digests are computed in pure Dart
/// via [ScpSigHash], and signatures are stored in `transactionSignatures[*].signature`
/// (base64-encoded Ed25519).
class ScpTxData extends TxData {
  /// The full signed transaction map (API shape with `transactionSignatures`).
  final Map<String, dynamic> transaction;

  /// Hex-encoded digests, one per [transactionSignatures] entry.
  final List<String> toSign;

  /// The transaction signature entries (parallel to [toSign]).
  final List<ScpTransactionSignature> transactionSignatures;

  ScpTxData({
    required this.transaction,
    required this.toSign,
    this.transactionSignatures = const [],
  });

  factory ScpTxData.fromJson(Map<String, dynamic> json) {
    final txJson = json['transaction_scp'] ?? json['transaction'] ?? json;
    final tx = Map<String, dynamic>.from(
        txJson is Map<String, dynamic> ? txJson : json);
    final toSign = (json['to_sign'] as List<dynamic>? ??
            (json['toSign'] as List<dynamic>? ?? []))
        .map((item) => '$item')
        .toList();
    return ScpTxData(
      transaction: tx,
      toSign: toSign,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'transaction_scp': transaction,
      'to_sign': toSign,
    };
  }

  /// Build the broadcast payload matching the JS reference:
  /// `{ data: signedTx }`.
  @override
  Map<String, dynamic> toBroadcast() {
    if (!isSigned) return {};
    return {'data': transaction};
  }
}
