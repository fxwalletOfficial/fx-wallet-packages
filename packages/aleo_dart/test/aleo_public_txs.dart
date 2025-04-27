import 'dart:convert';
import 'dart:io';

import 'package:aleo_dart/aleo.dart';

String host = 'https://api.fxwallet.in';
// String host = "http://127.0.0.1:14042";
int decimal = 6;
final dyLib = DyLib.getDyLibFromCargo();
final recordFFI = AleoRecord(dyLib);
final accountFFI = AleoAccount(dyLib);

void main() async {
  final viewKey = '';
  final address =
      'aleo1j5s754demr84a9mnkwtwxts4z8e6nvsx0f5m9yaw7803cxqgauyqg5vz5u';

  /// 公开交易解析， public方为该地址的所有交易，通过viewkey筛掉，确保与隐私交易不重复。
  final List<dynamic> pubTxsJson = json.decode(
      new File('./test/data/aleo_contract.json')
          .readAsStringSync(encoding: utf8))['publicTransactions'];
  // print(pubTxsJson);
  print("公开tx");
  final TxsResult publicTxs = TxsResult(
      recordFFI: recordFFI,
      recordCipherTexts: [],
      viewKey: viewKey,
      address: address);
  publicTxs.getPublicTxs(pubTxsJson);
  for (final tx in publicTxs.txs) {
    print(tx.toJson());
  }
}
