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

  static Uint8List privateKeyToPublicKey(Uint8List privateKey,
      {bool compress = true}) {
    final bigPrivateKey = hexToBigInt(dynamicToHex(privateKey));
    return (ECCurve_secp256k1().G * bigPrivateKey)!
        .getEncoded(compress)
        .sublist(compress ? 0 : 1);
  }

  static Uint8List getUnCompressedPublicKey(Uint8List privateKey) {
    final bigPrivateKey = hexToBigInt(dynamicToHex(privateKey));
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

  static bool isValidEthSignature(BigInt r, BigInt s, int v,
      {bool homesteadOrLater = true, int chainId = -1}) {
    var SECP256K1_N_DIV_2 = hexToBigInt(dynamicToHex(
        '7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0'));
    var SECP256K1_N = hexToBigInt(dynamicToHex(
        'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141'));

    if (encodeBigInt(r).length != 32 || encodeBigInt(s).length != 32)
      return false;
    if (!isValidEthSigRecovery(calculateEthSigRecovery(v, chainId: chainId)))
      return false;
    if (r == BigInt.zero ||
        r > SECP256K1_N ||
        s == BigInt.zero ||
        s > SECP256K1_N) return false;
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

  static verify(String message, Uint8List publicKey, String signature) {
    ECPoint? Q = secp256k1.curve.decodePoint(publicKey);
    BigInt r = decodeBigInt(dynamicToUint8List(signature).sublist(0, 32),
        endian: Endian.big);
    BigInt s = decodeBigInt(dynamicToUint8List(signature).sublist(32, 64),
        endian: Endian.big);

    final signer = ECDSASigner(null, HMac(SHA256Digest(), 64));
    signer.init(false, PublicKeyParameter(ECPublicKey(Q, secp256k1)));
    return signer.verifySignature(
        dynamicToUint8List(message), ECSignature(r, s));
  }
}
