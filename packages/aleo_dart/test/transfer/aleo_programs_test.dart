import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

import '../support/test_dylib.dart';

/// Manual integration demo for transaction building + broadcasting (requires a
/// live node + the native library). Skipped automatically when the native
/// library is unavailable (e.g. on CI), and the broadcasting case is marked
/// `skip` so it never submits a real transaction unattended.
void main() async {
  final dyLib = tryLoadAleoLib();
  if (dyLib == null) {
    test('aleo_dart programs FFI tests', () {}, skip: nativeLibMissingReason);
    return;
  }
  final rust = AleoProgram(dyLib);

  final url = 'https://api.explorer.aleo.org/v1';
  final amountRecord = '';

  test('try transfer without record', () async {
    final privateKey =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final recipient =
        'aleo127c79p7k4jj9e2c8kwwqsn5qkavun07etkyqpr795eyrdnyh3uzqnf8nfn';
    final amountCredits = 1000000;
    final transferType = TransferMethod.public_to_private;
    final feeCredits = 10000;

    final tx = await rust.buildTransaction(privateKey, recipient, transferType,
        amountCredits, feeCredits, url, amountRecord, amountRecord);
    print(tx);
    final txHash = await rust.broadcast(tx, url, transferType);
    print(txHash);
  }, skip: 'manual integration test; broadcasts a real transaction');
}
