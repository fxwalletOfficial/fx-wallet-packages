import 'dart:convert';
import 'dart:io';

import 'package:crypto_wallet_util/transaction.dart';
import 'package:test/test.dart';

void main() {
  late ScUnsignedTransaction unsignedTx;
  late ScWasmIsolateBridge bridge;

  setUpAll(() {
    final unsignedJson =
        json.decode(
              File(
                './test/transaction/data/sc_unsigned.json',
              ).readAsStringSync(encoding: utf8),
            )
            as Map<String, dynamic>;
    unsignedTx = ScUnsignedTransaction.fromJson(unsignedJson);
    bridge = ScWasmIsolateBridge(
      File('./lib/src/transaction/sc/sc.wasm').readAsBytesSync(),
    );
  });

  tearDownAll(() => bridge.dispose());

  test('computes the SC digest in the background worker', () async {
    final result = await bridge.processUnsignedTransaction(unsignedTx);

    expect(result.toSign, [
      'c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d',
    ]);
  });

  test('reuses the worker for concurrent requests', () async {
    final results = await Future.wait([
      bridge.processUnsignedTransaction(unsignedTx),
      bridge.processUnsignedTransaction(unsignedTx),
    ]);

    expect(results, hasLength(2));
    expect(results[0].toSign, results[1].toSign);
  });

  test('the default builder uses the background bridge', () async {
    final builder = await ScTransactionBuilder.create();
    addTearDown(builder.dispose);

    expect(builder.wasmBridge, isA<ScWasmIsolateBridge>());
  });
}
