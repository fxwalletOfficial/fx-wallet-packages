import 'dart:math';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart' as crypto;

Uint8List intToByte(int value, int length) {
  final data = Uint8List(length);

  String str = value.toRadixString(16);
  if (str.length % 2 == 1) str = '0$str';

  final buf = hex.decode(str);
  data.setAll(length - buf.length, buf);

  return data;
}

BigInt byteToBigInt(Uint8List value) {
  BigInt result = BigInt.from(0);
  for (int i = 0; i < value.length; i++) {
    result += BigInt.from(value[value.length - i - 1]) << (8 * i);
  }
  return result;
}

Uint8List bigIntToByte(BigInt value, int? length) {
  String str = value.toRadixString(16);
  if (str.length % 2 == 1) str = '0$str';

  final len = length ?? (str.length / 2).round();
  final data = Uint8List(len);
  final buf = hex.decode(str);
  data.setAll(len - buf.length, buf);

  return data;
}

Uint8List stringToBytes(String value) {
  final item = value.replaceFirst('0x', '');
  return Uint8List.fromList(hex.decode(item));
}

Uint8List sha256(List<int> value) {
  final digest = crypto.sha256.convert(value);
  return Uint8List.fromList(digest.bytes);
}

Uint8List fromHex(String data) {
  if (data.startsWith("0x")) {
    data = data.substring(2);
  }

  final result = Uint8List(data.length ~/ 2);

  for (int i = 0; i < data.length; i += 2) {
    result[i ~/ 2] = int.parse(data.substring(i, i + 2), radix: 16);
  }

  return result;
}

Uint8List toUtf8Bytes(String str) {
  List<int> utf8 = [];

  for (int i = 0; i < str.length; i++) {
    int data = str.codeUnitAt(i);

    if (data < 0x80) {
      utf8.add(data);
    } else if (data < 0x800) {
      utf8.add(0xc0 | (data >> 6));
      utf8.add(0x80 | (data & 0x3f));
    } else if (data < 0xd800 || data >= 0xe000) {
      utf8.add(0xe0 | (data >> 12));
      utf8.add(0x80 | ((data >> 6) & 0x3f));
      utf8.add(0x80 | (data & 0x3f));
    } else {
      // Surrogate pair
      i++;
      if (i >= str.length) {
        throw Exception("Invalid UTF-16 string");
      }
      int nextCharCode = str.codeUnitAt(i);
      data = 0x10000 + (((data & 0x3ff) << 10) | (nextCharCode & 0x3ff));
      utf8.add(0xf0 | (data >> 18));
      utf8.add(0x80 | ((data >> 12) & 0x3f));
      utf8.add(0x80 | ((data >> 6) & 0x3f));
      utf8.add(0x80 | (data & 0x3f));
    }
  }

  return Uint8List.fromList(utf8);
}

bool arraysEqual(List a, List b) {
  if (a.length != b.length) return false;
  return a.every((e) => b.contains(e));
}

List<int> bufferXOR(List<int> a, List<int> b) {
  final length = max(a.length, b.length);
  final result = List.filled(length, 0);

  for (var i = 0; i < length; i++) {
    result[i] = a[i] ^ b[i];
  }
  return result;
}

final _pathReg = RegExp(r"/(\d+)('{0,1})");

List<CborValue> getPath(String path) {
  if (!path.startsWith('m/')) throw Exception('Invalid type');

  final items = <CborValue>[];
  final matches = _pathReg.allMatches(path);
  for (final match in matches) {
    final num = int.parse(match.group(1)!);
    final hardened = match.group(2)?.isNotEmpty ?? false;
    items.addAll([CborSmallInt(num), CborBool(hardened)]);
  }

  return items;
}

/// Xfp code to hex. [bigEndian] decide whether use big endian type.
String getXfp(BigInt xfpCode, {bool bigEndian = true}) {
  String code = xfpCode.toRadixString(16);
  if (code.length < 8) {
    final len = code.length;
    for (int i = 0; i < 8 - len; i++) {
      code = '0$code';
    }
  }

  final bytes = Uint8List.fromList(hex.decode(code));
  final reverse = bigEndian ? bytes.reversed.toList() : bytes;
  return hex.encode(Uint8List.fromList(reverse));
}

/// Hex xfp to bigInt xfp. [bigEndian] decide whether use big endian type.
BigInt toXfpCode(String xfp, {bool bigEndian = true}) {
  final reverse = bigEndian ? Uint8List.fromList(hex.decode(xfp)).reversed.toList() : Uint8List.fromList(hex.decode(xfp)).toList();
  return BigInt.parse(hex.encode(reverse), radix: 16);
}

/// Convert a CborList to a BIP32 path string
String cborPathToString(CborList? pathList) {
  if (pathList == null) return '';
  String path = 'm';
  for (int i = 0; i < pathList.length; i += 2) {
    final index = pathList[i] as CborSmallInt;
    final hardened = (i + 1 < pathList.length) && (pathList[i + 1] is CborBool) && (pathList[i + 1] as CborBool).value;
    path += '/${index.value}${hardened ? "'" : ""}';
  }
  return path;
}
