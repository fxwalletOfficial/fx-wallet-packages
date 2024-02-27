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
// final String libPosition = 'aleo_rust/target/debug/libaleo_rust.so';
// final dyLib = DyLib.getDyLibByPosition(libPosition);
final dyLib = DyLib.getDyLibFromGit();
final rust = AleoProgram(dyLib);

final amount_record = 'None';
final fee_record = 'None';
void main() {
  // final url =  'https://api.explorer.aleo.org/v1';
  final url = 'http://23.20.9.85:3033';

  test('try transfer without record', () {
    final private_key =
        'APrivateKey1zkp8CZNn3yeCseEtxuVPbDCwSyhGW6yZKUYKfgXmcpoGPWH';
    final recipient =
        'aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn';
    final amount_credits = 10000000;
    final transfer_type = TransferMethod.public_to_private;
    final fee_credits = 1000000;

    final tx = rust.buildTransaction(private_key, recipient, transfer_type,
        amount_credits, fee_credits, url, amount_record, amount_record);
    final txJson = json.decode(tx);
    print(txJson['execution']['transitions'][0]['outputs'][0]['value']);
    final txHash = rust.broadcast(tx, url, transfer_type);
    print(txHash);
  });

  test('build transaction', () {
    final private_key =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final recipient =
        'aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px';
    final amount_credits = 1000000;
    final transfer_type = TransferMethod.private;
    final fee_credits = 1000000;
    final amount_record =
        'record1qyqspj8md5yhtk774sum5r5lp0q7ysrz3uljtw98aqj9n9626ga9kqqxqyxx66trwfhkxun9v35hguerqqpqzqrwzmj36tyjlqnnsfk9j29739zusxxccj5ls0cztztp40aguqu9qvuh09t8r9fsjlvmhhcku6wkz7dejcc43yh4rlwf4gk24hwrpgnswcdfanf';
    final fee_record =
        'record1qyqsprkmsytx67gvzffjwgjcrh0dwhutl8yhpzv3jpya44hqcg0futg2qyxx66trwfhkxun9v35hguerqqpqzq8aaxazt5sk6lv7jqewhurxn4fupj2qzx4kjpptdpxnyds3tjx2q654uzaxfuffvcvs7s5cqnektergh4qltgpkp9gnzht5ct7zfkrqqlkppme';
    final tx = rust.buildTransaction(private_key, recipient, transfer_type,
        amount_credits, fee_credits, url, amount_record, fee_record);
    // print(tx);
    final txHash = rust.broadcast(tx, url, transfer_type);
    print(txHash);
  });
  test('downing proving key', () async {
    await rust.downloadProvingKey();
  }, timeout: Timeout(Duration(minutes: 3)));
}