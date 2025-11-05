import 'dart:typed_data';

import 'package:bs58check/bs58check.dart' as bs58check;
import 'package:crypto_wallet_util/src/utils/bip32/bip32.dart' show NetworkType;
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/ecurve.dart' show isPoint;
import 'package:pointycastle/export.dart';

import '../../../../utils/bech32/bech32.dart';
import '../utils/script.dart';
import '../crypto.dart';
import '../models/networks.dart';
import '../payments/index.dart' show PaymentData;
import '../utils/blake2b.dart';
import '../utils/constants/op.dart';

final _secp256k1 = ECCurve_secp256k1();

class P2PKH {
  PaymentData data;
  late NetworkType network;

  P2PKH({required this.data, network}) {
    this.network = network ?? bitcoin;
    _init();
  }

  void _init() {
    data.name = 'p2pkh';
    if (data.address != null) {
      _getDataFromAddress(data.address!);
      _getDataFromHash();
    } else if (data.hash != null) {
      _getDataFromHash();
    } else if (data.output != null) {
      if (!isValidOutput(data.output!))
        throw ArgumentError('Output is invalid');
      data.hash = data.output!.sublist(3, 23);
      _getDataFromHash();
    } else if (data.pubkey != null) {
      data.hash = hash160(data.pubkey!);
      _getDataFromHash();
      _getDataFromChunk();
    } else if (data.input != null) {
      final chunks = decompile(data.input)!;
      _getDataFromChunk(chunks);

      if (chunks.length != 2) throw ArgumentError('Input is invalid');
      if (!isCanonicalScriptSignature(chunks[0]))
        throw ArgumentError('Input has invalid signature');
      if (!isPoint(chunks[1])) throw ArgumentError('Input has invalid pubkey');

      data.witness = [];
    } else {
      throw ArgumentError('Not enough data');
    }
  }

  void _getDataFromChunk([List<dynamic>? chunks]) {
    if (data.pubkey == null && chunks != null) {
      data.pubkey =
          (chunks[1] is int) ? Uint8List.fromList([chunks[1]]) : chunks[1];
      data.hash = hash160(data.pubkey!);
      _getDataFromHash();
    }
    if (data.signature == null && chunks != null) {
      data.signature =
          (chunks[0] is int) ? Uint8List.fromList([chunks[0]]) : chunks[0];
    }
    if (data.input == null && data.pubkey != null && data.signature != null) {
      data.input = compile([data.signature, data.pubkey]);
    }
  }

  void _getDataFromHash() {
    if (data.address == null) {
      final payload = Uint8List(21);
      payload.buffer.asByteData().setUint8(0, network.pubKeyHash);
      payload.setRange(1, payload.length, data.hash!);
      data.address = bs58check.encode(payload);
    }
    data.output ??= compile([
      OPS['OP_DUP'],
      OPS['OP_HASH160'],
      data.hash,
      OPS['OP_EQUALVERIFY'],
      OPS['OP_CHECKSIG']
    ]);
  }

  void _getDataFromAddress(String address) {
    var payload = bs58check.decode(address);
    final version = payload.buffer.asByteData().getUint8(0);
    if (version != network.pubKeyHash) {
      throw ArgumentError('Invalid version or Network mismatch');
    }
    data.hash = payload.sublist(1);
    if (data.hash!.length != 20) throw ArgumentError('Invalid address');
  }

  String get addressInBlake2b {
    final digest = convertBit(Blake2b.digest(data.pubkey!, 20));
    return bech32.encode(Bech32(network.bech32 ?? 'bc', digest));
  }

  String get tapRootAddress {
    if (data.pubkey == null) return '';

    final pub = _secp256k1.curve.decodePoint(data.pubkey!)!;

    final info = taprootConstruct(pubKey: pub);
    final words = convertBits(info, 8, 5);
    final addr = bech32.encode(Bech32(network.bech32!, [1] + words),
        encoding: 'bech32m');

    return addr;
  }

  static String getTaprootAddress(Uint8List publicKey, String prefix) {
    final pub = _secp256k1.curve.decodePoint(publicKey)!;

    final info = taprootConstruct(pubKey: pub);
    final words = convertBits(info, 8, 5);
    final addr =
        bech32.encode(Bech32(prefix, [1] + words), encoding: 'bech32m');
    return addr;
  }

  String get bech32Address {
    final digest = convertBits(data.hash, 8, 5);
    return bech32.encode(Bech32(network.bech32 ?? 'bc', digest));
  }
}

bool isValidOutput(Uint8List data) {
  return data.length == 25 &&
      data[0] == OPS['OP_DUP'] &&
      data[1] == OPS['OP_HASH160'] &&
      data[2] == 0x14 &&
      data[23] == OPS['OP_EQUALVERIFY'] &&
      data[24] == OPS['OP_CHECKSIG'];
}
