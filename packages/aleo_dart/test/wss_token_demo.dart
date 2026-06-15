import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:dio/dio.dart';

import 'package:aleo_dart/aleo.dart';
import './local/config.dart';

String host = Config.host;
Future<void> main() async {
  // 基本配置
  final dyLib = DyLib.getDyLibFromCargo();
  final rustLib = AleoProgram(dyLib, "mainnet");
  final wss = Config.socket + '/wallet/aleo/execute';
  final nodeUrl = Config.nodeUrl;
  final private_key = Config.privateKey;

  // 交易类型 token转账都使用public
  final transfer_type = TransferMethod.public;

  // 交易程序id, 后续在token info中获取
  final program_id = 'betastaking.aleo';
  // 调用token转账方法
  final function = TransferMethod.public;

  // 交易优先费
  final fee_credits = 0;

  // 收款地址与转账数量
  final recipient = Config.recipient;
  final amount = '100000';

  // // 交易参数 最终需转换为字符串 arguments 处理可以放在服务端。
  // final arguments = [recipient, amount];
  // 调用服务端接口，获取交易参数。
  final arguments = await getArguments(program_id, function, {
    'address': recipient,
    'amount': amount,
  });

  final authorizationJson = await rustLib.contractExecution(
    private_key,
    program_id,
    function,
    arguments,
    nodeUrl,
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
          private_key, fee_credits, message, program_id, nodeUrl);

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

/// 调用服务端接口，获取交易参数。
Future<String> getArguments(
    String programId, String function, Map<String, String> arguments) async {
  final dio = Dio(BaseOptions());
  final uri = '/arguments';

  try {
    final response = await dio.post(host + uri, data: {
      'program_id': programId,
      'function_name': function,
      'args': arguments,
    });

    if (response.statusCode == 200) {
      return response.data['args'];
    }
    return '';
  } catch (e) {
    print(e);
    return '';
  }
}
