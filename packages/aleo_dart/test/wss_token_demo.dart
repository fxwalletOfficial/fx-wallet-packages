import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:dio/dio.dart';

import 'package:aleo_dart/aleo.dart';
import './local/config.dart';

/// Manual demo: an ARC-21 **token** (non-`credits.aleo`) transfer through the
/// **delegated** prove server, mirroring the wallet's `ProofType.CONTRACT` flow
/// (`isolate_tx.dart`). The device only **authorizes** — `contractExecution`
/// returns the execution authorization and `contractFeeExecution` returns the fee
/// authorization; both are sent over the WebSocket and the server does the
/// proving. So no proving keys are needed on device, and a non-`credits.aleo`
/// `program_id` is fully supported (its source + import closure are fetched from
/// the node by `contractExecution`).
///
/// Needs `test/local/config.dart` (gitignored), a reachable Aleo node, and the
/// prove WebSocket — run by hand, not in CI.

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

  // Authorize-only: builds the token execution authorization on device (fetching
  // betastaking.aleo's source + import closure from the node). Proving is the
  // server's job — we just send this authorization over the socket.
  final authorizationJson = await rustLib.contractExecution(
    private_key,
    program_id,
    function,
    arguments,
    nodeUrl,
  );
  // Normalize to the structure the prove server expects (pair each request with
  // its transition), matching the wallet's isolate_tx CONTRACT path and the other
  // wss_*_demo flows — the server's /wallet/aleo/execute entry expects this shape.
  final authorization = rustLib.modifyAuthorization(authorizationJson);
  // Fail fast locally if it's empty/malformed, instead of sending garbage to the
  // prove server and getting an opaque remote error.
  _requireAuthorization(authorization, 'execution authorization');

  final channel = IOWebSocketChannel.connect(wss);

  channel.sink.add(json.encode({
    'transfer_type': transfer_type,
    'method': 'amount',
    'authorization': authorization,
    'program_id': program_id,
  }));

  channel.stream.listen((data) async {
    final String message = data.toString();
    if (message.contains('proof1')) {
      // The server proved the execution; now authorize the (public) fee over it.
      // Still authorize-only — the server proves the fee too.
      final feeAuthorization = await rustLib.contractFeeExecution(
          private_key, fee_credits, message, program_id, nodeUrl);
      _requireAuthorization(feeAuthorization, 'fee authorization');

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

/// Sanity-checks an authorization before it goes to the prove server: non-empty,
/// valid JSON, and carries the `requests` + `transitions` an Aleo authorization
/// must have. Throws with a clear message otherwise (a malformed/empty value here
/// means the on-device authorize step failed).
void _requireAuthorization(String authorizationJson, String label) {
  if (authorizationJson.isEmpty) {
    throw StateError('$label is empty — on-device authorize failed');
  }
  final Object? decoded = json.decode(authorizationJson);
  if (decoded is! Map ||
      !decoded.containsKey('requests') ||
      !decoded.containsKey('transitions')) {
    throw StateError(
        '$label is not a valid authorization (missing requests/transitions): '
        '$authorizationJson');
  }
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
