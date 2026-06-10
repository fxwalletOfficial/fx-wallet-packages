import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_web3_webview/flutter_web3_webview.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
// EthereumAddress / EtherAmount live in the `wallet` package that web3dart
// depends on but does not re-export.
import 'package:wallet/wallet.dart' show EthereumAddress, EtherAmount;

import 'package:web3_webview_demo/services/eip712.dart';
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

/// Real EVM signer backed by `web3dart` + the local [Eip712] encoder.
///
/// Produces cryptographically valid secp256k1 signatures against the demo
/// account's (public Hardhat) private key. `sendTransaction` signs an
/// EIP-1559 transaction and either returns a deterministic mock hash (the
/// default) or broadcasts it over the chain's RPC when `broadcast` is set.
class Web3DartEthSigner implements EthSigner {
  const Web3DartEthSigner();

  EthPrivateKey _key(DemoAccount account) =>
      EthPrivateKey.fromHex(account.evmPrivateKey);

  @override
  Future<String> personalSign({
    required DemoAccount account,
    required String message,
  }) async {
    // personal_sign signs the raw message bytes with the EIP-191 prefix.
    // DApps usually hex-encode the bytes; fall back to UTF-8 otherwise.
    final bytes = message.startsWith('0x')
        ? hexToBytes(message)
        : Uint8List.fromList(utf8.encode(message));
    final sig = _key(account).signPersonalMessageToUint8List(bytes);
    return '0x${bytesToHex(sig)}';
  }

  @override
  Future<String> ethSign({
    required DemoAccount account,
    required String message,
  }) async {
    // Legacy eth_sign signs a 32-byte hash directly, no prefix.
    final hash = message.startsWith('0x')
        ? hexToBytes(message)
        : keccak256(Uint8List.fromList(utf8.encode(message)));
    return _encodeSignature(sign(hash, _key(account).privateKey));
  }

  @override
  Future<String> signTypedData({
    required DemoAccount account,
    required String payload,
  }) async {
    final digest = Eip712.digestFromJson(payload);
    return _encodeSignature(sign(digest, _key(account).privateKey));
  }

  @override
  Future<String> sendTransaction({
    required DemoAccount account,
    required JsTransactionObject transaction,
    required bool broadcast,
    required String rpcUrl,
  }) async {
    final json = transaction.toJson();
    final cred = _key(account);

    if (!broadcast) {
      // Mock path: sign the request payload to prove the key is usable,
      // then return a deterministic hash of that signature. We don't build
      // a full EIP-1559 RLP here because that requires the account nonce
      // and a gas price from the network, which the offline path avoids.
      final payload = Uint8List.fromList(utf8.encode(jsonEncode(json)));
      final sig = sign(keccak256(payload), cred.privateKey);
      final sigBytes = BytesBuilder()
        ..add(_pad32(sig.r))
        ..add(_pad32(sig.s))
        ..addByte(sig.v);
      return '0x${bytesToHex(keccak256(sigBytes.toBytes()))}';
    }

    final tx = Transaction(
      from: cred.address,
      to: json['to'] is String
          ? EthereumAddress.fromHex(json['to'] as String)
          : null,
      value: _weiOrNull(json['value']),
      maxGas: _intOrNull(json['gas']),
      data: json['data'] is String && (json['data'] as String).length > 2
          ? hexToBytes(json['data'] as String)
          : null,
    );

    final client = Web3Client(rpcUrl, http.Client());
    try {
      return await client.sendTransaction(cred, tx,
          chainId: _chainIdFrom(json));
    } finally {
      await client.dispose();
    }
  }

  String _encodeSignature(MsgSignature sig) {
    final r = _pad32(sig.r);
    final s = _pad32(sig.s);
    final builder = BytesBuilder()
      ..add(r)
      ..add(s)
      ..addByte(sig.v);
    return '0x${bytesToHex(builder.toBytes())}';
  }

  Uint8List _pad32(BigInt value) {
    final out = Uint8List(32);
    var v = value;
    for (var i = 31; i >= 0; i--) {
      out[i] = (v & BigInt.from(0xff)).toInt();
      v = v >> 8;
    }
    return out;
  }

  EtherAmount? _weiOrNull(dynamic value) {
    if (value is! String) return null;
    final hex = value.startsWith('0x') ? value.substring(2) : value;
    if (hex.isEmpty) return null;
    return EtherAmount.inWei(BigInt.parse(hex, radix: 16));
  }

  int? _intOrNull(dynamic value) {
    if (value is! String) return null;
    final hex = value.startsWith('0x') ? value.substring(2) : value;
    if (hex.isEmpty) return null;
    return int.parse(hex, radix: 16);
  }

  int _chainIdFrom(Map<String, dynamic> json) {
    final raw = json['chainId'];
    if (raw is String && raw.startsWith('0x')) {
      return int.parse(raw.substring(2), radix: 16);
    }
    if (raw is int) return raw;
    return 1;
  }
}

