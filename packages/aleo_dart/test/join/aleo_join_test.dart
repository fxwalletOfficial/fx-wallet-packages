import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

final String libPosition = 'aleo_rust/target/debug/libaleo_rust.so';
final dyLib = DyLib.getDyLibByPosition(libPosition);
// final dyLib = DyLib.getDyLibFromCargo();
final rust = AleoProgram(dyLib);

final amount_record = '';
final fee_record = '';
void main() async {
  final url = 'https://api.explorer.aleo.org/v1';
  // final url = 'http://23.20.9.85:3033';

  test('try join', () async {
    final private_key =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final record_1 =
        "record1qyqsqcalak0kj0nhyc04xr87s8ezlumx9reun2cs4fpsluxtepz6trqgqyxx66trwfhkxun9v35hguerqqpqzqy8d5j3yz6a5twm7jckw5xqpwht7wnxjr6leka78gsupzyejjq2qxn6ttq0qk3p8xqaxhkn0ueungjqz5yez7dj685spzuj8490ce83q8h7w36";
    final record_2 =
        "record1qyqsqnedgjem68e04226v2y755mecs4cl8sd3st8zjxnue2uus698gg2qyxx66trwfhkxun9v35hguerqqpqzqxasc87h5l6hk53423u4eh0lg9nzm5j0h9dp9r3maz5xc0hr0x3q2dg85wl9jv3p6ja86wj7frlus78k8ysnh25zzuykqa7vx5s3efqqzxgjep";

    final fee_credits = 10000;

    final tx = await rust.tryJoin(
        private_key, record_1, record_2, fee_credits, fee_record, url);

    print(tx);
  });
}
