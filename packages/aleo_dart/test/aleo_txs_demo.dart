import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:aleo_dart/aleo.dart';

String host = 'https://api.fxwallet.in';
int decimal = 6;
final dyLib = DyLib.getDyLibFromGit();
final rust = AleoRecord(dyLib);

void main() async {
  final txs = []; // 交易列表
  final privateKey =
      'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  final viewKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
  final address =
      'aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn';

  final List<String> txIds = [];

  /// 根据record，查询record是否被使用，并得到支出交易列表,先查支出，方便填充支出地址。
  final List<dynamic> recordCipherTextsJson = json.decode(
      new File('./test/data/aleo_records.json')
          .readAsStringSync(encoding: utf8))['records'];

  final List<String> recordCipherTexts =
      recordCipherTextsJson.map((element) => element.toString()).toList();

  final serialNumbers =
      rust.serialNumberStrings(recordCipherTexts, privateKey, viewKey);

  final transactions = await getTransactions(serialNumbers, viewKey);
  BigInt privateBalance = BigInt.from(0);
  for (final outTxJson in transactions) {
    if (outTxJson['transition'] == null) {
      /// 交易详情为空时，说明该record未被使用，加入余额
      final recordCipherText = rust.findRecord(
          recordCipherTexts, outTxJson['serialNumber'], privateKey, viewKey);
      final RecordPlainText record =
          rust.decryptCipherText(recordCipherText, viewKey);
      privateBalance += BigInt.parse(record.getMicrocredits());
    } else {
      final transactionId = outTxJson['transition']['id'];
      if (!txIds.contains(transactionId)) {
        final outTx = AleoTransaction.fromJson(outTxJson['transition']);
        outTx.transferType = TransferType.expense;
        outTx.processPrivateTx(rust, viewKey, privateKey,
            outTxJson['transition'], recordCipherTexts);
        txs.add(outTx);
        txIds.add(outTx.transactionId);
        outTx.inputAddress = address;
      } // 包含时，说明有两个record被用作同个交易。即用了 fee_private
    }
  }
  print(privateBalance);

  /// 解析收入交易列表
  final List<dynamic> inTxsJson = json.decode(
      new File('./test/data/aleo_records.json')
          .readAsStringSync(encoding: utf8))['relatedTransactions'];
  for (final inTxJson in inTxsJson) {
    final transactionId = inTxJson['transaction']['id'];
    if (!txIds.contains(transactionId)) {
      final tx = AleoTransaction.fromJson(inTxJson['transaction']);
      tx.processPrivateTx(rust, viewKey, privateKey, inTxJson['transaction'],
          recordCipherTexts);
      tx.transferType = TransferType.income;
      txs.add(tx);
      txIds.add(tx.transactionId.toString());
      tx.outputAddress = address;
    }
  }

  for (final tx in txs) {
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
