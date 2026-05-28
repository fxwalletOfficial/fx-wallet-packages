import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'package:crypto_wallet_util/src/wallets/sc.dart';
import 'package:crypto_wallet_util/transaction.dart';

void main() async {
  const String mnemonic =
      'what ordinary shop frame olympic dove economy define extra unable oyster emerge';

  final wallet = await SiaCoin.fromMnemonic(mnemonic);
  final wasmBytes = File('./lib/src/transaction/sc/sc.wasm').readAsBytesSync();

  /// Load the same unsigned transaction fixture used in the JS reference
  /// script (`FIXED_UNSIGNED_TX`).
  final unsignedJson = json.decode(
      File('./test/transaction/data/sc_unsigned.json')
          .readAsStringSync(encoding: utf8));
  final unsignedTx = ScUnsignedTransaction.fromJson(unsignedJson);

  group('sc wasm digest', () {
    test('produces the expected digest from FIXED_UNSIGNED_TX', () async {
      final watch = Stopwatch()..start();
      final bridge = ScWasmRunBridge(wasmBytes);
      final result = await bridge.processUnsignedTransaction(unsignedTx);

      // Known value from the JS reference:
      // 3. Generating digests with local sc.wasm
      // [{"index":0,"digestHex":"c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d"}]
      expect(result.toSign.first,
          'c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d');

      bridge.dispose();
      watch.stop();
      print(
          '[sc_test] produces the expected digest from FIXED_UNSIGNED_TX: ${watch.elapsedMilliseconds} ms');
    });
  });

  group('sc sign & verify', () {
    test('signs the WASM digests and verifies', () async {
      final watch = Stopwatch()..start();
      final bridge = ScWasmRunBridge(wasmBytes);
      final builder = ScTransactionBuilder(wasmBridge: bridge);
      final txData = await builder.build(unsignedTx);

      final signer = ScTxSigner(wallet, txData);
      signer.sign();

      expect(signer.verify(), isTrue);

      // Signature is written into satisfiedPolicy.signatures as hex
      final sigs = (txData.transaction['siacoinInputs'] as List)
          .first['satisfiedPolicy']['signatures'] as List;
      expect(sigs.first, isNotEmpty);

      bridge.dispose();
      watch.stop();
      print(
          '[sc_test] signs the WASM digests and verifies: ${watch.elapsedMilliseconds} ms');
    });

    test('throws when siacoinInputs count != toSign count', () async {
      final watch = Stopwatch()..start();
      final bridge = ScWasmRunBridge(wasmBytes);
      final builder = ScTransactionBuilder(wasmBridge: bridge);
      final txData = await builder.build(unsignedTx);
      txData.toSign.add('deadbeef');

      expect(() => ScTxSigner(wallet, txData).sign(), throwsStateError);

      bridge.dispose();
      watch.stop();
      print(
          '[sc_test] throws when siacoinInputs count != toSign count: ${watch.elapsedMilliseconds} ms');
    });
  });
}
