import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import 'package:aleo_dart/aleo.dart';

Future<void> main() async {
  final String libPosition = 'aleo_rust/target/release/libaleo_rust.so';
  final dyLib = DyLib.getDyLibByPosition(libPosition);
  final rustLib = AleoProgram(dyLib, "mainnet");

  final wss = 'ws://localhost:31551/wallet/aleo/execute';

  final url = '';

  final private_key = '';
  final recipient = '';
  final transfer_type = TransferMethod.public;
  final fee_credits = 0;

  final program_id = 'betastaking.aleo';
  final function = TransferMethod.public;
  final amount = '100000u64';

  final argments = [recipient, amount];

  final authorizationJson = await rustLib.contractExecution(
    private_key,
    program_id,
    function,
    argments.join(','),
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

  // final data = {"request": [], "transitions": []};
  // final transitions = authorization['transitions'];
  // for (var request in authorization['requests']) {
  //   final pragma = request['pragma'];
  //   final function = request['function'];
  //   for (var transition in transitions) {
  //     if (transition['pragma'] == pragma &&
  //         transition['function'] == function) {
  //       data['transitions']!.add(transition);
  //       data['request']!.add(request);
  //     }
  //   }
  // }
  // print(data);
}
