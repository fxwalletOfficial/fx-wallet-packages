import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import 'package:aleo_dart/aleo.dart';

Future<void> main() async {
  final String libPosition = 'aleo_rust/target/release/libaleo_rust.so';
  final dyLib = DyLib.getDyLibByPosition(libPosition);
// final dyLib = DyLib.getDyLibFromCargo();
  final rustLib = AleoProgram(dyLib);

  final wss = 'ws://aleo.fxwallet.com/wallet/aleo/delegate';
  // final wss = 'wss://api.fxwallet.in/wallet/aleo/record';

  final url = 'https://api.explorer.aleo.org/v1';

  final private_key =
      'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  final recipient =
      'aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn';
  final amount_credits = 1000000;
  final fee_credits = 100000;
  final transfer_type = 'transfer_private';
  final amount_record = '';

  final authorization = await rustLib.executionAuthorization(
    private_key,
    recipient,
    transfer_type,
    amount_credits,
    url,
    amount_record,
  );
  final channel = IOWebSocketChannel.connect(wss);

  channel.sink.add(json.encode({
    'transfer_type': transfer_type,
    'method': 'amount',
    'authorization': authorization
  }));

  channel.stream.listen((data) async {
    print(data);
    final String message = data.toString();
    if (message.contains('proof1')) {
      final feeAuthorization = await rustLib.executionFeeAuthorization(
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
