import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur_dart/src/registry/registry_type.dart';
import 'package:bc_ur_dart/src/ur.dart';
import 'package:cbor/cbor.dart';
import 'package:convert/convert.dart';

class KeystoneXrpSignatureBytes {
  final String signature;
  final String publicKey;
  final String signedBlob;
  final String txHash;
  final Map<String, dynamic>? payload;

  const KeystoneXrpSignatureBytes({
    this.signature = '',
    this.publicKey = '',
    this.signedBlob = '',
    this.txHash = '',
    this.payload,
  });

  bool get hasSignatureMaterial =>
      signature.isNotEmpty || signedBlob.isNotEmpty;

  static KeystoneXrpSignatureBytes fromUR(UR ur) {
    if (ur.type.toLowerCase() != RegistryType.BYTES.type) {
      throw ArgumentError(
          'Invalid UR type for KeystoneXrpSignatureBytes: ${ur.type}');
    }

    final CborValue decoded = ur.decodeCBOR();
    if (decoded is! CborBytes) {
      throw ArgumentError('Keystone XRP signature payload must be cbor bytes');
    }

    final Uint8List bytes = Uint8List.fromList(decoded.bytes);
    final String text = _tryDecodeUtf8(bytes);
    final dynamic json = _tryDecodeJson(text);
    if (json is Map<String, dynamic>) {
      final result = KeystoneXrpSignatureBytes(
        signature: _readNestedString(
          json,
          ['signature', 'txnSignature', 'TxnSignature'],
        ),
        publicKey: _readNestedString(
          json,
          ['publicKey', 'pubkey', 'SigningPubKey'],
        ),
        signedBlob: _readNestedString(json, [
          'signedBlob',
          'signedTransaction',
          'signedTx',
          'txBlob',
          'tx_blob'
        ]),
        txHash: _readNestedString(json, ['txHash', 'tx_hash', 'hash']),
        payload: json,
      );
      if (!result.hasSignatureMaterial) {
        throw ArgumentError('Invalid Keystone XRP signature bytes payload');
      }
      return result;
    }

    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      final String hexBlob = hex.encode(bytes);
      if (hexBlob.isEmpty) {
        throw ArgumentError('Invalid Keystone XRP signature bytes payload');
      }
      return KeystoneXrpSignatureBytes(signedBlob: hexBlob);
    }

    if (_looksLikeSignedBlob(trimmed)) {
      return KeystoneXrpSignatureBytes(signedBlob: trimmed);
    }

    return KeystoneXrpSignatureBytes(signature: trimmed);
  }

  static dynamic _tryDecodeJson(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  static String _tryDecodeUtf8(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return '';
    }
  }

  static String _readNestedString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final direct = json[key];
      final normalized = _normalizeValue(direct);
      if (normalized.isNotEmpty) return normalized;
    }

    for (final value in json.values) {
      if (value is Map<String, dynamic>) {
        final nested = _readNestedString(value, keys);
        if (nested.isNotEmpty) return nested;
      }
      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final nested = _readNestedString(item, keys);
            if (nested.isNotEmpty) return nested;
          }
        }
      }
    }

    return '';
  }

  static String _normalizeValue(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    return '';
  }

  static bool _looksLikeSignedBlob(String value) {
    final hex = RegExp(r'^[0-9A-Fa-f]+$');
    return value.length > 32 && value.length.isEven && hex.hasMatch(value);
  }
}
