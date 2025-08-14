import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bs58check/bs58check.dart' as bs58;
import 'package:hex/hex.dart';

import '../src/ecpair.dart';
import '../src/models/networks.dart';
import '../src/payments/index.dart' show PaymentData;
import '../src/payments/p2pkh.dart';
import '../src/utils/magic_hash.dart';
import '../src/utils/script.dart';

/// Checks if you are awesome. Spoiler: you are.
class HDWallet {
  bip32.BIP32? _bip32;
  P2PKH? _p2pkh;
  String? seed;
  NetworkType network;

  String? get privKey {
    if (_bip32 == null) return null;
    try {
      return HEX.encode(_bip32!.privateKey!);
    } catch (_) {
      return null;
    }
  }

  String? get pubKey => _bip32 != null ? HEX.encode(_bip32!.publicKey) : null;
  Uint8List? get fingerprint =>  _bip32?.fingerprint;

  String? get base58Priv {
    if (_bip32 == null) return null;
    try {
      return _bip32!.toBase58();
    } catch (_) {
      return null;
    }
  }

  String? get base58 => _bip32?.neutered().toBase58();

  String? get wif {
    if (_bip32 == null) return null;
    try {
      return _bip32!.toWIF();
    } catch (_) {
      return null;
    }
  }

  String? get address => _p2pkh?.data.address;

  String? get bech32Address => _p2pkh?.bech32Address;

  String? get bchAddress {
    if (address == null || network.prefix == null) return null;

    final decode = bs58.decode(address!);
    final hash = decode.sublist(1);
    final type = 'P2PKH';

    final prefixData = prefixToUint5Array(network.prefix!) + [0];
    final versionByte = getTypeBits(type) + getHashSizeBits(hash);
    final payloadData = convertBits([versionByte] + hash, 8, 5);
    final checksumData = prefixData + payloadData + List.generate(8, (index) => 0);
    final payload = payloadData + checksumToUint5Array(polymod(checksumData));

    return '${network.prefix!}:${base32Encode(payload)}';
  }

  String? get addressInBlake2b => _p2pkh?.addressInBlake2b;

  String? get tapRootAddress => _p2pkh?.tapRootAddress;

  HDWallet({required bip32, required p2pkh, required this.network, this.seed}) {
    _bip32 = bip32;
    _p2pkh = p2pkh;
  }

  HDWallet derivePath(String path) {
    final bip32 = _bip32!.derivePath(path);
    final p2pkh = P2PKH(data: PaymentData(pubkey: bip32.publicKey), network: network);
    return HDWallet(bip32: bip32, p2pkh: p2pkh, network: network);
  }

  HDWallet derive(int index) {
    final bip32 = _bip32!.derive(index);
    final p2pkh = P2PKH(data: PaymentData(pubkey: bip32.publicKey), network: network);
    return HDWallet(bip32: bip32, p2pkh: p2pkh, network: network);
  }

  factory HDWallet.fromSeed(Uint8List seed, {NetworkType? network}) {
    network = network ?? bitcoin;
    final seedHex = HEX.encode(seed);
    final wallet = bip32.BIP32.fromSeed(seed, bip32.NetworkType(bip32: bip32.Bip32Type(public: network.bip32.public, private: network.bip32.private), wif: network.wif));
    final p2pkh = P2PKH(data: PaymentData(pubkey: wallet.publicKey), network: network);
    return HDWallet(bip32: wallet, p2pkh: p2pkh, network: network, seed: seedHex);
  }

  factory HDWallet.fromBase58(String xpub, {NetworkType? network}) {
    network = network ?? bitcoin;
    var wallet;
    var p2pkh;
    try {
      wallet = bip32.BIP32.fromBase58(xpub, bip32.NetworkType(
          bip32: bip32.Bip32Type(
              public: network.bip32.public, private: network.bip32.private),
          wif: network.wif));
    }catch(e){
    }
    try {
      p2pkh = P2PKH(
          data: PaymentData(pubkey: wallet.publicKey), network: network);
    }catch(e){
    }
    return HDWallet(bip32: wallet, p2pkh: p2pkh, network: network, seed: null);
  }

  Uint8List? sign(String message) {
    var messageHash = magicHash(message, network);
    return _bip32!.sign(messageHash);
  }

  bool? verify({required String message, required Uint8List signature}) {
    var messageHash = magicHash(message);
    return _bip32!.verify(messageHash, signature);
  }
}

class Wallet {
  ECPair _keyPair;
  P2PKH _p2pkh;
  NetworkType? network;

  String? get privKey => HEX.encode(_keyPair.privateKey!);

  String? get pubKey => HEX.encode(_keyPair.publicKey!);

  String? get wif => _keyPair.toWIF();

  String? get address => _p2pkh.data.address;

  Wallet(this._keyPair, this._p2pkh, this.network);

  factory Wallet.random([NetworkType? network]) {
    final keyPair = ECPair.makeRandom(network: network);
    final p2pkh = P2PKH(data: PaymentData(pubkey: keyPair.publicKey), network: network);
    return Wallet(keyPair, p2pkh, network);
  }

  factory Wallet.fromWIF(String wif, [NetworkType? network]) {
    network = network ?? bitcoin;
    final keyPair = ECPair.fromWIF(wif, network: network);
    final p2pkh = P2PKH(data: PaymentData(pubkey: keyPair.publicKey), network: network);
    return Wallet(keyPair, p2pkh, network);
  }

  Uint8List sign(String message) {
    var messageHash = magicHash(message, network);
    return _keyPair.sign(messageHash);
  }

  bool verify({required String message, required Uint8List signature}) {
    var messageHash = magicHash(message, network);
    return _keyPair.verify(messageHash, signature);
  }
}
