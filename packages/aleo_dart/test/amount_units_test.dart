// Guards the transfer amount/fee unit contract: the FFI integer is passed
// straight through to credits.aleo as microcredits (`{amount}u64`), with no
// credits->microcredits scaling. This matches the reference implementation and
// the caller is responsible for supplying microcredits.
//
// Run against a built library:
//   ALEO_NEW_LIB=/abs/path/libaleo_rust.dylib dart test test/amount_units_test.dart
import 'dart:convert';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

import 'support/test_dylib.dart';

void main() {
  final dy = tryLoadAleoLib();
  if (dy == null) {
    test('amount units', () {}, skip: nativeLibMissingReason);
    return;
  }

  final program = AleoProgram(dy);
  final account = AleoAccount(dy);
  const privateKey =
      'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  final recipient = account.privateKeyToAddress(privateKey);

  test('transfer amount is encoded as microcredits without scaling', () async {
    // Includes values past i32 (2^31, 2^32) and the total-supply order of
    // magnitude (10^15): the ABI is u64 end to end, so none may truncate.
    for (final amount in <int>[
      1,
      5,
      1000000,
      2000000000,
      2147483648,
      4294967296,
      1000000000000000,
    ]) {
      final auth = await program.executionAuthorization(
          privateKey, recipient, 'transfer_public', amount, '', '');
      expect(auth, isNotEmpty);
      final inputs =
          (json.decode(auth)['requests'] as List).first['inputs'] as List;
      expect(inputs, contains('${amount}u64'),
          reason: 'amount $amount should pass through as ${amount}u64');
    }
  });

  test('negative amounts and fees are rejected before reaching the FFI', () {
    // A negative Dart int would wrap to an enormous u64 across the ABI.
    expect(
        () => program.executionAuthorization(
            privateKey, recipient, 'transfer_public', -1, '', ''),
        throwsException);
    expect(
        () => program.executionFeeAuthorization(
            privateKey, 'transfer_public', -1, '', '', '{}'),
        throwsException);
  });
}
