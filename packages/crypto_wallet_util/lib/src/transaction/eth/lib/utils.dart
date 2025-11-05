import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:convert/convert.dart';
import 'package:pointycastle/pointycastle.dart';

/// Converts an [int] or [BigInt] to a [Uint8List]
Uint8List intToBuffer(i) {
  return Uint8List.fromList(i == null || i == 0 || i == BigInt.zero
      ? []
      : dynamicToUint8List(padToEven(intToHex(i).substring(2))));
}

/// Pads a [String] to have an even length
String padToEven(String value) {
  ArgumentError.checkNotNull(value);

  var a = value;
  if (a.length % 2 == 1) a = '0$a';

  return a;
}

/// Converts a [int] into a hex [String]
String intToHex(i) {
  ArgumentError.checkNotNull(i);

  return '0x${i.toRadixString(16)}';
}

String stripHexPrefix(String str) {
  ArgumentError.checkNotNull(str);

  return isHexPrefixed(str) ? str.substring(2) : str;
}

/// Converts a [Uint8List] into a hex [String].
String bufferToHex(Uint8List buf) {
  return '0x${hex.encode(buf)}';
}

Uint8List toBuffer(v) {
  if (v is! Uint8List) {
    if (v is List<int>) {
      v = Uint8List.fromList(v);
    } else if (v is String) {
      if (isHexString(v)) {
        v = Uint8List.fromList(hex.decode(padToEven(stripHexPrefix(v))));
      } else {
        v = Uint8List.fromList(utf8.encode(v));
      }
    } else if (v is int) {
      v = intToBuffer(v);
    } else if (v == null) {
      v = Uint8List(0);
    } else if (v is BigInt) {
      v = Uint8List.fromList(encodeBigInt(v));
    } else {
      throw 'invalid type';
    }
  }

  return v;
}

/// Creates Keccak hash of the input
Uint8List keccak(dynamic a, {int bits = 256}) {
  a = toBuffer(a);
  Digest sha3 = Digest('Keccak/$bits');
  return sha3.process(a);
}
