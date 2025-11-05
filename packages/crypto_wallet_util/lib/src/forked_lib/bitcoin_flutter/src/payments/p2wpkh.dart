import 'dart:typed_data';

import 'package:crypto_wallet_util/src/utils/bip32/bip32.dart' show NetworkType;
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/ecurve.dart' show isPoint;
import '../../../../utils/bech32/exceptions.dart';
import '../../../../utils/bech32/segwit.dart';
import '../crypto.dart';
import '../models/networks.dart';
import '../payments/index.dart' show PaymentData;
import '../utils/constants/op.dart';
import '../utils/script.dart' as bscript;

class P2WPKH {
  final EMPTY_SCRIPT = Uint8List.fromList([]);

  PaymentData data;
  late NetworkType network;


  P2WPKH({required this.data, NetworkType? network}) {
    this.network = network ?? bitcoin;
    _init();
  }

  void _init() {
    if (data.address == null && data.hash == null && data.output == null && data.pubkey == null && data.witness == null) throw ArgumentError('Not enough data');

    data.name = 'p2wpkh';

    if (data.address != null) _getDataFromAddress(data.address!);
    if (data.hash != null) _getDataFromHash();

    if (data.output != null) {
      if (data.output!.length != 22 || data.output![0] != OPS['OP_0'] || data.output![1] != 20) throw ArgumentError('Output is invalid');

      data.hash ??= data.output!.sublist(2);
      _getDataFromHash();
    }

    if (data.pubkey != null) {
      data.hash = hash160(data.pubkey!);
      _getDataFromHash();
    }

    if (data.witness != null) {
      if (data.witness!.length != 2) throw ArgumentError('Witness is invalid');
      if (!bscript.isCanonicalScriptSignature(data.witness![0]!)) throw ArgumentError('Witness has invalid signature');
      if (!isPoint(data.witness![1]!)) throw ArgumentError('Witness has invalid pubkey');

      _getDataFromWitness(data.witness!);
    } else if (data.pubkey != null && data.signature != null) {
      data.witness = [data.signature, data.pubkey];
      data.input ??= EMPTY_SCRIPT;
    }
  }

  void _getDataFromWitness([List<Uint8List?>? witness]) {
    data.input ??= EMPTY_SCRIPT;
    if (data.pubkey == null) {
      data.pubkey = witness![1];
      data.hash ??= hash160(data.pubkey!);
      _getDataFromHash();
    }
    data.signature ??= witness![0];
  }

  void _getDataFromHash() {
    data.address ??= segwit.encode(Segwit(network.bech32!, 0, data.hash!)).address;
    data.output ??= bscript.compile([OPS['OP_0'], data.hash]);
  }

  void _getDataFromAddress(String address) {
    try {
      final addr = segwit.decode(SegwitInput(network.bech32!, address));
      if (network.bech32 != addr.hrp) throw ArgumentError('Invalid prefix or Network mismatch');

      // Only support version 0 now;
      if (addr.version != 0) throw ArgumentError('Invalid address version');

      data.hash = Uint8List.fromList(addr.program);
    } on InvalidHrp {
      throw ArgumentError('Invalid prefix or Network mismatch');
    } on InvalidProgramLength {
      throw ArgumentError('Invalid address data');
    } on InvalidWitnessVersion {
      throw ArgumentError('Invalid witness address version');
    }
  }
}
