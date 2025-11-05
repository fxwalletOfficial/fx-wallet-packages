import 'dart:typed_data';

import 'package:crypto_wallet_util/src/type/type.dart';
import 'lib/eth_lib.dart';

enum EthTxType {
  legacy,
  eip1559,
  eip7702,
}

abstract class EthTxData extends TxData {
  final EthTxDataRaw data;
  final TxNetwork network;
  final EthTxType txType;

  EthTxData({required this.data, required this.network, required this.txType});

  Eip7702Authorization get authorization;

  /// Returns the serialized unsigned tx (hashed or raw), which can be used.
  List raw();

  /// Returns the serialized encoding of the EIP-1559 transaction.
  Uint8List serialize({bool sig = true});

  Uint8List getMessageToSign();
}
