import 'dart:convert';
import 'dart:io';

import 'package:crypto_wallet_util/src/transaction/sc/sc_wasm_bridge.dart'
    show loadScWasm;
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

  test(
    'serializes concurrent requests without sharing a persistent worker',
    () async {
      final results = await Future.wait([
        bridge.processUnsignedTransaction(unsignedTx),
        bridge.processUnsignedTransaction(unsignedTx),
      ]);

      expect(results, hasLength(2));
      expect(results[0].toSign, results[1].toSign);
    },
    timeout: Timeout(const Duration(seconds: 90)),
  );

  test('fails closed when every WASM loading path is unavailable', () async {
    var fileChecks = 0;

    await expectLater(
      loadScWasm(
        assetLoader: () async {
          throw StateError('asset bundle unavailable');
        },
        packageUriResolver: (_) async {
          throw UnsupportedError('package URI unavailable');
        },
        fileExists: (_) {
          fileChecks++;
          return false;
        },
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('Cannot locate sc.wasm in the package bundle.'),
            contains('package URI unavailable'),
          ),
        ),
      ),
    );

    expect(fileChecks, 2);
  });

  test(
    'falls back to a relative path when the package URI file read fails',
    () async {
      final wasmBytes = File(
        './lib/src/transaction/sc/sc.wasm',
      ).readAsBytesSync();
      var packageUriReadAttempts = 0;

      final bytes = await loadScWasm(
        assetLoader: () async => null,
        packageUriResolver: (_) async => Uri.file('/nonexistent/sc.wasm'),
        fileExists: (path) => path == 'lib/src/transaction/sc/sc.wasm',
        fileReader: (path) async {
          if (path == '/nonexistent/sc.wasm') {
            packageUriReadAttempts++;
            throw const FileSystemException('no such file');
          }
          return wasmBytes;
        },
      );

      expect(packageUriReadAttempts, 1);
      expect(bytes, wasmBytes);
    },
  );

  test(
    'final fail-closed error retains the package URI read failure',
    () async {
      await expectLater(
        loadScWasm(
          assetLoader: () async => null,
          packageUriResolver: (_) async => Uri.file('/nonexistent/sc.wasm'),
          fileExists: (_) => false,
          fileReader: (_) async =>
              throw const FileSystemException('package URI file missing'),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Cannot locate sc.wasm in the package bundle.'),
              contains('package URI file missing'),
            ),
          ),
        ),
      );
    },
  );

  test('the default builder builds without manual disposal', () async {
    final builder = await ScTransactionBuilder.create();

    expect(builder.wasmBridge, isA<ScWasmIsolateBridge>());
    final result = await builder.build(unsignedTx);
    expect(result.toSign, [
      'c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d',
    ]);
  });

  test(
    'the default builder loads the asset without source-relative paths',
    () async {
      final originalDirectory = Directory.current;
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'crypto_wallet_util_sc_asset_test_',
      );
      addTearDown(() async {
        Directory.current = originalDirectory;
        await temporaryDirectory.delete(recursive: true);
      });
      Directory.current = temporaryDirectory;

      final builder = await ScTransactionBuilder.create();
      final result = await builder.build(unsignedTx);
      expect(result.toSign, [
        'c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d',
      ]);
    },
  );

  test('accepts a caller-provided WASM asset loader', () async {
    var loadCount = 0;
    final builder = await ScTransactionBuilder.create(
      wasmLoader: () async {
        loadCount++;
        return File('./lib/src/transaction/sc/sc.wasm').readAsBytesSync();
      },
    );
    addTearDown(builder.dispose);

    expect(loadCount, 1);
    expect(builder.wasmBridge, isA<ScWasmIsolateBridge>());
  });

  test(
    'disposing a non-owning builder does not dispose a shared bridge',
    () async {
      final sharedBridge = ScWasmIsolateBridge(
        File('./lib/src/transaction/sc/sc.wasm').readAsBytesSync(),
      );
      addTearDown(sharedBridge.dispose);

      final firstBuilder = ScTransactionBuilder(wasmBridge: sharedBridge);
      final secondBuilder = ScTransactionBuilder(wasmBridge: sharedBridge);
      firstBuilder.dispose();

      final result = await secondBuilder.build(unsignedTx);
      expect(result.toSign, [
        'c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d',
      ]);
    },
  );
}
