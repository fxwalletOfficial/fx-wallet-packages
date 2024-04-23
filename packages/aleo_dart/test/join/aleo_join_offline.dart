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
void main() {
  final url = 'https://api.explorer.aleo.org/v1';

  test('join offline', () async {
    final private_key =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';

    final transfer_type =
        TransferMethod.public; // 这里的type 是没用的，但用隐私fee的时候，要填成private
    final record_1 =
        "record1qyqspphwjh9aknd6zvz0r55dmsvm3tmu0kx5kqgy4g0mhgan4g606ec8qyxx66trwfhkxun9v35hguerqqpqzqrczyr8lwkhhu7dxhrmw9pgn9wf2jsy4fwh76l4la4p5sewzpzlql8f2vcm02zwalulqmp3jsamrjv7hzea27nelgyskxvzcuhttv3s78t0e0r";
    final record_2 =
        "record1qyqsp9rc4re2ldtxn4qpcsmpt6j3j6ew2yjhfkyflqu3tzq476gu2ncpqyxx66trwfhkxun9v35hguerqqpqzq9q9uchnt4gg32ls69nr6s9evdcvyj0ychrld2247d3h2g3hnnfqpy9fn2laq85f7d8ydejvadtfxu3afkmsj4apz92d0c8sutp8va3yn6gn0z";

    final fee_credits = 10000;

    final authorization =
        await rust.joinAuthorization(private_key, record_1, record_2, url);
    print(authorization);
    final proof = await rust.executeProof(url, authorization); // in server
    final feeAuthorization = await rust.executionFeeAuthorization(
        private_key, transfer_type, fee_credits, url, fee_record, proof);
    final feeProof =
        await rust.executeFeeProof(url, feeAuthorization); // in server
    final offlineTx = await rust.buildTransactionOffline(proof, feeProof);
    final txHash = await rust.broadcast(offlineTx, url, transfer_type);
    print(txHash);
  });
}
