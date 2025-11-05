import 'dart:math';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/utils.dart';

import 'package:crypto_wallet_util/src/config/constants/dictionary.dart';

/// Function for convert a [Uint8List] to [BigInt].
BigInt u8aToBn(
  Uint8List u8a, {
  Endian endian = Endian.little,
  bool isNegative = false,
}) {
  return hexToBn(dynamicToHex(u8a), endian: endian, isNegative: isNegative);
}

var _byteMask = BigInt.from(0xff);
Uint8List bnToU8a(BigInt number) {
  // Not handling negative numbers. Decide how you want to do that.
  int size = (number.bitLength + 7) >> 3;
  var result = Uint8List(size);
  for (int i = 0; i < size; i++) {
    result[size - i - 1] = (number & _byteMask).toInt();
    number = number >> 8;
  }
  final List<int> list = List.from(result);
  return Uint8List.fromList(list.reversed.toList());
}

/// Function for convert a hex [String] to [BigInt].
BigInt hexToBigInt(String hex) {
  if (hex.length == 0) return BigInt.from(0);
  return BigInt.parse(strip0xHex(hex), radix: 16);
}

BigInt phraseToInt(String phrase) {
  BigInt result = BigInt.from(-1);
  List<String> words = phrase.split(" ");

  for (int i = 0; i < words.length; i++) {
    String word = words[i];
    int index = DICTIONARY.indexWhere(
        (w) => w.startsWith(word.substring(0, ENGLISH_UNIQUE_PREFIX_LEN)));
    if (index == -1) {
      return BigInt.from(-1); // return -1 if word not found in dictionary
    }

    BigInt exp = BigInt.from(DICTIONARY_SIZE).pow(i);
    BigInt increase = BigInt.from(index + 1) * exp;
    result += increase;
  }

  return result;
}

Uint8List intToBytes(BigInt i) {
  List<int> buf = [];

  while (i >= BigInt.from(256)) {
    buf.add((i % BigInt.from(256)).toInt());
    i -= BigInt.from(256);
    i = i ~/ BigInt.from(256);
  }

  buf.add((i % BigInt.from(256)).toInt());

  return Uint8List.fromList(buf);
}

/// Interprets a [Uint8List] as a signed integer and returns a [BigInt]. Assumes 256-bit numbers.
BigInt fromSigned(Uint8List signedInt) {
  final data = hexToBigInt(dynamicToString(signedInt));
  return data.toSigned(256);
}

/// Converts a [BigInt] to an unsigned integer and returns it as a [Uint8List]. Assumes 256-bit numbers.
Uint8List toUnsigned(BigInt unsignedInt) {
  return encodeBigInt(unsignedInt.toUnsigned(256), endian: Endian.big);
}

Uint8List encodeBigIntBe(BigInt input, {int length = 0}) {
  int byteLength = (input.bitLength + 7) >> 3;
  int reqLength = length > 0 ? length : max(1, byteLength);
  assert(byteLength <= reqLength, 'byte array longer than desired length');
  assert(reqLength > 0, 'Requested array length <= 0');

  var res = Uint8List(reqLength);
  res.fillRange(0, reqLength - byteLength, 0);

  var q = input;
  for (int i = 0; i < byteLength; i++) {
    res[reqLength - i - 1] = (q & _byteMask).toInt();
    q = q >> 8;
  }
  return res;
}
