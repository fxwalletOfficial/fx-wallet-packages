import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/exceptions.dart';
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/base58.dart';
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/constants.dart';
import 'package:pointycastle/export.dart';
// ignore: implementation_imports
import 'package:pointycastle/src/utils.dart' as utils;

/// The Bitcoin curve
final _curve = ECCurve_secp256k1();

/// From the specification the length of a private of public key
const int _lengthOfKey = 33;

/// FirstHardenedChild is the index of the first 'hardened' child key as per the bip32 spec
const int firstHardenedChild = 0x80000000;

/// From the BIP32 spec. Used when calculating the hmac of the seed
final Uint8List _masterKey = utf8.encoder.convert('Bitcoin seed');

BigInt _decodeBigInt(Uint8List bytes) {
  var negative = bytes.isNotEmpty && bytes[0] & 0x80 == 0x80;
  if (negative) return bcDecodeBigInt([0, ...bytes]);

  return bcDecodeBigInt(bytes);
}

/// AKA 'point(k)' in the specification
ECPoint _publicKeyFor(BigInt d) {
  return ECPublicKey(_curve.G * d, _curve).Q!;
}

/// AKA 'ser_P(P)' in the specification
Uint8List _compressed(ECPoint q) {
  return q.getEncoded(true);
}

/// AKA 'ser_32(i)' in the specification
Uint8List _serializeTo4bytes(int i) {
  var bytes = ByteData(4)..setInt32(0, i, Endian.big);

  return bytes.buffer.asUint8List();
}

/// CKDPriv in the specification
ExtendedPrivateKey _deriveExtendedPrivateChildKey(ExtendedPrivateKey parent, int childNumber) {
  var message = childNumber >= firstHardenedChild ? _derivePrivateMessage(parent, childNumber) : _derivePublicMessage(parent.publicKey, childNumber);
  var hash = _hmacSha512(parent.chainCode, message);

  var leftSide = _decodeBigInt(_leftFrom(hash));
  if (leftSide >= _curve.n) throw KeyBiggerThanOrder();


  var childPrivateKey = (leftSide + parent.key) % _curve.n;
  if (childPrivateKey == BigInt.zero) throw KeyZero();

  var chainCode = _rightFrom(hash);

  return ExtendedPrivateKey(
    version: parent.version,
    key: childPrivateKey,
    chainCode: chainCode,
    childNumber: childNumber,
    depth: parent.depth + 1,
    parentFingerprint: parent.fingerprint
  );
}

/// CKDPub in the specification
ExtendedPublicKey _deriveExtendedPublicChildKey(ExtendedPublicKey parent, int childNumber) {
  if (childNumber >= firstHardenedChild) throw InvalidChildNumber();

  var message = _derivePublicMessage(parent, childNumber);
  var hash = _hmacSha512(parent.chainCode, message);

  var leftSide = _decodeBigInt(_leftFrom(hash));
  if (leftSide >= _curve.n) throw KeyBiggerThanOrder();


  var childPublicKey = _publicKeyFor(leftSide) + parent.q;
  if (childPublicKey!.isInfinity) throw KeyInfinite();

  return ExtendedPublicKey(
    version: Uint8List.fromList(xpub),
    q: childPublicKey,
    chainCode: _rightFrom(hash),
    childNumber: childNumber,
    depth: parent.depth + 1,
    parentFingerprint: parent.fingerprint,
  );
}

Uint8List _paddedEncodedBigInt(BigInt i) {
  var fullLength = Uint8List(_lengthOfKey - 1);
  var encodedBigInt = utils.encodeBigIntAsUnsigned(i);
  fullLength.setAll(fullLength.length - encodedBigInt.length, encodedBigInt);

  return fullLength;
}

Uint8List _derivePrivateMessage(ExtendedPrivateKey key, int childNumber) {
  var message = Uint8List(37)
    ..setAll(1, _paddedEncodedBigInt(key.key))
    ..setAll(33, _serializeTo4bytes(childNumber));

  return message;
}

