import 'package:crypto_wallet_util/src/utils/utils.dart';

/// An instance of the default implementation of the Bech32Codec.
const Bech32Codec bech32 = Bech32Codec();

/// Class for decode and encode bech32.
class Bech32Codec extends Codec<Bech32, String> {
  const Bech32Codec();

  @override
  Bech32Decoder get decoder => Bech32Decoder();
  @override
  Bech32Encoder get encoder => Bech32Encoder();

  @override
  String encode(Bech32 input,
      {maxLength = Bech32Validations.maxInputLength,
      String encoding = 'bech32'}) {
    return Bech32Encoder()
        .convert(input, maxLength: maxLength, encoding: encoding);
  }

  @override
  Bech32 decode(String encoded,
      {maxLength = Bech32Validations.maxInputLength,
      String encoding = 'bech32'}) {
    return Bech32Decoder()
        .convert(encoded, maxLength: maxLength, encoding: encoding);
  }
}

// This class converts a Bech32 class instance to a String.
class Bech32Encoder extends Converter<Bech32, String> with Bech32Validations {
  @override
  String convert(Bech32 input,
      {int maxLength = Bech32Validations.maxInputLength,
      String encoding = 'bech32'}) {
    var hrp = input.hrp;
    var data = input.data;

    hrp = hrp.toLowerCase();
    final checkSummed = data + createChecksum(hrp, data, encoding: encoding);

    if (hasOutOfBoundsChars(checkSummed)) throw Exception();

    return hrp + separator + checkSummed.map((i) => charset[i]).join();
  }

  static String encode(String humanReadablePart, Uint8List data) {
    final List<int> converted = convertBits(data, 8, 5);
    final bech32Codec = Bech32Codec();
    final bech32Data = Bech32(humanReadablePart, Uint8List.fromList(converted));
    return bech32Codec.encode(bech32Data);
  }
}

/// This class converts a String to a Bech32 class instance.
class Bech32Decoder extends Converter<String, Bech32> with Bech32Validations {
  @override
  Bech32 convert(String input,
      {int maxLength = Bech32Validations.maxInputLength,
      String encoding = 'bech32'}) {
    var separatorPosition = input.lastIndexOf(separator);
    input = input.toLowerCase();
    var hrp = input.substring(0, separatorPosition);
    var data = input.substring(
        separatorPosition + 1, input.length - Bech32Validations.checksumLength);
    var dataBytes = data.split('').map((c) => charset.indexOf(c)).toList();
    return Bech32(hrp, dataBytes);
  }
}

/// Generic validations for Bech32 standard.
class Bech32Validations {
  static const int maxInputLength = 90;
  static const checksumLength = 6;

  // From the entire input subtract the hrp length, the separator and the required checksum length
  bool isChecksumTooShort(int separatorPosition, String input) {
    return (input.length - separatorPosition - 1 - checksumLength) < 0;
  }

  bool hasOutOfBoundsChars(List<int> data) {
    return data.any((c) => c == -1);
  }

  bool isHrpTooShort(int separatorPosition) {
    return separatorPosition == 0;
  }

  bool isInvalidChecksum(String hrp, List<int> data, List<int> checksum,
      {String encoding = 'bech32'}) {
    return !verifyChecksum(hrp, data + checksum, encoding: encoding);
  }

  bool isMixedCase(String input) {
    return input.toLowerCase() != input && input.toUpperCase() != input;
  }

  bool hasInvalidSeparator(String bech32) {
    return bech32.lastIndexOf(separator) == -1;
  }

  bool hasOutOfRangeHrpCharacters(String hrp) {
    return hrp.codeUnits.any((c) => c < 33 || c > 126);
  }
}

/// Bech32 is a dead simple wrapper around a Human Readable Part (HRP) and a
/// bunch of bytes.
class Bech32 {
  Bech32(this.hrp, this.data);

  final String hrp;
  final List<int> data;
}

const String separator = '1';

const List<String> charset = [
  'q',
  'p',
  'z',
  'r',
  'y',
  '9',
  'x',
  '8',
  'g',
  'f',
  '2',
  't',
  'v',
  'd',
  'w',
  '0',
  's',
  '3',
  'j',
  'n',
  '5',
  '4',
  'k',
  'h',
  'c',
  'e',
  '6',
  'm',
  'u',
  'a',
  '7',
  'l'
];

const List<int> generator = [
  0x3b6a57b2,
  0x26508e6d,
  0x1ea119fa,
  0x3d4233dd,
  0x2a1462b3
];

int _polymod(List<int> values) {
  var chk = 1;
  for (var v in values) {
    var top = chk >> 25;
    chk = (chk & 0x1ffffff) << 5 ^ v;
    for (var i = 0; i < generator.length; i++) {
      if ((top >> i) & 1 == 1) chk ^= generator[i];
    }
  }

  return chk;
}

List<int> _hrpExpand(String hrp) {
  var result = hrp.codeUnits.map((c) => c >> 5).toList();
  result = result + [0];

  result = result + hrp.codeUnits.map((c) => c & 31).toList();

  return result;
}

bool verifyChecksum(String hrp, List<int> dataIncludingChecksum,
    {String encoding = 'bech32'}) {
  return _polymod(_hrpExpand(hrp) + dataIncludingChecksum) ==
      (encoding == 'bech32' ? 1 : 0x2bc830a3);
}

List<int> createChecksum(String hrp, List<int> data,
    {String encoding = 'bech32'}) {
  final ENCODING_CONST = encoding == 'bech32' ? 1 : 0x2bc830a3;
  var values = _hrpExpand(hrp) + data + [0, 0, 0, 0, 0, 0];
  var polymod = _polymod(values) ^ ENCODING_CONST;

  var result = <int>[0, 0, 0, 0, 0, 0];

  for (var i = 0; i < result.length; i++) {
    result[i] = (polymod >> (5 * (5 - i))) & 31;
  }
  return result;
}

List<int> toUint5Array(data) {
  return convertBits(data, 8, 5);
}

List<int> convertBits(data, int from, int to, {bool strictMode = false}) {
  double len = data.length * from / to;
  final length = strictMode ? len.floor() : len.ceil();

  final mask = (1 << to) - 1;
  final result = List.generate(length, (_) => 0);

  var index = 0;
  var accumulator = 0;
  var bits = 0;

  for (var i = 0; i < data.length; i++) {
    var value = data[i];
    accumulator = (accumulator << from) | value;
    bits += from;
    while (bits >= to) {
      bits -= to;
      result[index] = (accumulator >> bits) & mask;
      index++;
    }
  }

  if (!strictMode) {
    if (bits > 0) {
      result[index] = (accumulator << (to - bits)) & mask;
      index++;
    }
  } else {}

  return result;
}

Uint8List convertBit(Uint8List buff) {
  String str = '';
  for (var i = 0; i < buff.length; i++) {
    String res = buff[i].toRadixString(2);
    res = res.length < 8
        ? '00000000'.substring(0, 8 - res.length) + res
        : buff[i].toRadixString(2);

    str = str + res;
  }
  int len = (str.length / 5).ceil();
  List<int> arr = [];
  for (var i = 0; i < len; i++) {
    var info = str.substring(0, 5);
    str = str.substring(5);
    arr.add(int.parse(info, radix: 2));
  }
  arr.insert(0, 0);
  return dynamicToUint8List(arr);
}
