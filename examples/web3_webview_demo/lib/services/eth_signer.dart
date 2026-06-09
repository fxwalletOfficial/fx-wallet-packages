import 'dart:convert';

import 'package:flutter_web3_webview/flutter_web3_webview.dart';

import 'package:web3_webview_demo/services/wallet_state.dart';

/// EVM signing surface the browser page drives.
///
/// Phase 3 wires the approval flow against [MockEthSigner], which returns
/// deterministic placeholder signatures so the whole request → approval →
/// response round-trip can be exercised before the real `web3dart`-backed
/// implementation lands in Phase 4. Phase 4 adds a `Web3DartEthSigner`
/// implementing this same interface and swaps it in at the app shell.
abstract class EthSigner {
  /// EIP-191 `personal_sign`. [message] is the raw message the DApp passed
  /// (hex or UTF-8); the result is a 65-byte `0x`-prefixed signature.
  Future<String> personalSign({
    required DemoAccount account,
    required String message,
  });

  /// Legacy `eth_sign`. Same signature shape as [personalSign].
  Future<String> ethSign({
    required DemoAccount account,
    required String message,
  });

  /// `eth_signTypedData` (v1/v3/v4). [payload] is the typed-data JSON
  /// string; the result is a 65-byte `0x`-prefixed signature.
  Future<String> signTypedData({
    required DemoAccount account,
    required String payload,
  });

  /// `eth_sendTransaction`. Returns the `0x`-prefixed transaction hash.
  ///
  /// When [broadcast] is false the implementation signs but does not
  /// submit, returning a deterministic mock hash; when true it broadcasts
  /// over [rpcUrl] and returns the real hash.
  Future<String> sendTransaction({
    required DemoAccount account,
    required JsTransactionObject transaction,
    required bool broadcast,
    required String rpcUrl,
  });
}

/// Deterministic placeholder signer used until Phase 4 lands the real
/// `web3dart` implementation. Signatures are stable functions of the
/// account + payload so the demo stays reproducible, but they are **not**
/// cryptographically valid — a DApp that verifies the signature on-chain
/// will reject them. That's fine for exercising the bridge plumbing.
class MockEthSigner implements EthSigner {
  const MockEthSigner();

  @override
  Future<String> personalSign({
    required DemoAccount account,
    required String message,
  }) async {
    return _mockSignature('personal_sign', account, message);
  }

  @override
  Future<String> ethSign({
    required DemoAccount account,
    required String message,
  }) async {
    return _mockSignature('eth_sign', account, message);
  }

  @override
  Future<String> signTypedData({
    required DemoAccount account,
    required String payload,
  }) async {
    return _mockSignature('typed_data', account, payload);
  }

  @override
  Future<String> sendTransaction({
    required DemoAccount account,
    required JsTransactionObject transaction,
    required bool broadcast,
    required String rpcUrl,
  }) async {
    // Mock signer never broadcasts; returns a deterministic fake hash.
    return _mockHash(account, jsonEncode(transaction.toJson()));
  }

  String _mockSignature(String tag, DemoAccount account, String payload) {
    // 65 bytes = 130 hex chars.
    return '0x${_hexFill('$tag:${account.evmAddress}:$payload', 130)}';
  }

  String _mockHash(DemoAccount account, String payload) {
    // 32 bytes = 64 hex chars.
    return '0x${_hexFill('${account.evmAddress}:$payload', 64)}';
  }

  /// Deterministically expand a seed string into [length] hex characters by
  /// repeatedly hashing the running buffer. Stable for identical input.
  String _hexFill(String seed, int length) {
    final buffer = StringBuffer();
    var value = seed.hashCode.abs();
    while (buffer.length < length) {
      buffer.write(value.toRadixString(16).padLeft(8, '0'));
      value = (value * 1103515245 + 12345) & 0x7fffffff;
    }
    return buffer.toString().substring(0, length);
  }
}
