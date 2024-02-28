import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:aleo_dart/aleo.dart';

String host = 'https://api.fxwallet.in';
int decimal = 6;
final dyLib = DyLib.getDyLibFromGit();
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

  final serialNumbers =
      recordFFI.serialNumberStrings(recordCipherTexts, privateKey, viewKey);
  final transactions = await getTransactions(serialNumbers, viewKey);
  /************************************/

  final TxsResult result = TxsResult(
      recordFFI: recordFFI,
      recordCipherTexts: recordCipherTexts,
      viewKey: viewKey,
      address: address);

  /// 获取顺序不可颠倒，需要先处理找零
  result.getOutputTxs(transactions, privateKey);
  result.getInputTxs(inTxsJson, privateKey);
  print(result.privateBalance);
  for (final tx in result.txs) {
    print(tx.toJson());
  }
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