Uint8List _derivePublicMessage(ExtendedPublicKey key, int childNumber) {
  var message = Uint8List(37)
    ..setAll(0, _compressed(key.q))
    ..setAll(33, _serializeTo4bytes(childNumber));

  return message;
}

/// This function returns a list of length 64. The first half is the key, the second half is the chain code.
Uint8List _hmacSha512(Uint8List key, Uint8List message) {
  var hmac = HMac(SHA512Digest(), 128)..init(KeyParameter(key));
  return hmac.process(message);
}

/// Double hash the data: RIPEMD160(SHA256(data))
Uint8List _hash160(Uint8List data) {
  return RIPEMD160Digest().process(SHA256Digest().process(data));
}

Uint8List _leftFrom(Uint8List list) {
  return list.sublist(0, 32);
}

Uint8List _rightFrom(Uint8List list) {
  return list.sublist(32);
}

// NOTE wow, this is annoying
bool _equal(Iterable a, Iterable b) {
  if (a.length != b.length) return false;

  for (var i = 0; i < a.length; i++) {
    if (a.elementAt(i) != b.elementAt(i)) return false;
  }

  return true;
}

/// Abstract class on which [ExtendedPrivateKey] and [ExtendedPublicKey] are based.
abstract class ExtendedKey {
  ExtendedKey({
    required this.version,
    required this.depth,
    required this.childNumber,
    required this.chainCode,
    required this.parentFingerprint,
  });

  /// 32 bytes
  final Uint8List chainCode;

  final int childNumber;

  final int depth;

  /// 4 bytes
  final Uint8List version;

  /// 4 bytes
  final Uint8List parentFingerprint;

  /// Returns the first 4 bytes of the hash160 compressed public key.
  Uint8List get fingerprint;

  /// Returns the public key associated with the extended key. In case of [ExtendedPublicKey] returns self.
  ExtendedPublicKey get publicKey;

  List<int> _serialize() {
    return [
      ...version,
      depth,
      ...parentFingerprint,
      ..._serializeTo4bytes(childNumber),
      ...chainCode,
      ..._serializedKey()
    ];
  }

  List<int> _serializedKey();
  ExtendedKey derive(int childNumber);

  /// Used to verify deserialized keys.
  bool verifyChecksum(Uint8List externalChecksum) {
    return _equal(_checksum(), externalChecksum.toList());
  }

  Iterable<int> _checksum() {
    return SHA256Digest()
        .process(SHA256Digest().process(Uint8List.fromList(_serialize())))
        .getRange(0, 4);
  }

  /// Returns the string representation of this extended key. This can be written to disk for future deserialize.
  @override
  String toString() {
    var payload = _serialize()..addAll(_checksum());

    return Base58Codec(Base58CheckCodec.bitcoinAlphabet).encode(payload);
  }

  /// Derives a key based on a path.
  ///
  /// A path is a slash delimited string starting with 'm' for private key and
  /// 'M' for a public key. Hardened keys are indexed with a tick.
  /// Example: "m/100/1'".
  /// This is the first Hardened private extended key on depth 2.
  ExtendedKey forPath(String path) {
    _validatePath(path);

    var wantsPrivate = path[0] == 'm';
    var children = _parseChildren(path);

    if (children.isEmpty) {
      if (wantsPrivate) return this;

      return publicKey;
    }

    return children.fold(this, (previousKey, childNumber) => previousKey.derive(childNumber));
  }

  void _validatePath(String path) {
    var kind = path.split('/').removeAt(0);

    if (!['m', 'M'].contains(kind)) throw InvalidPath("Path needs to start with 'm' or 'M'");
    if (kind == 'm' && this is ExtendedPublicKey) throw InvalidPath('Cannot derive private key from public master');
  }

