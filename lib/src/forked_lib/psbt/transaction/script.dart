import 'dart:typed_data';

import '../utils/converter.dart';
import '../utils/varints.dart';

class BufferReader {
  final Uint8List buffer;
  int offset;

  BufferReader(this.buffer, [this.offset = 0]) {
    if (buffer.length < offset) {
      throw ArgumentError('Buffer length must be greater than offset');
    }
  }

  // 读取 8 位无符号整数
  int readUInt8() {
    int result = buffer[offset];
    offset += 1;
    return result;
  }

  // 读取 32 位有符号整数
  int readInt32() {
    int result = _readInt32LE(offset);
    offset += 4;
    return result;
  }

  // 读取 32 位无符号整数
  int readUInt32() {
    int result = _readUInt32LE(offset);
    offset += 4;
    return result;
  }

  // 读取 64 位无符号整数
  int readUInt64() {
    int result = _readUInt64LE(offset);
    offset += 8;
    return result;
  }

  // 读取变长整数
  int readVarInt() {
    int vi = _decodeVarInt();
    offset += _getVarIntBytes(vi);
    return vi;
  }

  // 读取指定长度的切片
  Uint8List readSlice(int n) {
    if (buffer.length < offset + n) {
      throw Exception('Cannot read slice out of bounds');
    }
    Uint8List result = buffer.sublist(offset, offset + n);
    offset += n;
    return result;
  }

  // 读取变长切片
  Uint8List readVarSlice() {
    return readSlice(readVarInt());
  }

  // 读取向量
  List<Uint8List> readVector() {
    int count = readVarInt();
    List<Uint8List> vector = [];
    for (int i = 0; i < count; i++) {
      vector.add(readVarSlice());
    }
    return vector;
  }

  // 读取 32 位有符号整数（小端）
  int _readInt32LE(int offset) {
    if (offset + 4 > buffer.length) {
      throw Exception('Buffer overflow');
    }
    return (buffer[offset] |
            (buffer[offset + 1] << 8) |
            (buffer[offset + 2] << 16) |
            (buffer[offset + 3] << 24));
  }

  // 读取 16 位无符号整数（小端）
  int _readUInt16LE(int offset) {
    if (offset + 2 > buffer.length) {
      throw Exception('Buffer overflow');
    }
    return (buffer[offset] | (buffer[offset + 1] << 8)) & 0xFFFF;
  }

  // 读取 32 位无符号整数（小端）
  int _readUInt32LE(int offset) {
    if (offset + 4 > buffer.length) {
      throw Exception('Buffer overflow');
    }
    return (buffer[offset] |
            (buffer[offset + 1] << 8) |
            (buffer[offset + 2] << 16) |
            (buffer[offset + 3] << 24)) & 0xFFFFFFFF;
  }

  // 读取 64 位无符号整数（小端）
  int _readUInt64LE(int offset) {
    if (offset + 8 > buffer.length) {
      throw Exception('Buffer overflow');
    }
    return (buffer[offset] |
            (buffer[offset + 1] << 8) |
            (buffer[offset + 2] << 16) |
            (buffer[offset + 3] << 24) |
            ((buffer[offset + 4] & 0xFFFFFFFF) << 32) |
            ((buffer[offset + 5] & 0xFFFFFFFF) << 40) |
            ((buffer[offset + 6] & 0xFFFFFFFF) << 48) |
            ((buffer[offset + 7] & 0xFFFFFFFF) << 56));
  }

  // 解码变长整数（示例实现）
  int _decodeVarInt() {
    if (offset >= buffer.length) {
      throw Exception('Buffer overflow');
    }
    int firstByte = buffer[offset];
    if (firstByte < 0xfd) {
      return firstByte;
    } else if (firstByte == 0xfd) {
      return _readUInt16LE(offset + 1);
    } else if (firstByte == 0xfe) {
      return _readUInt32LE(offset + 1); // 需要实现 64 位读取
    } else {
      return _readUInt64LE(offset + 1);
    }
  }

  // 获取变长整数的字节数（示例实现）
  int _getVarIntBytes(int value) {
    if (value < 0xfd) {
      return 1;
    } else if (value <= 0xffff) {
      return 3; // 1 byte for 0xfd + 2 bytes for uint16
    } else if (value <= 0xffffffff) {
      return 5; // 1 byte for 0xfe + 4 bytes for uint32
    } else {
      return 9; // 1 byte for 0xff + 8 bytes for uint64
    }
  }
}


/// Represents a script in a transaction.
class Script {
  final List<dynamic> _cmds;

  /// Script commands.
  List<dynamic> get commands => _cmds;

  /// The length of the script.
  int get length => () {
        int length = 0;
        Uint8List raw = _rawSerialize();
        length += raw.length;

        if (raw[0] == 0x00 && raw.length == 1) {
          return length;
        }
        length += Varints.encode(raw.length).length;
        return length;
      }();

  /// @nodoc
  Script(this._cmds);

  /// Parse the script from the given script bytes.
  static List<dynamic> parse(Uint8List script) {
    int offset = 0;
    int length = Varints.read(script, offset);
    offset += (length < 0xfd)
        ? 1
        : (length == 0xfd)
            ? 3
            : (length == 0xfe)
                ? 5
                : 9;
    List<dynamic> cmds = [];

    int count = 0;
    while (count < length) {
      int currentByte = script[offset];
      offset += 1;
      count += 1;
      if (currentByte >= 1 && currentByte <= 75) {
        int n = currentByte;
        cmds.add(script.sublist(offset, offset + n));
        offset += n;
        count += n;
      } else if (currentByte == 76) {
        int dataLength =
            Converter.littleEndianToInt(script.sublist(offset, offset + 1));
        offset += 1;
        cmds.add(script.sublist(offset, offset + dataLength));
        offset += dataLength;
        count += dataLength + 1;
      } else if (currentByte == 77) {
        int dataLength =
            Converter.littleEndianToInt(script.sublist(offset, offset + 2));
        offset += 2;
        cmds.add(script.sublist(offset, offset + dataLength));
        offset += dataLength;
        count += dataLength + 2;
      } else {
        int opCode = currentByte;
        cmds.add(opCode);
      }
    }
    if (count != length) {
      throw const FormatException('parsing script failed');
    }
    return cmds;
  }

  Uint8List _rawSerialize() {
    List<int> serialized = [];
    for (var cmd in commands) {
      if (cmd is int) {
        serialized.add(cmd);
      } else {
        Uint8List data = Uint8List.fromList(cmd);
        if (data.length < 76) {
          serialized.add(data.length);
        } else if (data.length < 0x100) {
          serialized.add(76);
          serialized.addAll(Converter.intToLittleEndianBytes(data.length, 1));
        } else if (data.length < 0x10000) {
          serialized.add(77);
          serialized.addAll(Converter.intToLittleEndianBytes(data.length, 2));
        }
        serialized.addAll(data);
      }
    }
    return Uint8List.fromList(serialized);
  }

  /// Serialize the script.
  String serialize() {
    if (commands.isEmpty) {
      return '';
    }
    Uint8List raw = _rawSerialize();
    if (raw[0] == 0x00 && raw.length == 1) {
      //segwit
      return Converter.bytesToHex(raw);
    }

    return Converter.bytesToHex(Varints.encode(raw.length)) +
        Converter.bytesToHex(raw);
  }
}
