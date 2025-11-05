import 'dart:math';
import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/bip32/bip32.dart' show NetworkType;
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/ecurve.dart' as ecc;
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/wif.dart' show WIF, decode, encode;
import 'package:hex/hex.dart';

import '../../../../forked_lib/bitcoin_flutter/src/models/networks.dart';
import '../../../../forked_lib/bitcoin_flutter/src/utils/script.dart';

class ECPair {
  Uint8List? _d;
  Uint8List? _Q;
  late NetworkType network;
  bool compressed = true;

  ECPair(Uint8List? d, Uint8List? Q, {NetworkType? network, bool? compressed}) {
    _d = d;
    _Q = Q;
    this.network = network ?? bitcoin;
    this.compressed = compressed ?? true;
  }
  Uint8List? get publicKey {
    _Q ??= ecc.pointFromScalar(_d!, compressed);
    return _Q;
  }

  Uint8List? get privateKey => _d;

  String toWIF() {
    if (privateKey == null) throw ArgumentError('Missing private key');
    return encode(WIF(version: network.wif, privateKey: privateKey!, compressed: compressed));
  }

  Uint8List sign(Uint8List hash) {
    return ecc.sign(hash, privateKey!);
  }

  ECPair ToTweak() {
    if (publicKey == null) throw Exception('Public key missed');

    final key = taggedHash('TapTweak', toXOnly(publicKey!));
    final hasOddY = publicKey![0] == 3 || (publicKey![0] == 4 && (publicKey![64] & 1) == 1);
    final private = hasOddY ? _privateNegate() : privateKey;

    final sum = bigFromBytes(private!) + bigFromBytes(key);
    final r = sum % secp256k1.n;
    final mod = r >= BigInt.zero ? r : secp256k1.n + r;
    final result = Uint8List.fromList(bigToBytes(mod));

    return ECPair.fromPrivateKey(result, network: network, compressed: compressed);
  }

  Uint8List _privateNegate() {
    if (privateKey == null) throw Exception('Private key missing.');

    final bigNumber = -bigFromBytes(privateKey!);
    final r = bigNumber % secp256k1.n;
    final mod = r >= BigInt.zero ? r : secp256k1.n + r;

    return Uint8List.fromList(bigToBytes(mod));
  }

  Uint8List signSchnorr({required Uint8List message, String aux = ''}) {
    final d0 = BigInt.parse(HEX.encode(privateKey!), radix: 16);
    if ((d0 < BigInt.one) || (d0 > (secp256k1.n - BigInt.one))) throw Exception('Private key is invalid.');

    final bAux = HEX.decode(aux.padLeft(64, '0'));
    if (bAux.length != 32) throw Exception('Aux is invalid.');

    final P = (secp256k1.G * d0)!;
    final d = (P.y!.toBigInteger()! % BigInt.two == BigInt.zero) ? d0 : secp256k1.n - d0;
    final t = d ^ bigFromBytes(taggedHash('BIP0340/aux', bAux));
    final k0 = bigFromBytes(taggedHash('BIP0340/nonce', bigToBytes(t) + bigToBytes(P.x!.toBigInteger()!) + message)) % secp256k1.n;

    if (k0.sign == 0) throw Exception('Message is invalid.');

    final R = (secp256k1.G * k0)!;

    final k = (R.y!.toBigInteger()! % BigInt.two == BigInt.zero) ? k0 : secp256k1.n - k0;
    final rX = bigToBytes(R.x!.toBigInteger()!);
    final e = getE(P, rX, message);

    final signature = rX + bigToBytes((k + e * d) % secp256k1.n);
    return Uint8List.fromList(signature);
  }

  bool verify(Uint8List hash, Uint8List signature) {
    return ecc.verify(hash, publicKey!, signature);
  }

  factory ECPair.fromWIF(String w, {NetworkType? network}) {
    var decoded = decode(w);
    final version = decoded.version;

    NetworkType nw;
    if (network != null) {
      nw = network;
      if (nw.wif != version) throw ArgumentError('Invalid network version');
    } else {
      if (version == bitcoin.wif) {
        nw = bitcoin;
      } else if (version == testnet.wif) {
        nw = testnet;
      } else {
        throw ArgumentError('Unknown network version');
      }
    }
    return ECPair.fromPrivateKey(decoded.privateKey, compressed: decoded.compressed, network: nw);
  }

  factory ECPair.fromPublicKey(Uint8List publicKey, {NetworkType? network, bool? compressed}) {
    if (!ecc.isPoint(publicKey)) throw ArgumentError('Point is not on the curve');

    return ECPair(null, publicKey, network: network, compressed: compressed);
  }

  factory ECPair.fromPrivateKey(Uint8List privateKey, {NetworkType? network, bool? compressed}) {
    if (privateKey.length != 32) throw ArgumentError('Expected property privateKey of type Buffer(Length: 32)');
    if (!ecc.isPrivate(privateKey)) throw ArgumentError('Private key not in range [1, n)');

    return ECPair(privateKey, null, network: network, compressed: compressed);
  }

  factory ECPair.makeRandom({NetworkType? network, bool? compressed, Function? rng}) {
    final rFunc = rng ?? _randomBytes;
    Uint8List? d;

    do {
      d = rFunc(32);
      if (d!.length != 32) throw ArgumentError('Expected Buffer(Length: 32)');
    } while (!ecc.isPrivate(d));
    return ECPair.fromPrivateKey(d, network: network, compressed: compressed);
  }
}

const int _SIZE_BYTE = 255;
Uint8List _randomBytes(int size) {
  final rng = Random.secure();
  final bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    bytes[i] = rng.nextInt(_SIZE_BYTE);
  }
  return bytes;
}
