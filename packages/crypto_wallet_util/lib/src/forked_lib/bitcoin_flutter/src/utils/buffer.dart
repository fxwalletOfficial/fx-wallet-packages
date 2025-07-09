import 'dart:typed_data';

import 'package:hex/hex.dart';

import '../crypto.dart';
import '../utils/varuint.dart' as varuint;

class Buffer {
  Uint8List tBuffer = Uint8List.fromList([]);
  int tOffset = 0;
  /// Any changes made to the ByteData will also change the buffer, and vice versa. https://api.dart.dev/stable/2.7.1/dart-typed_data/ByteBuffer/asByteData.html
  ByteData bytes = ByteData(0);

  Buffer(int length) {
    tBuffer = Uint8List(length);
    tOffset = 0;
    bytes = tBuffer.buffer.asByteData();
  }

  factory Buffer.fromUint8List({int length = 0, Uint8List? data, int? initialOffset}) {
    final item = Buffer(length);
    if (initialOffset != null) item.tOffset = initialOffset;

    if (data == null) return item;

    item.tBuffer = data;
    item.bytes = item.tBuffer.buffer.asByteData();
    return item;
  }

  void writeSlice(List<int>? slice) {
    if (slice == null) return;

    tBuffer.setRange(tOffset, tOffset + slice.length, slice);
    tOffset += slice.length;
  }

  void writeUInt8(int i) {
    bytes.setUint8(tOffset, i);
    tOffset++;
  }

  void writeUInt32(int? i) {
    if (i == null) return;

    bytes.setUint32(tOffset, i, Endian.little);
    tOffset += 4;
  }

  void writeInt32(int? i) {
    if (i == null) return;

    bytes.setInt32(tOffset, i, Endian.little);
    tOffset += 4;
  }

  void writeUInt64(int? i) {
    if (i == null) return;

    bytes.setUint64(tOffset, i, Endian.little);
    tOffset += 8;
  }

  void writeVarInt(i) {
    varuint.encode(i, tBuffer, tOffset);
    tOffset += varuint.encodingLength(i);
  }

  void writeVarSlice(Uint8List? slice) {
    if (slice == null) return;

    writeVarInt(slice.length);
    writeSlice(slice);
  }

  void writeVector(List<Uint8List?>? vector) {
    if (vector == null) return;

    writeVarInt(vector.length);
    vector.forEach((buf) => writeVarSlice(buf));
  }

  Uint8List toHash256() => hash256(tBuffer);

  Uint8List toSha256() => sha256(tBuffer);

  @override
  String toString() => HEX.encode(tBuffer);
}