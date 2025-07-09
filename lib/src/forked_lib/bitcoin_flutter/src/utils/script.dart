import 'dart:convert';
import 'dart:typed_data';

import 'package:bip32/src/utils/ecurve.dart' as ecc;
import 'package:hex/hex.dart';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

import '../bech32/bech32.dart';
import '../transaction.dart';
import '../utils/constants/op.dart';
import '../utils/push_data.dart' as pushdata;
import '../utils/check_types.dart';

final secp256k1 = ECCurve_secp256k1();
final secp256k1P = BigInt.parse('fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f', radix: 16);

Map<int, String> REVERSE_OPS = OPS.map((String string, int number) => MapEntry(number, string));
final OP_INT_BASE = OPS['OP_RESERVED'];
final ZERO = Uint8List.fromList([0]);

bool isOPInt(dynamic value) {
  return (value is num && (value == OPS['OP_0'] || (value >= OPS['OP_1']! && value <= OPS['OP_16']!) || value == OPS['OP_1NEGATE']));
}

bool isPushOnlyChunk(dynamic value) {
  return (value is Uint8List) || isOPInt(value);
}

bool isPushOnly(dynamic value) {
  return (value is List) && value.every(isPushOnlyChunk);
}

Uint8List? compile(List<dynamic> chunks) {
  final bufferSize = chunks.fold(0, (dynamic acc, chunk) {
    if (chunk is int) return acc + 1;
    if (chunk.length == 1 && asMinimalOP(chunk) != null) {
      return acc + 1;
    }
    return acc + pushdata.encodingLength(chunk.length) + chunk.length;
  });
  Uint8List? buffer = Uint8List(bufferSize);

  var offset = 0;
  chunks.forEach((chunk) {
    // data chunk
    if (chunk is Uint8List) {
      // adhere to BIP62.3, minimal push policy
      final opcode = asMinimalOP(chunk);
      if (opcode != null) {
        buffer!.buffer.asByteData().setUint8(offset, opcode);
        offset += 1;
        return null;
      }
      var epd = pushdata.encode(buffer, chunk.length, offset);
      offset += epd.size!;
      buffer = epd.buffer;
      buffer!.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
      // opcode
    } else {
      buffer!.buffer.asByteData().setUint8(offset, chunk);
      offset += 1;
    }
  });

  if (offset != buffer!.length) throw ArgumentError('Could not decode chunks');
  return buffer;
}

List<dynamic>? decompile(dynamic buffer) {
  var chunks = <dynamic>[];

  if (buffer == null) return chunks;
  if (buffer is List<Uint8List?>) return buffer;

  var i = 0;
  while (i < buffer.length) {
    final opcode = buffer[i];

    // data chunk
    if ((opcode > OPS['OP_0']) && (opcode <= OPS['OP_PUSHDATA4'])) {
      final d = pushdata.decode(buffer, i);

      // did reading a pushDataInt fail?
      if (d == null) return null;
      i += d.size!;

      // attempt to read too much data?
      if (i + d.number! > buffer.length) return null;

      final data = buffer.sublist(i, i + d.number!);
      i += d.number!;

      // decompile minimally
      final op = asMinimalOP(data);
      chunks.add(op != null ? op : data);

      // opcode
    } else {
      chunks.add(opcode);
      i += 1;
    }
  }
  return chunks;
}

Uint8List? fromASM(String? asm) {
  if (asm == '') return Uint8List.fromList([]);
  return compile(asm!.split(' ').map((chunkStr) {
    if (OPS[chunkStr] != null) return OPS[chunkStr];
    return HEX.decode(chunkStr);
  }).toList());
}

String toASM(List<dynamic>? c) {
  List<dynamic>? chunks;
  if (c is Uint8List) {
    chunks = decompile(c);
  } else {
    chunks = c;
  }
  return chunks!.map((chunk) {
    // data?
    if (chunk is Uint8List) {
      final op = asMinimalOP(chunk);
      if (op == null) return HEX.encode(chunk);
      chunk = op;
    }
    // opcode!
    return REVERSE_OPS[chunk];
  }).join(' ');
}

