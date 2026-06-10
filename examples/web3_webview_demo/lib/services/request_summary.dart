import 'dart:convert';

import 'package:flutter_web3_webview/flutter_web3_webview.dart';

/// Human-readable summary of a wallet request, shown in the approval sheet.
///
/// Decoupled from the signers (which only produce signatures) and from the
/// sheet widget (which only renders), so the request-parsing logic lives in
/// one testable place.
class RequestSummary {
  final String title;
  final List<MapEntry<String, String>> rows;

  const RequestSummary({required this.title, required this.rows});

  /// personal_sign / eth_sign message.
  factory RequestSummary.ethMessage({
    required String title,
    required String account,
    required String message,
  }) {
    return RequestSummary(title: title, rows: [
      MapEntry('Account', account),
      MapEntry('Message', decodeEthMessage(message)),
    ]);
  }

  /// eth_signTypedData (v1/v3/v4).
  factory RequestSummary.ethTypedData({
    required String account,
    required String payload,
  }) {
    var primaryType = '(unknown)';
    var domain = '(none)';
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        primaryType = decoded['primaryType']?.toString() ?? primaryType;
        final domainObj = decoded['domain'];
        if (domainObj is Map) {
          domain = domainObj['name']?.toString() ?? domain;
        }
      }
    } catch (_) {
      // Leave placeholders; the title still tells the user what this is.
    }
    return RequestSummary(title: 'Sign typed data', rows: [
      MapEntry('Account', account),
      MapEntry('Domain', domain),
      MapEntry('Primary type', primaryType),
    ]);
  }

  /// eth_sendTransaction.
  factory RequestSummary.ethTransaction({
    required JsTransactionObject transaction,
  }) {
    final json = transaction.toJson();
    return RequestSummary(title: 'Send transaction', rows: [
      MapEntry('From', json['from']?.toString() ?? '(unset)'),
      MapEntry('To', json['to']?.toString() ?? '(contract creation)'),
      MapEntry('Value', json['value']?.toString() ?? '0x0'),
      MapEntry('Gas', json['gas']?.toString() ?? '(estimate)'),
      MapEntry('Data', truncate(json['data']?.toString() ?? '0x')),
    ]);
  }

  /// solana_signMessage.
  factory RequestSummary.solMessage({
    required String account,
    required JsCallBackData data,
  }) {
    final params = data.params;
    var raw = '(none)';
    if (params is Map && params['raw'] is String) {
      raw = truncate(params['raw'] as String);
    }
    return RequestSummary(title: 'Sign Solana message', rows: [
      MapEntry('Account', account),
      MapEntry('Raw (hex)', raw),
    ]);
  }

  /// solana_signTransaction.
  factory RequestSummary.solTransaction({
    required String account,
    required JsCallBackData data,
  }) {
    final params = data.params;
    var message = '(none)';
    if (params is Map && params['message'] is String) {
      message = truncate(params['message'] as String);
    }
    return RequestSummary(title: 'Sign Solana transaction', rows: [
      MapEntry('Account', account),
      MapEntry('Message (base64)', message),
    ]);
  }

  /// Decode a hex-encoded message to UTF-8 for display when it round-trips
  /// cleanly; otherwise return the raw input unchanged.
  static String decodeEthMessage(String message) {
    if (message.startsWith('0x') && (message.length - 2).isEven) {
      try {
        final bytes = <int>[];
        for (var i = 2; i < message.length; i += 2) {
          bytes.add(int.parse(message.substring(i, i + 2), radix: 16));
        }
        return utf8.decode(bytes);
      } catch (_) {
        return message;
      }
    }
    return message;
  }

  static String truncate(String value, {int max = 80}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}… (${value.length} chars)';
  }
}
