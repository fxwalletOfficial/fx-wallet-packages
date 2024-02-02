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
final dyLib = DyLib.getDyLib();
final rust = AleoProgram(dyLib);
final record = AleoRecord(dyLib);

final amount_record = 'None';
final fee_record = 'None';
void main() {
  final url = 'http://23.20.9.85:3033';

  // test('try transfer', () {
  // final private_key =
  //     'APrivateKey1zkp8CZNn3yeCseEtxuVPbDCwSyhGW6yZKUYKfgXmcpoGPWH';
  // final recipient =
  //     "aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn";
  // final amount_credits = 10000000;
  // final transfer_type = 'transfer_public_to_private';
  // final fee_credits = 1000000;
  //   final tx = rust.tryTransfer(private_key, recipient, transfer_type,
  //       amount_credits, fee_credits, url, amount_record, fee_record);
  //   print(tx);
  // });

  test('try transfer with record', () {
    final private_key =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final recipient =
        "aleo1rhgdu77hgyqd3xjj8ucu3jj9r2krwz6mnzyd80gncr5fxcwlh5rsvzp9px";
    final amount_credits = 1000000;
    final transfer_type = 'transfer_private';
    final fee_credits = 1000000;

    final amount_record =
        'record1qyqsq6577wyjkw2zr9hvhqlaf5gac6vf8axs8lryx2aptvftwwdapeg0qyxx66trwfhkxun9v35hguerqqpqzq97elky2aks8ggvl3qe4hr55g3rxvq0zy8rt254t8faxh0xnf0yqplhqas5awqx6kmde6aj4nr6hu8ld2rwse6nkhswe0h2c65d6v9s5ftfakh';
    final fee_record =
        'record1qyqsplusr8r4h743l35lcujfmnec5pthdap2u5yeke7cj64vw5zukrgtqyxx66trwfhkxun9v35hguerqqpqzq9vtu0q628zl4fusfp7xjtt7dax77sda49ylfyt5p8wxcpxchasq07h942tnv7lpl6yqm88zsytd38dmglp70f4f955frwep9hhg3eqsn3f0jd';
    // final viewKey_receiver =
    //     'AViewKey1tQY7eCFZhX6wxNDpuTeBoCQEn3KsmmwoY9rUBWhxBdjp';
    // final viewKey_sender =
    //     'AViewKey1mSnpFFC8Mj4fXbK5YiWgZ3mjiV8CxA79bYNa8ymUpTrw';
    // var record_text = record.decryptCipherText(amount_record, viewKey_receiver);
    // print(record_text);
    // record_text = record.decryptCipherText(fee_record, viewKey_receiver);
    // print(record_text);

    final tx = rust.tryTransfer(private_key, recipient, transfer_type,
        amount_credits, fee_credits, url, amount_record, amount_record);
    print(tx);
    // var record_test =
    //     'record1qyqsqnqufpufj5cytf8kzvtf4crux29fn92cua0x6e3zq2nlx7lzz4qjqyxx66trwfhkxun9v35hguerqqpqzqyz524tdzrjl6yncakfxvx5y4w6cm9c93jas0t2cczujzplm59rp70lw36c05znw6trhfjttar525vz35ml3mp96pelqprxetyzypaq29nesjw';
    // print(record.decryptCipherText(record_test, viewKey_receiver));
    // record_test =
    //     'record1qyqsqdpfdu63f2etv8wzt7ffvwyhx9cf6kysumpt96ct8sc33uyq2hcfqyxx66trwfhkxun9v35hguerqqpqzqrdy687fue80d4k8an8geat0cmhka9scgwh2xvcg0rral5atk39q6gwkh0w7y8dk7gc6hh6r9nf4v3ycy4rr4x94vl0lvr699ar7yxscs55j4m';
    // print(record.decryptCipherText(record_test, viewKey_sender));
  });
}
// at1az3gt5rndhgnz4h73hj08gr7hpetg5xp5xg25qjxau4z5eu5aqqsz4uvhp
// at1k066c43pahet2l7x5k5szhzz4dz8mfjteat0ayrc26pz70n47crs7xv3ml