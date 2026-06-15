import 'dart:typed_data';

/// Bitcoin / Solana base58 alphabet (no 0, O, I, l).
const String _alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

/// Encode [bytes] to a base58 string. Hand-rolled (rather than a `bs58`
/// dependency) per the demo's "roll the Solana bits yourself" choice.
String base58Encode(Uint8List bytes) {
  if (bytes.isEmpty) return '';

  var zeros = 0;
  while (zeros < bytes.length && bytes[zeros] == 0) {
    zeros++;
  }

  // Work on a mutable big-endian base-256 copy, repeatedly dividing by 58.
  final input = Uint8List.fromList(bytes);
  final encoded = <int>[];
  var start = zeros;
  while (start < input.length) {
    var remainder = 0;
    for (var i = start; i < input.length; i++) {
      final acc = (remainder << 8) + input[i];
      input[i] = acc ~/ 58;
      remainder = acc % 58;
    }
    encoded.add(remainder);
    while (start < input.length && input[start] == 0) {
      start++;
    }
  }

  final sb = StringBuffer();
  for (var i = 0; i < zeros; i++) {
    sb.write('1');
  }
  for (var i = encoded.length - 1; i >= 0; i--) {
    sb.write(_alphabet[encoded[i]]);
  }
  return sb.toString();
}

/// Decode a base58 [input] string to bytes. Throws [FormatException] on an
/// out-of-alphabet character.
Uint8List base58Decode(String input) {
  if (input.isEmpty) return Uint8List(0);

  final digits = List<int>.filled(input.length, 0);
  for (var i = 0; i < input.length; i++) {
    final idx = _alphabet.indexOf(input[i]);
    if (idx < 0) {
      throw FormatException('Invalid base58 character: ${input[i]}');
    }
    digits[i] = idx;
  }

  var zeros = 0;
  while (zeros < input.length && input[zeros] == '1') {
    zeros++;
  }

  final decoded = <int>[];
  var start = zeros;
  while (start < digits.length) {
    var remainder = 0;
    for (var i = start; i < digits.length; i++) {
      final acc = remainder * 58 + digits[i];
      digits[i] = acc ~/ 256;
      remainder = acc % 256;
    }
    decoded.add(remainder);
    while (start < digits.length && digits[start] == 0) {
      start++;
    }
  }

  final result = <int>[];
  for (var i = 0; i < zeros; i++) {
    result.add(0);
  }
  for (var i = decoded.length - 1; i >= 0; i--) {
    result.add(decoded[i]);
  }
  return Uint8List.fromList(result);
}

/// Decode a hex string (with or without a `0x` prefix) to bytes.
Uint8List hexDecode(String input) {
  var hex = input.startsWith('0x') || input.startsWith('0X')
      ? input.substring(2)
      : input;
  if (hex.length.isOdd) hex = '0$hex';
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

/// Encode bytes to a lower-case hex string (no `0x` prefix).
String hexEncode(Uint8List bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}
