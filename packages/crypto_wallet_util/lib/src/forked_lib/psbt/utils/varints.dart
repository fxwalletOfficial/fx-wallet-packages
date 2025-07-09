import 'dart:typed_data';
import 'converter.dart';

class Varints {
  static int read(Uint8List s, int offset) {
    final firstByte = s[offset];
    if (firstByte < 0xfd) {
      return firstByte;
    } else if (firstByte == 0xfd) {
      return ByteData.sublistView(s, offset + 1, offset + 3)
          .getUint16(0, Endian.little);
    } else if (firstByte == 0xfe) {
      return ByteData.sublistView(s, offset + 1, offset + 5)
          .getUint32(0, Endian.little);
    } else {
      return ByteData.sublistView(s, offset + 1, offset + 9)
          .getUint64(0, Endian.little);
    }
  }

  static Uint8List encode(int i) {
    if (i < 0xfd) {
      return Uint8List.fromList([i.toInt()]);
    } else if (i < 0x10000) {
      return Uint8List.fromList(
          [0xfd] + Converter.intToLittleEndianBytes(i.toInt(), 2));
    } else if (i < 0x100000000) {
      return Uint8List.fromList(
          [0xfe] + Converter.intToLittleEndianBytes(i.toInt(), 4));
    } else {
      throw ArgumentError('integer too large: $i');
    }
  }
}
