import 'package:protobuf/protobuf.dart';

import 'package:crypto_wallet_util/src/forked_lib/cosmos_dart/cosmos_dart.dart';
import 'package:crypto_wallet_util/src/type/tx_data_type.dart';

/// [CosmosTxData] requires [msgs], [data], [config], [memo], [fee]
/// [msgs] is the parameter to be signed.
class CosmosTxData extends TxData {
  final List<GeneratedMessage> msgs;
  final SignerData data;
  TxConfig? config;
  final String? memo;
  Fee? fee;

  CosmosTxData(
      {required this.msgs,
      required this.data,
      this.config,
      this.memo,
      this.fee});

  @override
  Map<String, dynamic> toBroadcast() {
    return {};
  }

  @override
  Map<String, dynamic> toJson() {
    return {};
  }
}
