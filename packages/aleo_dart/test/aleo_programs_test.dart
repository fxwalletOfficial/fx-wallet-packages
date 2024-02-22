import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

// const sender = {
//   address: "aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px",
//   path: `m/44'/0'/0'/0'`,
//   view_key: "AViewKey1mSnpFFC8Mj4fXbK5YiWgZ3mjiV8CxA79bYNa8ymUpTrw",
//   private_key: "APrivateKey1zkp8CZNn3yeCseEtxuVPbDCwSyhGW6yZKUYKfgXmcpoGPWH",
// };
// const receiver = {
//   address: "aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn",
//   path: `m/44'/0'/0'/0'`,
//   view_key: "AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp",
//   private_key: "APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v",
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
        "aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn";
    final amount_credits = 100000000;
    final transfer_type = TransferType.public_to_private;
    final fee_credits = 1000000;

    final txHash = rust.tryTransfer(private_key, recipient, transfer_type,
        amount_credits, fee_credits, url, amount_record, amount_record);
    print(txHash);
  });

  test('build transaction', () {
    final private_key =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final recipient =
        "aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px";
    final amount_credits = 1000000;
    final transfer_type = TransferType.private;
    final fee_credits = 1000000;
    final amount_record =
        'record1qyqspdn8f6lh4eum9a36l93mnxh5vcqssjsep9z4lp4vpya2efgmjdsvqyxx66trwfhkxun9v35hguerqqpqzq9yu3tvsnj4x0a7e2w9w204aya09thraeckdlsn59pve6fnnd3eqv0n7jpp5rsxn48jdjj3z55vhmp42f8hxp7vk5d2430vuvk3fzrsx0w9wqw';

    final tx = rust.buildTransaction(private_key, recipient, transfer_type,
        amount_credits, fee_credits, url, amount_record, amount_record);
    print(tx);
    // final txHash = rust.broadcast(tx, url, transfer_type);
    // print(txHash);
  });
  test('downing proving key', () async {
    await rust.downloadProvingKey();
  }, timeout: Timeout(Duration(minutes: 3)));
}
