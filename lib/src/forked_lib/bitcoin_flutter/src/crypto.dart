import 'dart:typed_data';

import 'package:pointycastle/export.dart';

Uint8List hash160(Uint8List buffer) {
  var _tmp = SHA256Digest().process(buffer);
  return RIPEMD160Digest().process(_tmp);
}

Uint8List hmacSHA512(Uint8List key, Uint8List data) {
  final _tmp = HMac(SHA512Digest(), 128)..init(KeyParameter(key));
  return _tmp.process(data);
}

Uint8List hash256(Uint8List buffer) {
  var _tmp = SHA256Digest().process(buffer);
  return SHA256Digest().process(_tmp);
}

Uint8List sha256(Uint8List buffer) {
  return SHA256Digest().process(buffer);
}
