import 'package:base32/base32.dart';
import 'package:base32/encodings.dart';
import 'package:crypto_wallet_util/utils.dart';

/// Enum of base32 encoding type.
enum Base32Type { BASE32, RFC4648 }

/// Class for encode and decode base32.
class Base32 {
  static final String CHARSET = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  static final String RFC4648 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static String encode(List<int> data,
      {Base32Type type = Base32Type.BASE32, bool padding = false}) {
    switch (type) {
      case Base32Type.BASE32:
        String base32Hex = '';
        for (int i = 0; i < data.length; ++i) {
          int value = data[i];
          if (!(0 <= value && value < 32)) {
            throw Exception('Invalid value: $value.');
          }
          base32Hex += CHARSET[value];
        }
        return base32Hex;
      case Base32Type.RFC4648:
        String base32Hex = base32.encode(data.toUint8List(),
            encoding: Encoding.nonStandardRFC4648Lower);
        if (base32Hex[base32Hex.length - 1] == '=')
          base32Hex = base32Hex.substring(0, base32Hex.length - 1);
        return base32Hex;
    }
  }

  static List<int> decode(String base32Hex,
      {Base32Type type = Base32Type.BASE32}) {
    switch (type) {
      case Base32Type.BASE32:
        List<int> data = [];
        for (int i = 0; i < base32Hex.length; ++i) {
          int value = CHARSET.indexOf(base32Hex[i]);
          if (value == -1) {
            throw Exception('Invalid character: ${base32Hex[i]}.');
          }
          data.add(value);
        }
        return data;
      case Base32Type.RFC4648:
        final base32data = base32.decode(base32Hex,
            encoding: Encoding.nonStandardRFC4648Lower);
        return base32data;
    }
  }
}
