import 'dart:typed_data';

import 'package:buffer/buffer.dart';
import 'package:crypto_wallet_util/src/transaction/eth/lib/utils.dart';
import 'package:pointycastle/export.dart';

import 'package:crypto_wallet_util/src/utils/utils.dart';

final ECDomainParameters secp256k1 = ECCurve_secp256k1();
final BigInt _halfCurveOrder = secp256k1.n ~/ BigInt.two;

/// Provide EcdaSignature sign and [verify].
class EcdaSignature {
  static const int SIGN_LENGTH = 65;

  final Uint8List r;
  final Uint8List s;
  final int v;

  EcdaSignature(this.r, this.s, this.v);

  String getSignatureWithRecId() {
    final dest = Uint8List(65);
    List.copyRange(dest, 0, r);
    List.copyRange(dest, 32, s);
    dest[64] = v;
    return dynamicToString(dest);
  }

  String getSignature() {
    final dest = Uint8List(64);
    List.copyRange(dest, 0, r);
    List.copyRange(dest, 32, s);
    return dynamicToString(dest);
  }

  /// secp256k1 private keys must be exactly 32 bytes and encode a scalar
  /// in [1, n-1]. Every caller that turns a raw private key into a public
  /// key goes through here, so a wrong-length or out-of-range key fails
  /// loudly instead of silently producing a "valid-looking" but wrong key
  /// (BigInt.parse on the wrong byte count just yields a different scalar).
  static BigInt _validatedPrivateScalar(Uint8List privateKey) {
    if (privateKey.length != 32) {
      throw ArgumentError.value(privateKey.length, 'privateKey.length',
          'secp256k1 private key must be exactly 32 bytes');
    }
    final scalar = hexToBigInt(dynamicToHex(privateKey));
    if (scalar == BigInt.zero || scalar >= secp256k1.n) {
      throw ArgumentError('secp256k1 private key is out of range [1, n-1]');
    }
    return scalar;
  }

  static Uint8List privateKeyToPublicKey(Uint8List privateKey,
      {bool compress = true}) {
    final bigPrivateKey = _validatedPrivateScalar(privateKey);
    return (ECCurve_secp256k1().G * bigPrivateKey)!
        .getEncoded(compress)
        .sublist(compress ? 0 : 1);
  }

  static Uint8List getUnCompressedPublicKey(Uint8List privateKey) {
    final bigPrivateKey = _validatedPrivateScalar(privateKey);
    return (ECCurve_secp256k1().G * bigPrivateKey)!.getEncoded(false);
  }

  static Uint8List decompressPublicKey(Uint8List publicKey) {
    final point = secp256k1.curve.decodePoint(publicKey);
    return point!.getEncoded(false);
  }

  factory EcdaSignature.sign(String message, Uint8List privateKey) {
    final messageHash = dynamicToUint8List(message);
    final digest = SHA256Digest();
    final signer = ECDSASigner(null, HMac(digest, 64));
    final key = ECPrivateKey(hexToBigInt(dynamicToHex(privateKey)), secp256k1);

    signer.init(true, PrivateKeyParameter(key));
    ECSignature sig = signer.generateSignature(messageHash) as ECSignature;

    if (sig.s.compareTo(_halfCurveOrder) > 0) {
      final canonicalisedS = secp256k1.n - sig.s;
      sig = ECSignature(sig.r, canonicalisedS);
    }
    String pubHex =
        dynamicToHex(privateKeyToPublicKey(privateKey, compress: false));
    int recId = getRecid(pubHex, message, sig);
    if (recId == -1) {
      throw Exception(
          'Could not construct a recoverable key. This should never happen');
    }
    return EcdaSignature(Uint8List.fromList(toBytesPadded(sig.r, 32)),
        Uint8List.fromList(toBytesPadded(sig.s, 32)), recId);
  }

