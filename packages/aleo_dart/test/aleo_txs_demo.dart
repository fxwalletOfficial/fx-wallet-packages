import 'package:dio/dio.dart';

import 'package:aleo_dart/aleo.dart';

String host = "https://api.fxwallet.in";
int decimal = 6;
final dyLib = DyLib.getDyLibFromGit();
final rust = AleoRecord(dyLib);

void main() async {
  final recordCipherTexts = [
    'record1qyqspdn8f6lh4eum9a36l93mnxh5vcqssjsep9z4lp4vpya2efgmjdsvqyxx66trwfhkxun9v35hguerqqpqzq9yu3tvsnj4x0a7e2w9w204aya09thraeckdlsn59pve6fnnd3eqv0n7jpp5rsxn48jdjj3z55vhmp42f8hxp7vk5d2430vuvk3fzrsx0w9wqw',
    'record1qyqsqlqqe6juvqslkdhucee33dmsntt5amqptxcddys2e5td3j0mtgq3qyxx66trwfhkxun9v35hguerqqpqzqy9csc67ez5gzezsx2ja59u0727ydfsa4fkgh3d55fgmd5t9yccphss9v6ffmr68yt9jkcex7yg9zzwh57zpznce80zh6rranmcgyus208vey6',
    'record1qyqspj8md5yhtk774sum5r5lp0q7ysrz3uljtw98aqj9n9626ga9kqqxqyxx66trwfhkxun9v35hguerqqpqzqrwzmj36tyjlqnnsfk9j29739zusxxccj5ls0cztztp40aguqu9qvuh09t8r9fsjlvmhhcku6wkz7dejcc43yh4rlwf4gk24hwrpgnswcdfanf',
  ];
  final privateKey =
      'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  final viewKey = 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
  final serialNumbers =
      rust.serialNumberStrings(recordCipherTexts, privateKey, viewKey);

  final tansactions = await getTransactions(serialNumbers, viewKey);
  BigInt privateBalance = BigInt.from(0);
  for (final tx in tansactions) {
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
