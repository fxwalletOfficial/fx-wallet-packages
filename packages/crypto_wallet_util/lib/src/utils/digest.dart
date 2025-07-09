import 'package:crypto_wallet_util/src/utils/utils.dart';
import 'package:pointycastle/export.dart';
import 'package:crypto/crypto.dart';

Uint8List getSHA256Digest(Uint8List hash) {
  return SHA256Digest().process(hash);
}

Uint8List getRIPEMD160Digest(Uint8List hash) {
  return RIPEMD160Digest().process(hash);
}

String sha256FromUTF8(String input) {
  var digest = SHA256Digest().process(utf8.encode(input));
  return dynamicToString(digest);
}

String sha256fromHex(String hex) {
  var hashed = SHA256Digest().process(hex.toUint8List());
  return dynamicToString(hashed);
}

Uint8List hmacSha512(String key, String data) {
  var hmacSha512 = HMac(SHA512Digest(), 128)
    ..init(KeyParameter(utf8.encode(key)));
  var digest = hmacSha512.process(utf8.encode(data));
  return digest;
}

Uint8List hmacSha512FromList(Uint8List key, Uint8List data) {
  var hmacSha512 = HMac(SHA512Digest(), 128)..init(KeyParameter(key));
  var digest = hmacSha512.process(data);
  return digest;
}

Uint8List getSHA3Digest(Uint8List hash, [int length = 256]) {
  return SHA3Digest(length).process(hash);
}

Uint8List getKeccakDigest(Uint8List hash, [int length = 256]) {
  final keccakDigest = KeccakDigest(256);
  return keccakDigest.process(hash);
}

Uint8List getSha244Digest(Uint8List hash) {
  final sha224Hash = sha224.convert(hash).bytes;
  return sha224Hash.toUint8List();
}

Uint8List getSHA512256(Uint8List input) {
  final hash = sha512256.convert(input);
  return hash.bytes.toUint8List();
}

Uint8List sha160fromHex(String hex) {
  final hashed = getSHA256Digest(hex.toUint8List());
  return getRIPEMD160Digest(hashed);
}

Uint8List sha160fromByte(Uint8List hex) {
  final hashed = getSHA256Digest(hex);
  return getRIPEMD160Digest(hashed);
}