  factory EcdaSignature.signForEth(Uint8List message, Uint8List privateKey,
      {int chainId = -1}) {
    final digest = SHA256Digest();
    final signer = ECDSASigner(null, HMac(digest, 64));
    final key = ECPrivateKey(hexToBigInt(dynamicToHex(privateKey)), secp256k1);

    signer.init(true, PrivateKeyParameter(key));
    var sig = signer.generateSignature(message) as ECSignature;

    if (sig.s.compareTo(_halfCurveOrder) > 0) {
      final canonicalisedS = secp256k1.n - sig.s;
      sig = ECSignature(sig.r, canonicalisedS);
    }

    String pubHex =
        dynamicToHex(privateKeyToPublicKey(privateKey, compress: false));

    int recId = getRecid(pubHex, message.toStr(), sig);
    if (recId == -1) {
      throw Exception(
          'Could not construct a recoverable key. This should never happen');
    }

    return EcdaSignature(
        Uint8List.fromList(toBytesPadded(sig.r, 32)),
        Uint8List.fromList(toBytesPadded(sig.s, 32)),
        chainId > 0 ? recId + (chainId * 2 + 35) : recId + 27);
  }

  factory EcdaSignature.fromRpcSig(String sig) {
    Uint8List buf = sig.toUint8List();

    // NOTE: with potential introduction of chainId this might need to be updated
    if (buf.length != 65) {
      throw ArgumentError('Invalid signature length');
    }

    var v = buf[64];
    // support both versions of `eth_sign` responses
    if (v < 27) {
      v += 27;
    }

    return EcdaSignature(
      buf.sublist(0, 32),
      buf.sublist(32, 64),
      v,
    );
  }

  /// Convert signature parameters into the format of `eth_sign` RPC method.
  String toRpcSig({int chainId = -1}) {
    var recovery = _calculateSigRecovery(v, chainId: chainId);
    if (!_isValidSigRecovery(recovery)) throw ArgumentError('Invalid signature v value');

    // geth (and the RPC eth_sign method) uses the 65 byte format used by Bitcoin
    var bytesBuffer = BytesBuffer();
    bytesBuffer.add(setLengthLeft(r, 32));
    bytesBuffer.add(setLengthLeft(s, 32));
    bytesBuffer.add(toBuffer(BigInt.from(v)));
    return bufferToHex(bytesBuffer.toBytes());
  }

  int _calculateSigRecovery(int v, {int chainId = -1}) {
    return chainId > 0 ? v - (2 * chainId + 35) : v - 27;
  }

  bool _isValidSigRecovery(int recoveryId) {
    return recoveryId == 0 || recoveryId == 1;
  }

  static int calculateEthSigRecovery(int v, {int chainId = -1}) {
    return chainId > 0 ? v - (2 * chainId + 35) : v - 27;
  }

  static bool isValidEthSigRecovery(int recoveryId) {
    return recoveryId == 0 || recoveryId == 1;
  }

  /// [vIsBareRecoveryId]: EIP-1559/EIP-7702 typed transactions store the
  /// bare y-parity (0/1) in `v`, not the legacy EIP-155-encoded value
  /// (`recId + chainId*2 + 35`). Passing the typed-tx `v` through the
  /// EIP-155 formula yields a bogus recovery id and rejects every valid
  /// signature; callers must set this for typed transactions.
  static bool isValidEthSignature(BigInt r, BigInt s, int v,
      {bool homesteadOrLater = true,
      int chainId = -1,
      bool vIsBareRecoveryId = false}) {
    var SECP256K1_N_DIV_2 = hexToBigInt(dynamicToHex(
        '7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0'));
    var SECP256K1_N = hexToBigInt(dynamicToHex(
        'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141'));

    final recoveryId =
        vIsBareRecoveryId ? v : calculateEthSigRecovery(v, chainId: chainId);
    if (!isValidEthSigRecovery(recoveryId)) return false;
    // r and s are structurally valid whenever 1 <= value < n — the shortest
    // big-endian encoding may legitimately be under 32 bytes (leading zero
    // byte), so byte length must not gate validity here.
    if (r == BigInt.zero ||
        r >= SECP256K1_N ||
        s == BigInt.zero ||
        s >= SECP256K1_N) return false;
    if (homesteadOrLater && s > SECP256K1_N_DIV_2) return false;

    return true;
  }

