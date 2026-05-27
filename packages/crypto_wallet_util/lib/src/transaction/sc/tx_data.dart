import 'package:crypto_wallet_util/src/type/tx_data_type.dart';

/// [ScTxData] holds the assembled Sia V2 transaction plus the signing digests.
///
/// The [transaction] map stores the full V2 transaction JSON (the WASM output
/// with `satisfiedPolicy.signatures`).
/// The [toSign] list contains the hex-encoded digests, one per siacoinInput.
class ScTxData extends TxData {
  /// The full V2 transaction map (WASM output structure).
  final Map<String, dynamic> transaction;

  /// Hex-encoded digests to be signed, one per siacoinInput.
  final List<String> toSign;

  ScTxData({
    required this.transaction,
    required this.toSign,
  });

  factory ScTxData.fromJson(Map<String, dynamic> json) {
    // Support both the older `transaction_sc` wrapper and direct V2 format
    final txJson = json['transaction_sc'] ?? json['transaction'] ?? json;
    final tx = Map<String, dynamic>.from(
        txJson is Map<String, dynamic> ? txJson : json);
    final toSign = (json['to_sign'] as List<dynamic>? ??
            (json['toSign'] as List<dynamic>? ?? []))
        .map((item) => '$item')
        .toList();
    return ScTxData(
      transaction: tx,
      toSign: toSign,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'transaction_sc': transaction,
      'to_sign': toSign,
    };
  }

  /// Returns the signed V2 transaction ready for broadcast.
  ///
  /// After [isSigned] is true, `satisfiedPolicy.signatures` will contain
  /// the hex-encoded Ed25519 signatures.
  @override
  Map<String, dynamic> toBroadcast() {
    if (!isSigned) return {};
    return Map<String, dynamic>.from(transaction);
  }
}
