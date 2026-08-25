import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void run() {
  test('loads the package asset from a consuming Flutter app', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final packageRoot = Directory.current;
    final unsignedJson = json.decode(
      File('test/transaction/data/sc_unsigned.json').readAsStringSync(),
    );
    final fixtureDirectory = await Directory.systemTemp.createTemp(
      'crypto_wallet_util_sc_consumer_fixture_',
    );
    addTearDown(() => fixtureDirectory.delete(recursive: true));

    await File('${fixtureDirectory.path}/pubspec.yaml').writeAsString('''
name: sc_asset_consumer_fixture
publish_to: none

environment:
  sdk: '>=3.11.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  crypto_wallet_util:
    path: ${jsonEncode(packageRoot.path)}

dev_dependencies:
  flutter_test:
    sdk: flutter
''');
    await Directory('${fixtureDirectory.path}/test').create();
    await File('${fixtureDirectory.path}/test/asset_test.dart').writeAsString(
      """
import 'dart:convert';

import 'package:crypto_wallet_util/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds without a source-relative WASM file or custom loader', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final unsignedTx = ScUnsignedTransaction.fromJson(
      jsonDecode(r'''${jsonEncode(unsignedJson)}''')
          as Map<String, dynamic>,
    );
    final builder = await ScTransactionBuilder.create();
    final result = await builder.build(unsignedTx);

    expect(result.toSign, [
      'c191c3f2478833e66eb8911038f7fbe4f1810ec16cb3f0628c0ccfe7a4bc2f4d',
    ]);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
""",
    );

    final pubGet = await Process.run('flutter', [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: fixtureDirectory.path);
    expect(
      pubGet.exitCode,
      0,
      reason: 'flutter pub get failed:\n${pubGet.stdout}\n${pubGet.stderr}',
    );

    final testResult = await Process.run('flutter', [
      'test',
      '--no-pub',
    ], workingDirectory: fixtureDirectory.path);
    expect(
      testResult.exitCode,
      0,
      reason:
          'consumer Flutter test failed:\n'
          '${testResult.stdout}\n${testResult.stderr}',
    );
  });
}
