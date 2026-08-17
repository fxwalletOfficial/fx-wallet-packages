import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';

/// Mirrors the normalisation the injected provider bridge performs: take
/// everything after the last sentinel, cut at the last `}`, then JSON-parse.
Map<String, dynamic>? parseLikeBridge(String message) {
  final index = message.lastIndexOf(Web3RpcError.sentinel);
  if (index == -1) return null;
  final tail = message.substring(index + Web3RpcError.sentinel.length);
  final close = tail.lastIndexOf('}');
  final payload = close == -1 ? tail : tail.substring(0, close + 1);
  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic> && decoded['code'] is int) return decoded;
    return null;
  } catch (_) {
    return null;
  }
}

void main() {
  group('Web3RpcError factories carry the agreed EIP-1193 codes', () {
    final cases = <String, MapEntry<Web3RpcError, int>>{
      'userRejected': MapEntry(Web3RpcError.userRejected(), 4001),
      'unauthorized': MapEntry(Web3RpcError.unauthorized(), 4100),
      'unsupportedMethod': MapEntry(Web3RpcError.unsupportedMethod(), 4200),
      'cancelled': MapEntry(Web3RpcError.cancelled(), 4900),
      'unrecognizedChain': MapEntry(Web3RpcError.unrecognizedChain(), 4902),
      'requestUnavailable': MapEntry(Web3RpcError.requestUnavailable(), -32002),
      'limitExceeded': MapEntry(Web3RpcError.limitExceeded(), -32005),
      'internal': MapEntry(Web3RpcError.internal(), -32603),
    };

    cases.forEach((name, entry) {
      test('$name -> ${entry.value}', () {
        expect(entry.key.code, entry.value);
        expect(parseLikeBridge(entry.key.toString())?['code'], entry.value);
      });
    });
  });

  group('wire format stays parseable by the bridge', () {
    test('sentinel prefixes a compact JSON payload', () {
      expect(Web3RpcError.sentinel, 'Web3RpcError: ');
      expect(
        const Web3RpcError(4100, 'Unauthorized').toString(),
        'Web3RpcError: {"code":4100,"message":"Unauthorized"}',
      );
    });

    test('data is omitted when null and kept when present', () {
      expect(const Web3RpcError(4001, 'nope').toJson().containsKey('data'), isFalse);
      expect(
        const Web3RpcError(4902, 'Unrecognized chain ID', data: {'chainId': '0x1'}).toJson()['data'],
        {'chainId': '0x1'},
      );
    });

    test('still locatable after the platform layer wraps it again', () {
      final wrapped = Exception(Web3RpcError.requestUnavailable()).toString();

      expect(parseLikeBridge(wrapped)?['code'], -32002);
    });

    test('default messages of the wallet-facing factories are fixed', () {
      expect(Web3RpcError.unauthorized().message, 'Unauthorized');
      expect(Web3RpcError.internal().message, 'Internal wallet error');
      expect(
        Web3RpcError.requestUnavailable().message,
        'Request temporarily unavailable, please retry',
      );
    });
  });
}
