import 'dart:convert';

import 'package:crypto_wallet_util/src/type/tx_data_type.dart';

/// Holds the assembled SC transaction plus the signing digests.
class ScTxData extends TxData {
  /// The full transaction map (WASM output with `satisfiedPolicy.signatures`).
  final Map<String, dynamic> transaction;

  /// Hex-encoded digests, one per siacoinInput.
  final List<String> toSign;

  ScTxData({
    required this.transaction,
    required this.toSign,
  });

  factory ScTxData.fromJson(Map<String, dynamic> json) {
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

  /// Build the legacy broadcast payload matching `buildLegacyBroadcastPayload`
  /// in the JS reference.
  ///
  /// Converts the first hex signature to base64 and adds it under a
  /// `transactionSignatures` field, then wraps everything in `{ data: ... }`.
  @override
  Map<String, dynamic> toBroadcast() {
    if (!isSigned) return {};

    final data = Map<String, dynamic>.from(transaction);

    final inputs = data['siacoinInputs'] as List<dynamic>?;
    final sigs = inputs?.isNotEmpty == true
        ? inputs!.first['satisfiedPolicy']['signatures'] as List<dynamic>?
        : null;
    final firstSigHex = sigs?.isNotEmpty == true ? sigs!.first as String : null;

    if (firstSigHex == null) {
      return {};
    }

    data['transactionSignatures'] = [
      {
        'signature': base64.encode(
          List<int>.generate(firstSigHex.length ~/ 2, (i) {
            return int.parse(firstSigHex.substring(i * 2, i * 2 + 2),
                radix: 16);
          }),
        ),
      }
    ];

    return {'data': data};
  }
}
