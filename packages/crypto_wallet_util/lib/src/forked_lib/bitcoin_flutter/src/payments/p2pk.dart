import 'package:crypto_wallet_util/src/utils/bip32/bip32.dart' show NetworkType;
import 'package:crypto_wallet_util/src/utils/bip32/src/utils/ecurve.dart' show isPoint;
import 'package:crypto_wallet_util/src/forked_lib/bitcoin_flutter/src/models/networks.dart' show bitcoin;

import './index.dart' show PaymentData;
import '../utils/constants/op.dart';

class P2PK {
  late PaymentData data;
  late NetworkType network;

  P2PK({required this.data, NetworkType? network}) {
    this.network = network ?? bitcoin;
    _init();
  }

  void _init() {
    if (data.output != null) {
      if (data.output![data.output!.length - 1] != OPS['OP_CHECKSIG']) throw ArgumentError('Output is invalid');
      if (!isPoint(data.output!.sublist(1, -1))) throw ArgumentError('Output pubkey is invalid');
    }

    if (data.input != null) { }
  }
}
