import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const HARDENED_OFFSET = 0x80000000;
const BLS12_377_CURVE = 'bls12_377 seed';

class Seeds {
  List<int> seed;
  List<int> chainCode;

  Seeds(this.seed, this.chainCode);
}

Uint8List derive(String path, rootSeed) {
  final masterSeed = getMasterSeed(rootSeed);
  final segments = path
      .split('/')
      .sublist(1)
      .map((e) => e.replaceAll("'", ''))
      .map((el) => int.parse(el))
      .toList();

  for (var segment in segments) {
    final seeds = CKDPriv(masterSeed, segment + HARDENED_OFFSET);
    masterSeed.seed = seeds.seed;
    masterSeed.chainCode = seeds.chainCode;
  }
  return Uint8List.fromList(masterSeed.seed);
}

Seeds getMasterSeed(Uint8List seed) {
  final hmac = Hmac(sha512, utf8.encode(BLS12_377_CURVE));
  final i = hmac.convert(seed);
  return Seeds(Uint8List.fromList(i.bytes.sublist(0, 32)),
      Uint8List.fromList(i.bytes.sublist(32)));
}

Seeds CKDPriv(Seeds seeds, index) {
  var indexBuffer = Uint8List(4);
  ByteData.view(indexBuffer.buffer).setUint32(0, index, Endian.big);
  var data = Uint8List.fromList([0, ...seeds.seed, ...indexBuffer]);

  final hmac = Hmac(sha512, seeds.chainCode);
  final i = hmac.convert(data);

  return Seeds(Uint8List.fromList(i.bytes.sublist(0, 32)),
      Uint8List.fromList(i.bytes.sublist(32)));
}
