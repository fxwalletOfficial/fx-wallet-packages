import 'dart:convert';
import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import './local/config.dart';

String host = 'https://api.fxwallet.in';
// String host = "http://127.0.0.1:14042";
int decimal = 6;
final dyLib = DyLib.getDyLibFromCargo();
final recordFFI = AleoRecord(dyLib);
final accountFFI = AleoAccount(dyLib);

void main() async {
  final viewKey = Config.viewKey;
  final address = Config.address;
  // 这个列表相当于token列表，可以从后端获取
  final programs = ['betastaking.aleo', 'pondo_protocol.aleo'];

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
      address: address,
      programs: programs);
  publicTxs.getPublicTxs(pubTxsJson);

  // token交易解析
  final tokenTxs = publicTxs.getTokenTxs(publicTxs.txs, 'pondo_protocol.aleo');
  for (final tx in tokenTxs) {
    print(tx.toJson());
  }
}
