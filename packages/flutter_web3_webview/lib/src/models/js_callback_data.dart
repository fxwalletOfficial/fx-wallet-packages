import 'dart:convert';

import 'package:flutter_web3_webview/src/models/js_add_eth_chain.dart';
import 'package:flutter_web3_webview/src/models/js_transaction.dart';

export 'package:flutter_web3_webview/src/models/js_add_eth_chain.dart';
export 'package:flutter_web3_webview/src/models/js_transaction.dart';

class JsCallBackData {
  final String method;
  final dynamic params;

  JsCallBackData({this.method = '', this.params = const <String, dynamic>{}});

  static JsCallBackData fromData(dynamic data) {
    data = data is List && data.isNotEmpty ? data.first : null;
    if (data is! Map<String, dynamic>) return JsCallBackData();

    final method = data['method'] ?? '';
    final params = data['params'] ?? [];
    return JsCallBackData(method: method, params: params);
  }

  JsTransactionObject getTxParams() {
    final json = params is List && params.isNotEmpty ? params.first : params;
    return JsTransactionObject.fromJson(
        json is Map<String, dynamic> ? json : {});
  }

  String getEthSignMsg() {
    if (params is String) return params;
    if (params is List<String> && params.length > 1) return params[1];

    return '';
  }

  String getPersonalSignMsg() {
    if (params is String) return params;
    if (params is List) return json.encode(params);

    return '';
  }

  String getSignTypedDataParams() {
    if (params is! List || params.length < 2) return '';
    final item = params[0] is String ? params[1] : params[0];
    return item is String ? item : json.encode(item);
  }

  JsAddEthereumChain getChainParams() {
    final json = params is List && params.isNotEmpty ? params.first : params;
    return JsAddEthereumChain.fromJson(
        json is Map<String, dynamic> ? json : {});
  }
}