  static Uint8List privateAdd(Uint8List d, Uint8List tweak) {
    final n = secp256k1.n;
    BigInt tt = BigInt.parse(dynamicToString(tweak), radix: 16);
    BigInt dd = BigInt.parse(dynamicToString(d), radix: 16);
    Uint8List dt = encodeBigInt((dd + tt) % n, endian: Endian.big);
    if (dt.length < 32) {
      Uint8List padLeadingZero = Uint8List(32 - dt.length);
      dt = Uint8List.fromList(padLeadingZero + dt);
    }
    return dt;
  }

  /// Recover the 64-byte uncompressed public key (X‖Y, no 0x04 prefix) that
  /// produced [r]/[s] over [messageHash] for the given [recoveryId] (0/1),
  /// or `null` if [recoveryId] doesn't yield a valid point. This lets a
  /// verifier check a signature against a known address/pubkey instead of
  /// only checking `r`/`s`/`v` are in range.
  static Uint8List? recoverPublicKey(
      BigInt r, BigInt s, int recoveryId, Uint8List messageHash) {
    try {
      final pubKeyBigInt = _recoverFromSignature(
          recoveryId, ECSignature(r, s), messageHash, secp256k1);
      if (pubKeyBigInt == null) return null;
      return encodeBigInt(pubKeyBigInt, endian: Endian.big, bitLength: 512);
    } catch (_) {
      // Invalid points, non-invertible scalars, and infinity are all
      // untrusted-signature failures, not verifier errors.
      return null;
    }
  }

  static int getRecid(String pubHex, String message, ECSignature sig) {
    int recId = -1;
    BigInt publicKey = hexToBigInt(pubHex);
    for (var i = 0; i < 4; i++) {
      final k =
          _recoverFromSignature(i, sig, dynamicToUint8List(message), secp256k1);
      if (k == publicKey) {
        recId = i;
        break;
      }
    }
    return recId;
  }

  static BigInt? _recoverFromSignature(int recId, ECSignature sig,
      Uint8List message, ECDomainParameters params) {
    final n = params.n;
    final i = BigInt.from(recId ~/ 2);
    final x = sig.r + (i * n);

    final prime = BigInt.parse(
        'fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f',
        radix: 16);
    if (x.compareTo(prime) >= 0) return null;

    final R = _decompressKey(x, (recId & 1) == 1, params.curve);
    if (!(R! * n)!.isInfinity) return null;
    final e = decodeBigInt(message, endian: Endian.big);
    BigInt eInv = (BigInt.zero - e) % n;
    BigInt rInv = sig.r.modInverse(n);
    BigInt srInv = (rInv * sig.s) % n;
    BigInt eInvrInv = (rInv * eInv) % n;
    final q = (params.G * eInvrInv)! + (R * srInv);
    final bytes = q?.getEncoded(false);
    return decodeBigInt(bytes!.sublist(1), endian: Endian.big);
  }

  static ECPoint? _decompressKey(BigInt xBN, bool yBit, ECCurve c) {
    List<int> x9IntegerToBytes(BigInt s, int qLength) {
      final bytes = encodeBigInt(s, endian: Endian.big);

      if (qLength < bytes.length) {
        return bytes.sublist(0, bytes.length - qLength);
      } else if (qLength > bytes.length) {
        final tmp = List<int>.filled(qLength, 0);
        final offset = qLength - bytes.length;
        for (int i = 0; i < bytes.length; i++) {
          tmp[i + offset] = bytes[i];
        }
        return tmp;
      }
      return bytes;
    }

    var compEnc = x9IntegerToBytes(xBN, 1 + ((c.fieldSize + 7) ~/ 8));
    compEnc[0] = yBit ? 0x03 : 0x02;
    return c.decodePoint(compEnc);
  }

