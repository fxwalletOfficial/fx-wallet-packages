import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:aleo_dart/aleo.dart';

String host = "https://api.fxwallet.in";
int decimal = 6;
final dyLib = DyLib.getDyLibFromGit();
final rust = AleoRecord(dyLib);

void main() async {
  final inTxs = []; // 收入列表
  final outTxs = [];
  final privateKey =
      'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  final viewKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';

  /// 解析收入交易列表
  final List<dynamic> inTxsJson = json.decode(
      new File('./test/data/aleo_records.json')
          .readAsStringSync(encoding: utf8))['relatedTransactions'];

  for (final inTxJson in inTxsJson) {
    final tx = AleoTransaction.fromJson(inTxJson['transaction']);
    tx.transferType = 'in';
    if (tx.transitionType == TransferType.private) {
      final records = tx.value.split(',');
      BigInt income = BigInt.from(0);
      for (final record in records) {
        if (rust.isOwner(record, viewKey)) {
          final RecordPlainText recordPlainText =
              rust.decryptCipherText(record, viewKey);
          income += BigInt.parse(recordPlainText.getMicrocredits());
        }
      }
      tx.value = income.toString();
    }
    inTxs.add(tx);
  }

  /// 根据record，查询record是否被使用，并得到支出交易列表
  final List<dynamic> recordCipherTextsJson = json.decode(
      new File('./test/data/aleo_records.json')
          .readAsStringSync(encoding: utf8))['records'];

  final List<String> recordCipherTexts =
      recordCipherTextsJson.map((element) => element.toString()).toList();

  final serialNumbers =
      rust.serialNumberStrings(recordCipherTexts, privateKey, viewKey);

  final transactions = await getTransactions(serialNumbers, viewKey);
  BigInt privateBalance = BigInt.from(0);
  for (final tx in transactions) {
    if (tx["transition"] == null) {
      /// 交易详情为空时，说明该record未被使用，加入余额
      final recordCipherText = rust.findRecord(
          recordCipherTexts, tx["serialNumber"], privateKey, viewKey);
      final RecordPlainText record =
          rust.decryptCipherText(recordCipherText, viewKey);
      privateBalance += BigInt.parse(record.getMicrocredits());
    } else {
      print(tx["transition"]);
    }
  }
  print(privateBalance);
}

/// 调用服务端接口，获取serialNumbers对应的交易。
Future<List> getTransactions(List<String> serialNumbers, String viewKey) async {
  final dio = Dio(BaseOptions(
    headers: {
      'x-pubkey': viewKey,
    },
  ));
  List<dynamic> list = [];
  final String serialNumber = serialNumbers.join(",");
  final response =
      await dio.get(host + '/wallet/aleo/find/transactions/' + serialNumber);
  if (response.statusCode == 200) {
    list = response.data['items'];
  }
  return list;
}
