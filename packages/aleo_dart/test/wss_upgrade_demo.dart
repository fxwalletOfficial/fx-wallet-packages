import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/io.dart';

import 'package:aleo_dart/aleo.dart';
import './local/config.dart';

String host = Config.host;
Future<void> main() async {
  // 基本配置
  final dyLib = DyLib.getDyLibFromCargo();
  final rustLib = AleoProgram(dyLib, "mainnet");
  final rustRecordLib = AleoRecord(dyLib, "mainnet");
  // final wss = Config.socket + '/wallet/aleo/upgrade';
  final wss = 'wss://aleo.fxwallet.com/wallet/aleo/upgrade';
  final nodeUrl = Config.nodeUrl;
  final private_key = Config.privateKey;
  final view_key = Config.viewKey;

  // 交易类型, 只有最基本的那几种类型, 节点质押只支持public
  final transfer_type = TransferMethod.public;

  final publicRecord =
      'record1qyqsq8nktvwx2tq3ys4mmfclqexs89xv9uvstx7e5ndkevk4ayfqefsqqyxx66trwfhkxun9v35hguerqqpqzqqyuvhywm8dwg3c4l7t2pzd9mcv52ga54a8cns034vcncc2mf7upycqj68vqmwhvze0wc8yr3khunjnhszlyaavypvgy7wwlqsala9syctqjej';

  // 解析record
  // record1qyqsq8nktvwx2tq3ys4mmfclqexs89xv9uvstx7e5ndkevk4ayfqefsqqyxx66trwfhkxun9v35hguerqqpqzqqyuvhywm8dwg3c4l7t2pzd9mcv52ga54a8cns034vcncc2mf7upycqj68vqmwhvze0wc8yr3khunjnhszlyaavypvgy7wwlqsala9syctqjej
  // 685640431604231063444970805268472233140731435211848949355942532669597254133field
  // at1zqryps9nrxpq2d7ryj09x3yyg09xkjag0rhcsyjt87f5chzljgrqztg5vg
  

  final recordData = rustRecordLib.decryptCipherText(publicRecord, view_key);

  if (recordData.getVersion() == '0u8') {
    // 需要升级，升级后为 1u8
    print('record need upgrade');
    // 没被使用过
    final number = rustRecordLib.serialNumberString(publicRecord, private_key);
    print(number);
  }

  /// 公开交易解析， public方为该地址的所有交易，通过viewkey筛掉，确保与隐私交易不重复。
  final List<dynamic> pubTxsJson = json.decode(
      new File('./test/data/tx_upgrade.json').readAsStringSync(encoding: utf8));

  final transactions = pubTxsJson;
  /************************************/
  final TxsResult result = TxsResult(
      recordFFI: rustRecordLib,
      recordCipherTexts: [publicRecord],
      viewKey: view_key,
      address: Config.address);

  result.getOutputTxs(transactions, private_key);
  result.getInputTxs([], private_key);
  for (final tx in result.txs) {
    print(tx.toJson());
  }

  final authorization = await rustLib.upgradeAuthorization(
    private_key,
    publicRecord,
    nodeUrl,
  );

  final channel = IOWebSocketChannel.connect(wss);

  channel.sink.add(json.encode({
    'transfer_type': transfer_type,
    'method': 'amount',
    'authorization': authorization
  }));

  channel.stream.listen((data) async {
    final String message = data.toString();
    if (message.contains('tx_success')) {
      print(message);
      channel.sink.close();
    }
  });
}