  Iterable<int> _parseChildren(String path) {
    var explodedList = path.split('/')..removeAt(0)..removeWhere((child) => child == '');

    return explodedList.map((pathFragment) {
      if (pathFragment.endsWith("'")) {
        pathFragment = pathFragment.substring(0, pathFragment.length - 1);
        return int.parse(pathFragment) + firstHardenedChild;
      }

      return int.parse(pathFragment);
    });
  }
}

/// An extended private key as defined by the BIP32 specification.
///
/// In the lingo of the spec this is a `(k, c)`.
/// This can be used to generate a extended public key or further child keys.
/// Note that the spec talks about a 'neutered' key, this is the public key associated with a private key.
class ExtendedPrivateKey extends ExtendedKey {
  ExtendedPrivateKey({
    required this.key,
    required super.version,
    required super.depth,
    required super.childNumber,
    required super.chainCode,
    required super.parentFingerprint
  });

  factory ExtendedPrivateKey.master(Uint8List seed, List<int> version) {
    final hash = _hmacSha512(_masterKey, seed);
    final key = _decodeBigInt(_leftFrom(hash));
    final chainCode = _rightFrom(hash);
    final depth = 0;
    final childNumber = 0;
    final parentFingerprint = Uint8List.fromList([0, 0, 0, 0]);

    return ExtendedPrivateKey(
      version: Uint8List.fromList(version),
      key: key,
      chainCode: chainCode,
      depth: depth,
      childNumber: childNumber,
      parentFingerprint: parentFingerprint
    );
  }

  final BigInt key;

  ExtendedPublicKey? _publicKey;

  @override
  ExtendedPublicKey get publicKey {
    final v = _equal(version, zprv) ? zpub : xpub;

    _publicKey ??= ExtendedPublicKey(
      version: Uint8List.fromList(v),
      q: _publicKeyFor(key),
      depth: depth,
      childNumber: childNumber,
      chainCode: chainCode,
      parentFingerprint: parentFingerprint,
    );

    return _publicKey!;
  }

  @override
  Uint8List get fingerprint => publicKey.fingerprint;

  @override
  List<int> _serializedKey() {
    final text = key.toRadixString(16).padLeft(66, '0');
    var serialization = hex.decode(text);
    return serialization;
  }

  @override
  ExtendedPrivateKey derive(int childNumber) => _deriveExtendedPrivateChildKey(this, childNumber);
}

/// An extended public key as defined by the BIP32 specification.
///
/// In the lingo of the spec this is a `(K, c)`. This can be used to generate further public child keys only.
class ExtendedPublicKey extends ExtendedKey {
  ExtendedPublicKey({
    required this.q,
    required super.version,
    required super.depth,
    required super.childNumber,
    required super.chainCode,
    required super.parentFingerprint
  });

  final ECPoint q;

  @override
  Uint8List get fingerprint {
    var identifier = _hash160(_compressed(q));
    return Uint8List.view(identifier.buffer, 0, 4);
  }

  @override
  ExtendedPublicKey get publicKey {
    return this;
  }

  @override
  List<int> _serializedKey() {
    return _compressed(q).toList();
  }

  @override
  ExtendedPublicKey derive(int childNumber) => _deriveExtendedPublicChildKey(this, childNumber);
}

/// Decode a BigInt from bytes in big-endian encoding.
/// Twos compliment.
BigInt bcDecodeBigInt(List<int> bytes) {
  var negative = bytes.isNotEmpty && bytes[0] & 0x80 == 0x80;

  BigInt result;

  if (bytes.length == 1) {
    result = BigInt.from(bytes[0]);
  } else {
    result = BigInt.zero;
    for (var i = 0; i < bytes.length; i++) {
      var item = bytes[bytes.length - i - 1];
      result |= BigInt.from(item) << (8 * i);
    }
  }
  return result != BigInt.zero
      ? negative
          ? result.toSigned(result.bitLength)
          : result
      : BigInt.zero;
}