  /// Verify a raw `r||s` signature: the first 32 bytes are `r`, the next 32
  /// are `s`. Any bytes beyond that are ignored — some callers (e.g. CKB,
  /// HNS) append a trailing recovery id that this check doesn't need.
  /// Returns `false` (instead of throwing) for input shorter than 64 bytes
  /// or a public key that doesn't decode to a point on the curve, so a
  /// malformed signature fails closed rather than crashing the caller.
  static bool verify(String message, Uint8List publicKey, String signature) {
    final sigBytes = dynamicToUint8List(signature);
    if (sigBytes.length < 64) return false;

    ECPoint? Q;
    try {
      Q = secp256k1.curve.decodePoint(publicKey);
    } catch (_) {
      return false;
    }
    if (Q == null) return false;

    BigInt r = decodeBigInt(sigBytes.sublist(0, 32), endian: Endian.big);
    BigInt s = decodeBigInt(sigBytes.sublist(32, 64), endian: Endian.big);

    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    signer.init(false, PublicKeyParameter(ECPublicKey(Q, secp256k1)));
    return signer.verifySignature(
        dynamicToUint8List(message), ECSignature(r, s));
  }

  /// Decode a DER-encoded ECDSA signature (optionally followed by one
  /// sighash byte) into fixed-width raw `r||s` (64 bytes total). `r`/`s` are decoded
  /// as plain big-endian integers rather than copied byte-for-byte, so a
  /// DER integer that is legitimately shorter than 32 bytes (or carries a
  /// sign-disambiguation 0x00 byte) is still re-encoded to the correct
  /// fixed width instead of shifting the `s` offset. Throws
  /// [FormatException] on structurally invalid DER.
  static Uint8List derToRaw(Uint8List der) {
    if (der.length < 8) throw const FormatException('DER signature too short');
    if (der[0] != 0x30) throw const FormatException('Invalid DER sequence tag');

    final totalLen = der[1];
    final derEnd = 2 + totalLen;
    // Accept either bare DER or DER followed by exactly one sighash byte.
    // Additional trailing data would otherwise be silently ignored.
    if (derEnd != der.length && derEnd + 1 != der.length) {
      throw const FormatException('Invalid DER length');
    }
    if (der[2] != 0x02) {
      throw const FormatException('Invalid DER integer tag for r');
    }

    final rLen = der[3];
    if (rLen == 0 || rLen > 33 || 4 + rLen > derEnd) {
      throw const FormatException('Invalid DER r length');
    }
    final rBytes = der.sublist(4, 4 + rLen);
    _validateDerInteger(rBytes, 'r');

    var offset = 4 + rLen;
    if (offset + 1 >= derEnd || der[offset] != 0x02) {
      throw const FormatException('Invalid DER integer tag for s');
    }
    offset += 1;
    final sLen = der[offset];
    offset += 1;
    if (sLen == 0 || sLen > 33 || offset + sLen != derEnd) {
      throw const FormatException('Invalid DER s length');
    }
    final sBytes = der.sublist(offset, offset + sLen);
    _validateDerInteger(sBytes, 's');

    final r = decodeBigInt(rBytes, endian: Endian.big);
    final s = decodeBigInt(sBytes, endian: Endian.big);

    final raw = Uint8List(64);
    raw.setRange(0, 32, encodeBigIntBe(r, length: 32));
    raw.setRange(32, 64, encodeBigIntBe(s, length: 32));
    return raw;
  }

  static void _validateDerInteger(Uint8List bytes, String name) {
    if ((bytes[0] & 0x80) != 0) {
      throw FormatException('DER integer $name is negative');
    }
    if (bytes.length > 32 && bytes[0] != 0) {
      throw FormatException('DER integer $name exceeds 256 bits');
    }
    if (bytes.length > 1 && bytes[0] == 0 && (bytes[1] & 0x80) == 0) {
      throw FormatException('DER integer $name is excessively padded');
    }
  }

  /// Verify a DER-encoded signature with a trailing sighash byte — the
  /// format DOGE/LTC(non-Taproot)/BCH `sign()` actually produce. Returns
  /// `false` for malformed DER instead of throwing.
  static bool verifyDerWithHashType(
      String message, Uint8List publicKey, String signature) {
    try {
      final encoded = dynamicToUint8List(signature);
      if (encoded.length < 9 || 2 + encoded[1] + 1 != encoded.length) {
        return false;
      }
      final raw = derToRaw(encoded);
      return verify(message, publicKey, dynamicToString(raw));
    } catch (_) {
      return false;
    }
  }
}
