import 'dart:convert';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

// const sender = {
//   address: 'aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px',
//   path: `m/44'/0'/0'/0'`,
//   view_key: 'AViewKey1mSnpFFC8Mj4fXbK5YiWgZ3mjiV8CxA79bYNa8ymUpTrw',
//   private_key: 'APrivateKey1zkp8CZNn3yeCseEtxuVPbDCwSyhGW6yZKUYKfgXmcpoGPWH',
// };
// const receiver = {
//   address: 'aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn',
//   path: `m/44'/0'/0'/0'`,
//   view_key: 'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp',
//   private_key: 'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v',
// };
final String libPosition = 'aleo_rust/target/release/libaleo_rust.so';
final dyLib = DyLib.getDyLibByPosition(libPosition);
// final dyLib = DyLib.getDyLibFromCargo();
final rust = AleoProgram(dyLib);

final amount_record = '';
final fee_record = '';
void main() async {
  final url = 'https://api.explorer.aleo.org/v1';
  // final url = 'http://23.20.9.85:3033';

  test('try transfer without record', () async {
    final private_key =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final recipient =
        'aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn';
    final amount_credits = 1000000;
    final transfer_type = TransferMethod.public;
    final fee_credits = 1000000;

    final tx = await rust.buildTransaction(
        private_key,
        recipient,
        transfer_type,
        amount_credits,
        fee_credits,
        url,
        amount_record,
        amount_record);
    print(tx);
    // final txJson = json.decode(tx);
    // print(txJson['execution']['transitions'][0]['outputs'][0]['value']);
    final txHash = await rust.broadcast(tx, url, transfer_type);
    print(txHash);
  });

  // test('build transaction', () {
  //   final private_key =
  //       'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  //   final recipient =
  //       'aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px';
  //   final amount_credits = 1000000;
  //   final transfer_type = TransferMethod.private;
  //   final fee_credits = 100000;
  //   final amount_record =
  //       'record1qyqspttl9gdej22xemsrulz589z0szy0munwwl20l5vjc2eg40vyx9qxqyxx66trwfhkxun9v35hguerqqpqzqrcrl9u7daggvd2th8679wzzf557765tzus6fzzxsn7mjea6zt3qs7rtfs8fkywetjm8m2waff8yfmc4v5h2neemv90268surxtan3qjf5pppl';
  //   final fee_record =
  //       'record1qyqspttl9gdej22xemsrulz589z0szy0munwwl20l5vjc2eg40vyx9qxqyxx66trwfhkxun9v35hguerqqpqzqrcrl9u7daggvd2th8679wzzf557765tzus6fzzxsn7mjea6zt3qs7rtfs8fkywetjm8m2waff8yfmc4v5h2neemv90268surxtan3qjf5pppl';
  //   final tx = rust.buildTransaction(private_key, recipient, transfer_type,
  //       amount_credits, fee_credits, url, amount_record, '');
  //   print(tx);
  //   final txHash = rust.broadcast(tx, url, transfer_type);
  //   print(txHash);
  // });
  // test('downing proving key', () async {
  //   await rust.downloadProvingKey();
  // }, timeout: Timeout(Duration(minutes: 3)));
}
