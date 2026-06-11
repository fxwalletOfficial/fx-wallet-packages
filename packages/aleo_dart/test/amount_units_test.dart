// Guards the transfer amount/fee unit contract: the FFI integer is passed
// straight through to credits.aleo as microcredits (`{amount}u64`), with no
// credits->microcredits scaling. This matches the reference implementation and
// the caller is responsible for supplying microcredits.
//
// Run against a built library:
//   ALEO_NEW_LIB=/abs/path/libaleo_rust.dylib flutter test test/amount_units_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

void main() {
  final libPath = Platform.environment['ALEO_NEW_LIB'];
  if (libPath == null) {
    test('amount units', () {},
        skip: 'set ALEO_NEW_LIB to a libaleo_rust build');
    return;
  }

  final dy = DyLib.getDyLibByPosition(libPath);
  final program = AleoProgram(dy);
  final account = AleoAccount(dy);
  const privateKey =
      'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
  final recipient = account.privateKeyToAddress(privateKey);

  test('transfer amount is encoded as microcredits without scaling', () async {
    for (final amount in <int>[1, 5, 1000000, 2000000000]) {
      final auth = await program.executionAuthorization(
          privateKey, recipient, 'transfer_public', amount, '', '');
      expect(auth, isNotEmpty);
      final inputs =
          (json.decode(auth)['requests'] as List).first['inputs'] as List;
      expect(inputs, contains('${amount}u64'),
          reason: 'amount $amount should pass through as ${amount}u64');
    }
  });
}
