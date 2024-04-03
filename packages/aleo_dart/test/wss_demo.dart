import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import 'package:aleo_dart/aleo.dart';

void main() {
  final String libPosition = 'aleo_rust/target/debug/libaleo_rust.so';
  final dyLib = DyLib.getDyLibByPosition(libPosition);
// final dyLib = DyLib.getDyLibFromCargo();
  final rustLib = AleoProgram(dyLib);

  final wss = 'ws://127.0.0.1:14042/wallet/aleo/delegate';
  // final wss = 'wss://api.fxwallet.in/wallet/aleo/delegate';

  final url = 'http://23.20.9.85:3033';

  final private_key =
      'APrivateKey1zkp8CZNn3yeCseEtxuVPbDCwSyhGW6yZKUYKfgXmcpoGPWH';
  final recipient =
      'aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn';
  final amount_credits = 10000000;
  final fee_credits = 1000000;
  final transfer_type = 'transfer_public';

  final authorization = rustLib.executionAuthorization(
    private_key,
    recipient,
    transfer_type,
    amount_credits,
    url,
    '',
  );
  final channel = IOWebSocketChannel.connect(wss);

  channel.sink.add(json.encode({
    'transfer_type': transfer_type,
    'method': 'amount',
    'authorization': authorization
  }));

  channel.stream.listen((data) {
    final String message = data.toString();
    if (message.contains('proof')) {
      final feeAuthorization = rustLib.executionFeeAuthorization(
          private_key, transfer_type, fee_credits, url, "", message);

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