int? asMinimalOP(Uint8List buffer) {
  if (buffer.isEmpty) return OPS['OP_0'];
  if (buffer.length != 1) return null;
  if (buffer[0] >= 1 && buffer[0] <= 16) return OP_INT_BASE! + buffer[0];
  if (buffer[0] == 0x81) return OPS['OP_1NEGATE'];
  return null;
}

bool isDefinedHashType(hashType) {
  final hashTypeMod = hashType & ~0x80;
  // return hashTypeMod > SIGHASH_ALL && hashTypeMod < SIGHASH_SINGLE
  return hashTypeMod > 0x00 && hashTypeMod < 0x04;
}

bool isCanonicalPubKey(Uint8List buffer) {
  return ecc.isPoint(buffer);
}

bool isCanonicalScriptSignature(Uint8List buffer) {
  if (!isDefinedHashType(buffer[buffer.length - 1])) return false;
  return bip66check(buffer.sublist(0, buffer.length - 1));
}

bool bip66check(buffer) {
  if (buffer.length < 8) return false;
  if (buffer.length > 72) return false;
  if (buffer[0] != 0x30) return false;
  if (buffer[1] != buffer.length - 2) return false;
  if (buffer[2] != 0x02) return false;

  var lenR = buffer[3];
  if (lenR == 0) return false;
  if (5 + lenR >= buffer.length) return false;
  if (buffer[4 + lenR] != 0x02) return false;

  var lenS = buffer[5 + lenR];
  if (lenS == 0) return false;
  if ((6 + lenR + lenS) != buffer.length) return false;

  if (buffer[4] & 0x80 != 0) return false;
  if (lenR > 1 && (buffer[4] == 0x00) && buffer[5] & 0x80 == 0) return false;

  if (buffer[lenR + 6] & 0x80 != 0) return false;
  if (lenS > 1 && (buffer[lenR + 6] == 0x00) && buffer[lenR + 7] & 0x80 == 0) {
    return false;
  }
  return true;
}

Uint8List bip66encode(r, s) {
  var lenR = r.length;
  var lenS = s.length;
  if (lenR == 0) throw ArgumentError('R length is zero');
  if (lenS == 0) throw ArgumentError('S length is zero');
  if (lenR > 33) throw ArgumentError('R length is too long');
  if (lenS > 33) throw ArgumentError('S length is too long');
  if (r[0] & 0x80 != 0) throw ArgumentError('R value is negative');
  if (s[0] & 0x80 != 0) throw ArgumentError('S value is negative');
  if (lenR > 1 && (r[0] == 0x00) && r[1] & 0x80 == 0) throw ArgumentError('R value excessively padded');
  if (lenS > 1 && (s[0] == 0x00) && s[1] & 0x80 == 0) throw ArgumentError('S value excessively padded');

  var signature = Uint8List(6 + lenR + lenS as int);

  // 0x30 [total-length] 0x02 [R-length] [R] 0x02 [S-length] [S]
  signature[0] = 0x30;
  signature[1] = signature.length - 2;
  signature[2] = 0x02;
  signature[3] = r.length;
  signature.setRange(4, 4 + lenR as int, r);
  signature[4 + lenR as int] = 0x02;
  signature[5 + lenR as int] = s.length;
  signature.setRange(6 + lenR as int, 6 + lenR + lenS as int, s);
  return signature;
}

Uint8List encodeSignature(Uint8List signature, int hashType) {
  if (!isUint(hashType, 8)) throw ArgumentError('Invalid hasType $hashType');
  if (signature.length != 64) throw ArgumentError('Invalid signature');

  final hashTypeMod = hashType & ~((hashType & SIGHASH_BITCOINCASHBIP143) > 0 ? 0xc0 : 0x80);
  if (hashTypeMod <= 0 || hashTypeMod >= 4) throw ArgumentError('Invalid hashType $hashType');

  final hashTypeBuffer = Uint8List(1);
  hashTypeBuffer.buffer.asByteData().setUint8(0, hashType);
  final r = toDER(signature.sublist(0, 32));
  final s = toDER(signature.sublist(32, 64));
  final combine = List<int>.from(bip66encode(r, s));
  combine.addAll(List.from(hashTypeBuffer));
  return Uint8List.fromList(combine);
}

