import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';

import 'package:web3_webview_demo/services/base58.dart';
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

/// Real Solana signer: ed25519 over the demo account's fixed seed, using
/// the `cryptography` package and the hand-rolled base58 codec.
///
/// The two methods return *different* encodings on purpose, matching what
/// the injected provider JavaScript expects:
///   * `solana_signMessage` → hex (the provider's `messageToBuffer` decodes
///     the wallet response as hex);
///   * `solana_signTransaction` → base58 (the provider's
///     `mapSignedTransaction` runs `bs58.decode` on the response).
class Ed25519SolSigner implements SolSigner {
  const Ed25519SolSigner();

  static final Ed25519 _ed = Ed25519();

  Future<SimpleKeyPair> _keyPair(DemoAccount account) {
    return _ed.newKeyPairFromSeed(hexDecode(account.solanaSeed));
  }

  /// base58 public key (Solana address) for [account]. Used by the tests to
  /// assert the catalogue addresses match the seeds.
  Future<String> addressOf(DemoAccount account) async {
    final pub = await (await _keyPair(account)).extractPublicKey();
    return base58Encode(Uint8List.fromList(pub.bytes));
  }

  @override
  Future<String> signMessage({
    required DemoAccount account,
    required JsCallBackData data,
  }) async {
    final sig = await _sign(account, _rawBytes(data));
    // hex out — the provider decodes this with messageToBuffer.
    return '0x${hexEncode(sig)}';
  }

  @override
  Future<String> signTransaction({
    required DemoAccount account,
    required JsCallBackData data,
  }) async {
    final sig = await _sign(account, _rawBytes(data));
    // base58 out — the provider decodes this with bs58.decode.
    return base58Encode(sig);
  }

  Future<Uint8List> _sign(DemoAccount account, Uint8List message) async {
    final keyPair = await _keyPair(account);
    final signature = await _ed.sign(message, keyPair: keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  /// Extract the signed-over bytes from the `{ raw: <hex>, … }` params both
  /// Solana methods carry.
  Uint8List _rawBytes(JsCallBackData data) {
    final params = data.params;
    if (params is Map && params['raw'] is String) {
      return hexDecode(params['raw'] as String);
    }
    return Uint8List(0);
  }
}
