import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

import 'support/test_dylib.dart';

// Deterministic transaction assembly (split-proof). Fixtures captured from a
// real testnet transfer_public (tx at1klzfwh6fp5cpq9k4mh46yz7mk2wcs3gk...).
void main() {
  final dyLib = tryLoadAleoLib();
  if (dyLib == null) {
    test('build_transaction_offline', () {}, skip: nativeLibMissingReason);
    return;
  }
  final program = AleoProgram(dyLib, 'testnet');

  test('build_transaction_offline reproduces the reference transaction', () async {
    const dir = 'test/fixtures/g3';
    final execution = File('$dir/execution.json').readAsStringSync();
    final fee = File('$dir/fee.json').readAsStringSync();
    final expected = File('$dir/transaction.json').readAsStringSync();
    expect(await program.buildTransactionOffline(execution, fee), expected);
  });
}
