import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

import '../support/test_dylib.dart';

/// Manual integration demo for `tryJoin` (requires a live node + the native
/// library). Excluded from static analysis; skipped automatically when the
/// native library is unavailable (e.g. on CI).
void main() async {
  final dyLib = tryLoadAleoLib();
  if (dyLib == null) {
    test('aleo_dart join FFI tests', () {}, skip: nativeLibMissingReason);
    return;
  }
  final rust = AleoProgram(dyLib);

  final url = 'https://api.explorer.aleo.org/v1';
  final feeRecord = '';

  test('try join', () async {
    final privateKey =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final record1 =
        'record1qyqsqcalak0kj0nhyc04xr87s8ezlumx9reun2cs4fpsluxtepz6trqgqyxx66trwfhkxun9v35hguerqqpqzqy8d5j3yz6a5twm7jckw5xqpwht7wnxjr6leka78gsupzyejjq2qxn6ttq0qk3p8xqaxhkn0ueungjqz5yez7dj685spzuj8490ce83q8h7w36';
    final record2 =
        'record1qyqsqnedgjem68e04226v2y755mecs4cl8sd3st8zjxnue2uus698gg2qyxx66trwfhkxun9v35hguerqqpqzqxasc87h5l6hk53423u4eh0lg9nzm5j0h9dp9r3maz5xc0hr0x3q2dg85wl9jv3p6ja86wj7frlus78k8ysnh25zzuykqa7vx5s3efqqzxgjep';
    final feeCredits = 10000;

    final tx = await rust.tryJoin(
        privateKey, record1, record2, feeCredits, feeRecord, url);
    print(tx);
  }, skip: 'manual integration test; broadcasts via a live node');
}
