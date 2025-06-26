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

  // 交易类型, 只有最基本的那几种类型, 合约只支持public
  final transfer_type = TransferMethod.public;

  // 交易程序id, 流动性质押目前只支持 betastaking.aleo
  final program_id = 'betastaking.aleo';
  // 调用合约方法
  // 质押方法
  final function = ContractMethod.stake;
  // 赎回方法
  // final function = ContractMethod.withdraw;
  // claim方法
  // final function = ContractMethod.claim;

  // 交易优先费
  final fee_credits = 0;

  // 设置质押金额，与用户地址
  final address = Config.address;
  final amount = '1000000';

  // // 交易参数 最终需转换为字符串 arguments 处理可以放在服务端。
  // final arguments = [recipient, amount];
  // 调用服务端接口，获取交易参数。
  final response = await getArgumentsAndFunction(program_id, function, {
    'address': address,
    'amount': amount,
  });

  final arguments = response['args'];
  final function_name = response['function'];

  // 以下是固定流程
  final authorizationJson = await rustLib.contractExecution(
    private_key,
    program_id,
    function_name!,
    arguments!,
    nodeUrl,
  );

  final channel = IOWebSocketChannel.connect(wss);

  channel.sink.add(json.encode({
    'transfer_type': transfer_type,
    'method': 'amount',
    'authorization':
        rustLib.modifyAuthorization(authorizationJson), // 需要调整参数的顺序
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
Future<Map<String, String>> getArgumentsAndFunction(
    String programId, String function, Map<String, String> arguments) async {
  final dio = Dio(BaseOptions());
  final uri = '/arguments';

  try {
    final response = await dio.post(host + uri, data: {
      'program_id': programId,
      'function_name_raw': function,
      'args': arguments,
    });
    if (response.statusCode == 200) {
      return {
        'args': response.data["data"]["args"],
        'function': response.data["data"]["function_name"]
      };
    }
    return {
      'args': '',
      'function': '',
    };
  } catch (e) {
    print(e);
    return {
      'args': '',
      'function': '',
    };
  }
}
