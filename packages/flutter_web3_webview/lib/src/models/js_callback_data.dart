import 'dart:convert';

import 'package:flutter_web3_webview/src/models/js_add_eth_chain.dart';
import 'package:flutter_web3_webview/src/models/js_transaction.dart';

export 'package:flutter_web3_webview/src/models/js_add_eth_chain.dart';
export 'package:flutter_web3_webview/src/models/js_transaction.dart';

class JsCallBackData {
  final String method;
  final dynamic params;

  /// Request identity minted by the in-page provider bridge
  /// (`provider/packages/core/adapter/FlutterBridge.ts`).
  ///
  /// Optional on purpose. The bridge payload is reachable from page script —
  /// a DApp can call `flutter_inappwebview.callHandler('FxWalletHandler', …)`
  /// itself, and an older injected bundle predates the field — so a payload
  /// without an `id` stays valid and the queue substitutes a synthetic id
  /// instead (see `SerialEventQueue.add`). Correlation with the in-page
  /// promise is simply unavailable for those requests; nothing else changes.
  final String? id;

  JsCallBackData({
    this.method = '',
    this.params = const <String, dynamic>{},
    this.id,
  });

  static JsCallBackData fromData(dynamic data) {
    final payload = data is List && data.isNotEmpty ? data.first : data;
    final json = _asStringKeyedMap(payload);
    if (json == null) return JsCallBackData();

    final method = json['method'] is String ? json['method'] as String : '';
    final params = json['params'] ?? [];
    return JsCallBackData(method: method, params: params, id: _asId(json['id']));
  }

  JsTransactionObject getTxParams() {
    final json = params is List && params.isNotEmpty ? params.first : params;
    return JsTransactionObject.fromJson(_asStringKeyedMap(json) ?? {});
  }

  String getEthSignMsg() {
    if (params is String) return params;
    if (params is List && params.length > 1 && params[1] is String) {
      return params[1] as String;
    }

    return '';
  }

  String getPersonalSignMsg() {
    if (params is String) return params;
    if (params is List && params.isNotEmpty) {
      final message = params.first;
      return message is String ? message : json.encode(message);
    }

    return '';
  }

  String getSignTypedDataParams() {
    if (params is! List || params.length < 2) return '';
    final item = params[0] is String ? params[1] : params[0];
    return item is String ? item : json.encode(item);
  }

  JsAddEthereumChain getChainParams() {
    final json = params is List && params.isNotEmpty ? params.first : params;
    return JsAddEthereumChain.fromJson(_asStringKeyedMap(json) ?? {});
  }
}

/// Normalise the wire `id`. The bridge sends a string, but the payload is
/// page-controlled and the platform channel may hand a numeric literal back
/// as `int`/`double`, so accept both and reject anything else (including an
/// empty string) rather than fabricating an identity.
String? _asId(dynamic value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value is num) return value.toString();
  return null;
}

Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
  if (value is! Map) return null;
  if (value.keys.any((key) => key is! String)) return null;
  return Map<String, dynamic>.from(value);
}
