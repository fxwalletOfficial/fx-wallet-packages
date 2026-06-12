import 'dart:convert';
import 'dart:ffi';
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
    File(
      './test/transaction/data/sc_unsigned.json',
    ).readAsStringSync(encoding: utf8),
  );
  final unsignedTx = ScUnsignedTransaction.fromJson(unsignedJson);

  // Known value from the JS reference:
  // 3. Generating digests with local sc.wasm
  // [{"index":0,"digestHex":"c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d"}]
  const expectedDigest =
      'c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d';

  // The native FFI library is not bundled; a macOS/arm64 build is provided as a
  // test fixture only. Run the FFI cases there and skip on other platforms.
  const ffiLibPath = './test/native/libsc_transaction_darwin_arm64.dylib';
  String? ffiSkip;
  if (!Platform.isMacOS) {
    ffiSkip = 'native SC library is only provided for macOS in tests';
  } else if (!File(ffiLibPath).existsSync()) {
    ffiSkip =
        'native SC library not found at $ffiLibPath '
        '(build it with lib/src/forked_lib/sia-wasi/build.sh)';
  }

  // The two bridges must behave identically; run the same suite against each.
  final bridges = <String, Future<ScWasmBridge> Function()>{
    'ScGoFfiBridge': () async => ScGoFfiBridge(DynamicLibrary.open(ffiLibPath)),
    'ScWasmRunBridge': () async => ScWasmRunBridge(wasmBytes),
  };

  for (final entry in bridges.entries) {
    final name = entry.key;
    final makeBridge = entry.value;
    final skip = name == 'ScGoFfiBridge' ? ffiSkip : null;

    group('sc digest [$name]', () {
      test('produces the expected digest from FIXED_UNSIGNED_TX', () async {
        final watch = Stopwatch()..start();
        final bridge = await makeBridge();
        final result = await bridge.processUnsignedTransaction(unsignedTx);

        expect(result.toSign.first, expectedDigest);

        watch.stop();
        print('[sc_test/$name] digest: ${watch.elapsedMilliseconds} ms');
      });
    }, skip: skip);

    group('sc sign & verify [$name]', () {
      test('signs the digests and verifies', () async {
        final watch = Stopwatch()..start();
        final bridge = await makeBridge();
        final builder = ScTransactionBuilder(wasmBridge: bridge);
        final txData = await builder.build(unsignedTx);

        final signer = ScTxSigner(wallet, txData);
        signer.sign();

        expect(signer.verify(), isTrue);

        // Signature is written into satisfiedPolicy.signatures as hex
        final sigs =
            (txData.transaction['siacoinInputs'] as List)
                    .first['satisfiedPolicy']['signatures']
                as List;
        expect(sigs.first, isNotEmpty);

        watch.stop();
        print('[sc_test/$name] sign & verify: ${watch.elapsedMilliseconds} ms');
      });

      test('throws when siacoinInputs count != toSign count', () async {
        final bridge = await makeBridge();
        final builder = ScTransactionBuilder(wasmBridge: bridge);
        final txData = await builder.build(unsignedTx);
        txData.toSign.add('deadbeef');

        expect(() => ScTxSigner(wallet, txData).sign(), throwsStateError);
      });
    }, skip: skip);
  }
}
