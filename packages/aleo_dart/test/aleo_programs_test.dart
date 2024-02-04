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
// final String libPosition = './aleo_rust/libaleo_rust.so';
// final dyLib = DyLib.getDyLibByPosition(libPosition);
final dyLib = DyLib.getDyLibFromCargo();
final rust = AleoProgram(dyLib);

final amount_record = 'None';
final fee_record = 'None';
void main() {
  final url = 'http://23.20.9.85:3033';

  test('try transfer with record', () {
    final private_key =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final recipient =
        "aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px";
    final amount_credits = 1000000;
    final transfer_type = TransferType.public;
    final fee_credits = 1000000;

    final tx = rust.tryTransfer(private_key, recipient, transfer_type,
        amount_credits, fee_credits, url, amount_record, amount_record);
    print(tx);
  });
}
