import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:aleo_dart/aleo.dart';

String host = 'https://api.fxwallet.in';
// String host = "http://127.0.0.1:14042";
int decimal = 6;
final dyLib = DyLib.getDyLibFromCargo();
final recordFFI = AleoRecord(dyLib);
final accountFFI = AleoAccount(dyLib);

void main() async {
  final privateKey =
      'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  final viewKey = accountFFI.privateKeyToViewKey(privateKey);
  final address = accountFFI.viewKeyToAddress(viewKey);
  /******************调用服务端接口******************/
  /// 根据record，查询record是否被使用，并得到支出交易列表,先查支出，方便填充支出地址。
  final List<dynamic> recordCipherTextsJson = json.decode(
      new File('./test/data/aleo_records.json')
          .readAsStringSync(encoding: utf8))['records'];
  final List<dynamic> inTxsJson = json.decode(
      new File('./test/data/aleo_records.json')
          .readAsStringSync(encoding: utf8))['relatedTransactions'];
  final List<String> recordCipherTexts =
      recordCipherTextsJson.map((element) => element.toString()).toList();

  // final serialNumbers =
  //     recordFFI.serialNumberStrings(recordCipherTexts, privateKey, viewKey);
  final transactions = await getTransactions([
    '4775316136567027422469909554081132673061515973831856190895264347775107022190field',
    '4664111833154054231879463096168632726079903950894832866280659902063967214328field'
  ], viewKey);
  /************************************/
  final TxsResult result = TxsResult(
      recordFFI: recordFFI,
      recordCipherTexts: recordCipherTexts,
      viewKey: viewKey,
      address: address);

  print("隐私余额+tx");

  /// 获取顺序不可颠倒，需要先处理找零
  result.getOutputTxs(transactions, privateKey);
  result.getInputTxs(inTxsJson, privateKey);
  print(result.privateBalance);
  for (final tx in result.txs) {
    print(tx.toJson());
  }

  /// 公开交易解析， public方为该地址的所有交易，通过viewkey筛掉，确保与隐私交易不重复。
  final List<dynamic> pubTxsJson = json.decode(
      new File('./test/data/aleo_records.json')
          .readAsStringSync(encoding: utf8))['publicTransactions'];
  // print(pubTxsJson);
  print("公开tx");
  final programs = ['betastaking.aleo'];
  final TxsResult publicTxs = TxsResult(
      recordFFI: recordFFI,
      recordCipherTexts: [],
      viewKey: viewKey,
      address: address,
      programs: programs);  
  publicTxs.getPublicTxs(pubTxsJson);
  // 解析付款方地址
  publicTxs.getSender();
  for (final tx in publicTxs.txs) {
    print(tx.toJson());
  }

  // 如果需要解析token交易，则在所有交易中过滤出contract交易，并找出对应token的交易。

}

/// 调用服务端接口，获取serialNumbers对应的交易。
Future<List> getTransactions(List<String> serialNumbers, String viewKey) async {
  final dio = Dio(BaseOptions(
    headers: {
      'x-pubkey': viewKey,
    },
  ));
  List<dynamic> list = [];
  final String serialNumber = serialNumbers.join(',');
  final response =
      await dio.get(host + '/wallet/aleo/find/transactions/' + serialNumber);
  if (response.statusCode == 200) {
    list = response.data['items'];
  }
  return list;
}
