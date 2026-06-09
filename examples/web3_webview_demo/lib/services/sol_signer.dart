import 'package:flutter_web3_webview/flutter_web3_webview.dart';

import 'package:web3_webview_demo/services/wallet_state.dart';

/// Solana signing surface the browser page drives.
///
/// Mirrors [EthSigner]: Phase 3 wires the approval flow against
/// [MockSolSigner]; Phase 5 adds the real ed25519 implementation
/// (`cryptography` + `bs58`) behind the same interface.
abstract class SolSigner {
  /// `solana_signMessage`. The wallet receives `{ raw: <hex> }`; the
  /// result is the base58-encoded signature the JS bridge decodes back
  /// into bytes.
  Future<String> signMessage({
    required DemoAccount account,
    required JsCallBackData data,
  });

  /// `solana_signTransaction`. The wallet receives
  /// `{ raw: <hex>, message: <base64> }`; the result is the base58-encoded
  /// signature the JS bridge attaches to the transaction.
  Future<String> signTransaction({
    required DemoAccount account,
    required JsCallBackData data,
  });
}

/// Deterministic placeholder Solana signer (see [MockEthSigner] for the
/// rationale). Returns a stable base58-ish string keyed off the account +
/// payload; not a valid ed25519 signature.
class MockSolSigner implements SolSigner {
  const MockSolSigner();

  static const String _base58Alphabet =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  @override
  Future<String> signMessage({
    required DemoAccount account,
    required JsCallBackData data,
  }) async {
    return _mockSignature('msg', account, data);
  }

  @override
  Future<String> signTransaction({
    required DemoAccount account,
    required JsCallBackData data,
  }) async {
    return _mockSignature('tx', account, data);
  }

  String _mockSignature(String tag, DemoAccount account, JsCallBackData data) {
    final seed =
        '$tag:${account.solanaAddress}:${data.method}:${data.params}'
            .hashCode
            .abs();
    // ed25519 signatures are 64 bytes → ~88 base58 chars. Build a stable
    // pseudo-base58 string of that length from the seed.
    final buffer = StringBuffer();
    var value = seed;
    while (buffer.length < 88) {
      buffer.write(_base58Alphabet[value % _base58Alphabet.length]);
      value = (value * 1103515245 + 12345) & 0x7fffffff;
    }
    return buffer.toString();
  }
}
