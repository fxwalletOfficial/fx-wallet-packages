import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

/// Function for convert a hex [String] to [BigInt].
BigInt hexToBn(
  dynamic value, {
  Endian endian = Endian.big,
  bool isNegative = false,
}) {
  if (value == null) {
    return BigInt.from(0);
  }
  if (isNegative == false) {
    final sValue = value is num
        ? int.parse(value.toString(), radix: 10).toRadixString(16)
        : value;
    if (endian == Endian.big) {
      return BigInt.parse(sValue, radix: 16);
    }
    return decodeBigInt(
      hexToBytes(sValue),
    );
  } else {
    String hex = value is num
        ? int.parse(value.toString(), radix: 10).toRadixString(16)
        : value;
    if (hex.length % 2 > 0) {
      hex = '0$hex';
    }
    hex = decodeBigInt(
      hexToBytes(hex),
      endian: endian,
    ).toRadixString(16);
    BigInt bn = BigInt.parse(hex, radix: 16);

    final result = 0x80 &
        int.parse(hex.substring(0, 2 > hex.length ? hex.length : 2), radix: 16);
    if (result > 0) {
      BigInt some = BigInt.parse(
        bn.toRadixString(2).split('').map((i) {
          return '0' == i ? 1 : 0;
        }).join(),
        radix: 2,
      );
      some += BigInt.one;
      bn = -some;
    }
    return bn;
  }
}

/// Function for decode [Uint8List] to [BigInt].
BigInt decodeBigInt(List<int> bytes, {Endian endian = Endian.little}) {
  BigInt result = BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    final newValue = BigInt.from(
      bytes[endian == Endian.little ? i : bytes.length - i - 1],
    );
    result += newValue << (8 * i);
  }
  return result;
}

/// Function for encode [BigInt] to [Uint8List].
Uint8List encodeBigInt(
  BigInt number, {
  Endian endian = Endian.little,
  int? bitLength,
}) {
  final bl = (bitLength != null) ? bitLength : number.bitLength;
  final int size = (bl + 7) >> 3;
  final result = Uint8List(size);

  for (int i = 0; i < size; i++) {
    result[endian == Endian.little ? i : size - i - 1] =
        (number & BigInt.from(0xff)).toInt();
    number = number >> 8;
  }
  return result;
}

/// Function for delete 0x prefix.
String strip0xHex(String hex) {
  if (hex.startsWith('0x')) {
    return hex.substring(2);
  }
  return hex;
}

/// Function for add 0x prefix.
String complete0xHex(String hex) {
  if (hex.startsWith('0x')) {
    return hex;
  }
  return '0x$hex';
}

/// Function for hex [String] to [List]
List<int> hexToBytes(String hexStr) {
  return hex.decode(strip0xHex(hexStr));
}

List<int> toBytesPadded(BigInt value, int length) {
  List<int> bytes = encodeBigInt(value, endian: Endian.big);
  if (bytes.length > length) {
    throw ('Input is too large to put in byte array of size ${length.toString()}');
  }
  var result = List<int>.filled(length, 0);
  var offset = length - bytes.length;
  for (var i = 0; i < length; i++) {
    result[i] = i < offset ? 0 : bytes[i - offset];
  }
  return result;
}

/// Function for get whole hex.
String toWholeHex(String hexString) {
  var hex = strip0xHex(hexString);
  var wholeHex = hex.length % 2 == 0 ? hex : '0$hex';
  return complete0xHex(wholeHex);
}

/// [String], [List], [Uint8List] to [Uint8List]
Uint8List dynamicToUint8List(dynamic value) {
  switch (value.runtimeType.toString()) {
    case 'List<int>':
      return Uint8List.fromList(value);
    case 'String':
      return Uint8List.fromList(hex.decode(strip0xHex(toWholeHex(value))));
    case 'Uint8List':
      return value;
    default:
      throw Exception('value must be String, List<int> or Uint8List');
  }
}

/// [String], List, [Uint8List] to [String]
String dynamicToString(dynamic value) {
  switch (value.runtimeType.toString()) {
    case 'List<int>':
      return hex.encode(dynamicToUint8List(value));
    case 'Uint8List':
      return hex.encode(value);
    case 'String':
      return strip0xHex(toWholeHex(value));
    default:
      throw Exception('value must be String, List<int> or Uint8List');
  }
}

/// [String], [List], [Uint8List] to 0x
String dynamicToHex(dynamic value) {
  switch (value.runtimeType.toString()) {
    case 'List<int>':
      return '0x${hex.encode(dynamicToUint8List(value))}';
    case 'Uint8List':
      return '0x${hex.encode(value)}';
    case 'String':
      return complete0xHex(value);
    default:
      throw Exception('value must be String, List<int> or Uint8List');
  }
}

/// Function for encode int.
Uint8List encodeInt(int number, int length) {
  final data = Uint8List(length);
  final buf = dynamicToUint8List(number.toRadixString(16));
  data.setAll(0, buf.reversed);
  return data;
}

/// Function for retrieve a random hexadecimal string.
String generateRandomString() {
  Random random = Random();
  const chars = '0123456789abcdef'; // Character set can be modified as needed
  String result = '';
  for (int i = 0; i < 32; i++) {
    result += chars[random.nextInt(chars.length)];
  }
  return result;
}

/// Converts a [Uint8List] to a [int].
int bufferToInt(Uint8List buf) {
  return decodeBigInt(buf.toUint8List()).toInt();
}

/// Is the string a hex string.
bool isHexString(String value, {int length = 0}) {
  ArgumentError.checkNotNull(value);

  if (!RegExp('^0x[0-9A-Fa-f]*\$').hasMatch(value)) return false;
  if (length > 0 && value.length != 2 + 2 * length) return false;

  return true;
}

/// Returns a buffer filled with 0s.
Uint8List zeros(int bytes) {
  var buffer = Uint8List(bytes);
  buffer.fillRange(0, bytes, 0);
  return buffer;
}

/// Right Pads an [Uint8List] with leading zeros till it has [length] bytes. Or it truncates the beginning if it exceeds.
Uint8List setLengthRight(Uint8List msg, int length) {
  return setLength(msg, length, right: true);
}

Uint8List setLength(Uint8List msg, int length, {bool right = false}) {
  return setLengthLeft(msg, length, right: right);
}

/// Left Pads an [Uint8List] with leading zeros till it has [length] bytes. Or it truncates the beginning if it exceeds.
Uint8List setLengthLeft(Uint8List msg, int length, {bool right = false}) {
  var buf = zeros(length);
  msg = dynamicToUint8List(msg);
  if (right) {
    if (msg.length < length) {
      buf.setAll(0, msg);
      return buf;
    }
    return msg.sublist(0, length);
  }

  if (msg.length < length) {
    buf.setAll(length - msg.length, msg);
    return buf;
  }
  return msg.sublist(msg.length - length);
}

bool isHexPrefixed(String str) {
  ArgumentError.checkNotNull(str);

  return str.startsWith('0x');
}

List<int> asciiStringToByteArray(String text) {
  return text.codeUnits; // Convert string to ASCII character byte array
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
