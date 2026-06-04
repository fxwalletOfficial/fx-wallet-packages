import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/transaction/scp/scp_lib.dart';
import 'package:crypto_wallet_util/src/utils/blake2b.dart';

/// Pure-Dart implementation of the SCP V2 signing digest (`scpSigHash`).
///
/// Translates the JS `scpSigHash()` function: concatenates canonically-encoded
/// transaction fields and hashes with Blake2b-256.
class ScpSigHash {
  /// Compute signing digests for every [transactionSignatures] entry.
  ///
  /// Returns hex-encoded digests, one per signature entry.
  static List<String> computeDigests(ScpUnsignedTransaction tx) {
    final digests = <String>[];
    for (final entry in tx.transactionSignatures) {
      final digestBytes = _sigHash(tx, entry);
      digests.add(_bytesToHex(digestBytes));
    }
    return digests;
  }

  /// Compute a single signing digest for the given [signatureEntry].
  static Uint8List _sigHash(
      ScpUnsignedTransaction txn, ScpTransactionSignature signatureEntry) {
    final parts = <Uint8List>[];

    // siacoinInputs
    parts.add(_encodeInt(txn.siacoinInputs.length));
    for (final input in txn.siacoinInputs) {
      parts.add(_encodeInput(input));
    }

    // siacoinOutputs
    parts.add(_encodeInt(txn.siacoinOutputs.length));
    for (final output in txn.siacoinOutputs) {
      parts.add(_encodeOutput(output));
    }

    // Five empty lists (file contracts, file contract revisions,
    // storage proofs, siafund inputs, siafund outputs)
    parts.add(_encodeInt(0));
    parts.add(_encodeInt(0));
    parts.add(_encodeInt(0));
    parts.add(_encodeInt(0));
    parts.add(_encodeInt(0));

    // minerFees
    parts.add(_encodeInt(txn.minerFees.length));
    for (final fee in txn.minerFees) {
      parts.add(_encodeCurrency(fee));
    }

    // arbitraryData
    final arbData = txn.arbitraryData;
    parts.add(_encodeInt(arbData.length));
    for (final item in arbData) {
      parts.add(_encodeArbitraryData(item));
    }

    // Signature-specific fields
    parts.add(_hexToBytes(signatureEntry.parentID));
    parts.add(_encodeInt(signatureEntry.publicKeyIndex));
    parts.add(_encodeInt(0)); // timelock

    // Concatenate all parts and hash
    final totalLength = parts.fold<int>(0, (sum, p) => sum + p.length);
    final buf = Uint8List(totalLength);
    var offset = 0;
    for (final part in parts) {
      buf.setRange(offset, offset + part.length, part);
      offset += part.length;
    }

    return Blake2b.getBlake2bHash(buf, size: 32);
  }

  /// Encode a single siacoin input: `[0x00, parentID, unlockConditions]`.
  static Uint8List _encodeInput(ScpSiacoinInput input) {
    final parts = <Uint8List>[
      Uint8List.fromList([0]),
      _hexToBytes(input.parentID),
      _encodeUnlockConditions(input.unlockConditions),
    ];
    return _concat(parts);
  }

  /// Encode a single siacoin output: `[currency(value), unlockHash[:32]]`.
  static Uint8List _encodeOutput(ScpSiacoinOutput output) {
    final hashBytes = _hexToBytes(output.unlockHash);
    final parts = <Uint8List>[
      _encodeCurrency(output.value),
      Uint8List.fromList(hashBytes.sublist(0, 32)),
    ];
    return _concat(parts);
  }

  /// Encode unlock conditions:
  /// `[int64le(timelock), int64le(pubKeyCount), ...pubKeys, int64le(sigReq)]`.
  static Uint8List _encodeUnlockConditions(ScpUnlockConditions uc) {
    final parts = <Uint8List>[
      _encodeInt(uc.timelock),
      _encodeInt(uc.publicKeys.length),
    ];
    for (final pk in uc.publicKeys) {
      parts.add(_encodePublicKey(pk));
    }
    parts.add(_encodeInt(uc.signaturesRequired));
    return _concat(parts);
  }

  /// Encode a public key string `"algorithm:hexkey"`.
  ///
  /// Format: `[16-byte algorithm name padded with zeros, int64le(keyLen), keyBytes]`.
  static Uint8List _encodePublicKey(String publicKey) {
    final colonIndex = publicKey.indexOf(':');
    final algorithm = publicKey.substring(0, colonIndex);
    final keyHex = publicKey.substring(colonIndex + 1);

    final algorithmBytes = Uint8List(16);
    final algoUtf8 = utf8.encode(algorithm);
    algorithmBytes.setRange(0, algoUtf8.length, algoUtf8);

    final keyBytes = _hexToBytes(keyHex);

    return _concat([
      algorithmBytes,
      _encodeInt(keyBytes.length),
      keyBytes,
    ]);
  }

  /// Encode a currency value as Sia's variable-length encoding:
  /// `[int64le(byteLength), big-endian bytes]`.
  static Uint8List _encodeCurrency(String value) {
    final bigintValue = BigInt.parse(value);
    if (bigintValue < BigInt.zero) {
      throw ArgumentError('Negative currency value: $value');
    }

    var hex = bigintValue.toRadixString(16);
    if (hex == '0') {
      hex = '';
    } else if (hex.length % 2 != 0) {
      hex = '0$hex';
    }

    final bytes = hex.isEmpty ? Uint8List(0) : _hexToBytes(hex);
    return _concat([
      _encodeInt(bytes.length),
      bytes,
    ]);
  }

  /// Encode arbitrary data (base64 string): `[int64le(byteLength), bytes]`.
  static Uint8List _encodeArbitraryData(String base64Value) {
    final bytes = base64.decode(base64Value);
    return _concat([
      _encodeInt(bytes.length),
      bytes,
    ]);
  }

  /// Encode an integer as 8-byte little-endian (matching JS `writeInt32LE` into
  /// an 8-byte buffer).
  static Uint8List _encodeInt(int value) {
    final bytes = ByteData(8);
    bytes.setInt32(0, value, Endian.little);
    return bytes.buffer.asUint8List();
  }

  /// Convert a hex string to bytes. Strips optional `0x` prefix.
  static Uint8List _hexToBytes(String hexValue) {
    var hex = hexValue;
    if (hex.startsWith('0x') || hex.startsWith('0X')) {
      hex = hex.substring(2);
    }
    if (hex.length % 2 != 0) {
      throw ArgumentError('Invalid hex length: $hexValue');
    }
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  /// Convert bytes to a hex string.
  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Concatenate a list of byte arrays.
  static Uint8List _concat(List<Uint8List> parts) {
    final totalLength = parts.fold<int>(0, (sum, p) => sum + p.length);
    final result = Uint8List(totalLength);
    var offset = 0;
    for (final part in parts) {
      result.setRange(offset, offset + part.length, part);
      offset += part.length;
    }
    return result;
  }
}
