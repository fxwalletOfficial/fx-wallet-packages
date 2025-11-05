import 'dart:typed_data';

import '../utils/constants/constants.dart';

class Blake2b {
  static Uint8List digest(Uint8List data, size, {key}) {
    final item = Blake2bItem();

    _init(size: size, item: item, key: key);
    _update(data: data, item: item);

    return _sort(item: item);
  }

  static void _init({required int size, required Blake2bItem item, Uint8List? key}) {
    final klen = key == null ? 0 : key.length;

    item.state.setRange(0, 16, iv.getRange(0, 16));

    item.globalSize = size;
    item.count = 0;
    item.pos = 0;

    item.state[0] ^= 0x01010000 ^ (klen << 8) ^ item.globalSize;

    if (klen > 0) {
      var block = Uint8List(128);
      block.setRange(0, key!.length, key);
      _update(data: block, item: item);
    }
  }

  static void _update({required Uint8List data, required Blake2bItem item}) {
    int off = 0;
    int len = data.length;

    if (len > 0) {
      var left = item.pos;
      var fill = 128 - left;

      if (len > fill) {
        item.pos = 0;
        item.globalBlock.setRange(left + off, left + off + fill, data.getRange(off, off + fill));

        item.count += 128;
        _compress(block: item.globalBlock, off: 0, last: false, item: item);

        off += fill;
        len -= fill;

        while (len > 128) {
          item.count += 128;
          _compress(block: data, off: off, last: false, item: item);
          off += 128;
          len -= 128;
        }
      }

      item.globalBlock.setRange(item.pos, item.pos + len, data.getRange(off, off + len));
      item.pos += len;
    }
  }

  static Uint8List _sort({required Blake2bItem item}) {
    item.count += item.pos;
    item.globalBlock.setRange(item.pos, 128, Uint8List(128 - item.pos));
    _compress(block: item.globalBlock, off: 0, last: true, item: item);
    item.pos = FINALIZED;

    final out = Uint8List(item.globalSize);

    for (var i = 0; i < item.globalSize; i++) {
      var temp = item.state[i >> 2];
      out[i] = temp >= 0 ? temp >> (8 * (i & 3)) : ~(~temp >> (8 * (i & 3)));
    }


    item.state.setRange(0, 16, Uint8List(16));
    item.V.setRange(0, 32, Uint8List(32));
    item.M.setRange(0, 32, Uint8List(32));

    item.globalBlock.setRange(0, 128, Uint8List(128));

    return out;
  }

  static void _compress({required Uint8List block, required int off, required bool last, required Blake2bItem item}) {
    item.V.setRange(0, 16, item.state);
    item.V.setRange(16, 32, iv);

    item.V[24] ^= item.count;
    item.V[25] ^= item.count * 1 ~/ 0x100000000;
    item.V[26] ^= 0;
    item.V[27] ^= 0;

    if (last) {
      item.V[28] ^= -1;
      item.V[29] ^= -1;

      // last node
      item.V[29] ^= 0;
      item.V[30] ^= 0;
    }

    for (var i = 0; i < 32; i++) {
      item.M[i] = _readU32(block, off);
      off += 4;
    }

    for (var i = 0; i < 12; i++) {
      _g(item.V, item.M, 0, 8, 16, 24, sigma[i * 16 + 0], sigma[i * 16 + 1]);
      _g(item.V, item.M, 2, 10, 18, 26, sigma[i * 16 + 2], sigma[i * 16 + 3]);
      _g(item.V, item.M, 4, 12, 20, 28, sigma[i * 16 + 4], sigma[i * 16 + 5]);
      _g(item.V, item.M, 6, 14, 22, 30, sigma[i * 16 + 6], sigma[i * 16 + 7]);
      _g(item.V, item.M, 0, 10, 20, 30, sigma[i * 16 + 8], sigma[i * 16 + 9]);
      _g(item.V, item.M, 2, 12, 22, 24, sigma[i * 16 + 10], sigma[i * 16 + 11]);
      _g(item.V, item.M, 4, 14, 16, 26, sigma[i * 16 + 12], sigma[i * 16 + 13]);
      _g(item.V, item.M, 6, 8, 18, 28, sigma[i * 16 + 14], sigma[i * 16 + 15]);
    }

    for (var i = 0; i < 16; i++) item.state[i] ^= item.V[i] ^ item.V[i + 16];
  }

  static int _readU32(Uint8List data, int off) {
    return (data[off++] + data[off++] * 0x100 + data[off++] * 0x10000 + data[off] * 0x1000000);
  }

  static _g(v, m, a, b, c, d, ix, iy) {
    var x0 = m[ix + 0];
    var x1 = m[ix + 1];
    var y0 = m[iy + 0];
    var y1 = m[iy + 1];

    _sum64i(v, a, b);
    _sum64w(v, a, x0, x1);

    var xor0 = v[d + 0] ^ v[a + 0];
    var xor1 = v[d + 1] ^ v[a + 1];

    v[d + 0] = xor1;
    v[d + 1] = xor0;

    _sum64i(v, c, d);

    var xor2 = v[b + 0] ^ v[c + 0];
    var xor3 = v[b + 1] ^ v[c + 1];

    v[b + 0] = (xor2 >= 0 ? xor2 >> (24) : ~(~xor2 >> (24))) ^ (xor3 << 8);
    v[b + 1] = (xor3 >= 0 ? xor3 >> (24) : ~(~xor3 >> (24))) ^ (xor2 << 8);

    _sum64i(v, a, b);
    _sum64w(v, a, y0, y1);

    var xor4 = v[d + 0] ^ v[a + 0];
    var xor5 = v[d + 1] ^ v[a + 1];

    v[d + 0] = (xor4 >= 0 ? xor4 >> (16) : ~(~xor4 >> (16))) ^ (xor5 << 16);
    v[d + 1] = (xor5 >= 0 ? xor5 >> (16) : ~(~xor5 >> (16))) ^ (xor4 << 16);

    _sum64i(v, c, d);

    var xor6 = v[b + 0] ^ v[c + 0];
    var xor7 = v[b + 1] ^ v[c + 1];

    v[b + 0] = (xor7 >= 0 ? xor7 >> (31) : ~(~xor7 >> (31))) ^ (xor6 << 1);
    v[b + 1] = (xor6 >= 0 ? xor6 >> (31) : ~(~xor6 >> (31))) ^ (xor7 << 1);
  }

  static _sum64i(v, a, b) {
    var o0 = v[a + 0] + v[b + 0];
    var o1 = v[a + 1] + v[b + 1];
    var c = o0 >= 0x100000000 ? 1 : 0;

    v[a + 0] = o0;
    v[a + 1] = o1 + c;
  }

  static _sum64w(v, a, b0, b1) {
    var o0 = v[a + 0] + b0;
    var o1 = v[a + 1] + b1;
    var c = o0 >= 0x100000000 ? 1 : 0;

    v[a + 0] = o0;
    v[a + 1] = o1 + c;
  }
}

class Blake2bItem {
  Uint32List state = Uint32List(16);
  int globalSize = 32;
  int count = 0;
  int pos = 0x80000000;
  var globalBlock = Uint8List(128);
  Uint32List V = Uint32List(32);
  Uint32List M = Uint32List(32);
}
