import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import 'package:aleo_dart/aleo.dart';

Future<void> main() async {
  // 基本配置
  final String libPosition = 'aleo_rust/target/release/libaleo_rust.so';
  final dyLib = DyLib.getDyLibByPosition(libPosition);
  final rustLib = AleoProgram(dyLib, "mainnet");
  final wss = 'ws://localhost:31551/wallet/aleo/execute';
  final url = '';
  final private_key = '';

  // 交易类型 token转账都使用public
  final transfer_type = TransferMethod.public;

  // 交易程序id, 后续在token info中获取
  final program_id = 'betastaking.aleo';
  // 调用token转账方法
  final function =  TransferMethod.public;

  // 交易优先费
  final fee_credits = 0;

  // 收款地址与转账数量
  final recipient = '';
  final amount = '100000u64';

  // 交易参数 最终需转换为字符串 arguments 处理可以放在服务端。
  final arguments = [recipient, amount];

  final authorizationJson = await rustLib.contractExecution(
    private_key,
    program_id,
    function,
    arguments.join(','),
    url,
  );

  final channel = IOWebSocketChannel.connect(wss);

  channel.sink.add(json.encode({
    'transfer_type': transfer_type,
    'method': 'amount',
    'authorization': authorizationJson,
    'program_id': program_id,
  }));

  channel.stream.listen((data) async {
    final String message = data.toString();
    if (message.contains('proof1')) {
      final feeAuthorization = await rustLib.contractFeeExecution(
          private_key, fee_credits, message, program_id, url);

      channel.sink.add(jsonEncode({
        'transfer_type': transfer_type,
        'method': 'fee',
        'authorization': feeAuthorization,
      }));
    } else if (message.contains('tx_success')) {
      print(message);
      channel.sink.close();
    }
  });
}