Uint8List toDER(Uint8List x) {
  var i = 0;
  while (x[i] == 0) {
    ++i;
  }
  if (i == x.length) return ZERO;
  x = x.sublist(i);
  var combine = List<int>.from(ZERO);
  combine.addAll(x);
  if (x[0] & 0x80 != 0) return Uint8List.fromList(combine);
  return x;
}

prefixToUint5Array(String prefix) {
  final result = [];
  for (var i = 0; i < prefix.length; i++) {
    result.add(prefix[i].codeUnitAt(0) & 31);
  }

  return result;
}

getTypeBits(String type) {
  switch (type) {
    case 'P2PKH':
      return 0;
    case 'P2SH':
      return 8;
    default:
      throw new Error();
  }
}

getHashSizeBits(hash) {
  switch (hash.length * 8) {
    case 160:
      return 0;
    case 192:
      return 1;
    case 224:
      return 2;
    case 256:
      return 3;
    case 320:
      return 4;
    case 384:
      return 5;
    case 448:
      return 6;
    case 512:
      return 7;
    default:
      throw new Error();
  }
}

toUint5Array(data) {
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
  } else {

  }

  return result;
}

base32Encode(data) {
  var base32 = '';
  for (var i = 0; i < data.length; i++) {
    var value = data[i];
    base32 += charset[value];
  }

  return base32;
}

List base32Decode(String data) {
  List hash = [];
  for (var i = 0; i < data.length; i++) {
    hash.add(charset.indexOf(data[i]));
  }

  return hash;
}

polymod(data) {
  var GENERATOR = [0x98f2bc8e61, 0x79b76d99e2, 0xf33e5fb3c4, 0xae2eabe2a8, 0x1e4f43e470];
  var checksum = BigInt.from(1);
  for (var i = 0; i < data.length; i++) {
    var value = data[i];
    var topBits = checksum >> 35;
    checksum = ((checksum & BigInt.from(0x07ffffffff)) << 5) ^ BigInt.from(value);
    for (var j = 0; j < GENERATOR.length; j++) {
      if (((topBits >> j) & BigInt.from(1)).compareTo(BigInt.from(1)) == 0) {
        checksum = checksum ^ BigInt.from(GENERATOR[j]);
      }
    }
  }

  return checksum ^ BigInt.from(1);
}

checksumToUint5Array(checksum) {
  var result = List.generate(8, (_) => 0);
  for (var i = 0; i < 8; ++i) {
    result[7 - i] = (checksum & BigInt.from(31)).toInt();
    checksum = checksum >> 5;
  }
  return result;
}

List<int> taggedHash(String tag, List<int> msg) {
  var tagHash = sha256.convert(utf8.encode(tag)).bytes;
  return sha256.convert(tagHash + tagHash + msg).bytes;
}

List<int> bigToBytes(BigInt integer) {
  var hexNum = integer.toRadixString(16);
  if (hexNum.length % 2 == 1) hexNum = '0' + hexNum;

  return HEX.decode(hexNum);
}

BigInt bigFromBytes(List<int> bytes) {
  return BigInt.parse(HEX.encode(bytes), radix: 16);
}

BigInt getE(ECPoint P, List<int> rX, List<int> m) {
  return bigFromBytes(taggedHash('BIP0340/challenge', rX + bigToBytes(P.x!.toBigInteger()!) + m)) % secp256k1.n;
}

/// If the spending conditions do not require a script path, the output key should commit to an unspendable script path
/// instead of having no script path. This can be achieved by computing the output key point as
/// Q = P + int(hashTapTweak(bytes(P)))G.
/// https://en.bitcoin.it/wiki/BIP_0341#cite_note-22
List<int> taprootConstruct({required ECPoint pubKey, List<int>? merkleRoot}) {
  if (merkleRoot == null) merkleRoot = [];

  final tweak = taggedHash('TapTweak', bigToBytes(pubKey.x!.toBigInteger()!));
  final mul = secp256k1.G * BigInt.parse(HEX.encode(tweak), radix: 16);
  final result = mul! + pubKey;
  return bigToBytes(result!.x!.toBigInteger()!);
}

Uint8List toXOnly(Uint8List pubkey) {
  return pubkey.length == 32 ? pubkey : pubkey.sublist(1, 33);
}