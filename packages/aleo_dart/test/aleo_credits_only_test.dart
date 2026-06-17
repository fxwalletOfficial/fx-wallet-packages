import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

import 'support/test_dylib.dart';

/// v1 is credits-only. The public program flows must reject a non-`credits.aleo`
/// program **deterministically and before any node I/O** — so an unreachable /
/// 404 / slow / malicious node can never turn the rejection into an
/// `AleoNodeException`. These tests point the program at a loopback server that
/// counts every request and assert: `unsupported_feature` is thrown and the server
/// is never hit.
void main() {
  final dyLib = tryLoadAleoLib();

  late HttpServer server;
  late int requests;
  late String url;
  late AleoProgram program;

  setUp(() async {
    requests = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) {
      requests++;
      req.response.statusCode = 500;
      req.response.close();
    });
    url = 'http://${server.address.host}:${server.port}';
    if (dyLib != null) program = AleoProgram(dyLib, 'testnet');
  });

  tearDown(() async {
    if (dyLib != null) program.dispose();
    await server.close(force: true);
  });

  final unsupported = throwsA(isA<ProvisioningException>()
      .having((e) => e.code, 'code', 'unsupported_feature'));

  test('executeProgramProof rejects a custom program before any node request',
      () async {
    if (dyLib == null) {
      markTestSkipped(nativeLibMissingReason);
      return;
    }
    await expectLater(
      program.executeProgramProof(url, '{}', program_id_raw: 'custom.aleo'),
      unsupported,
    );
    expect(requests, 0, reason: 'must reject before reaching the node');
  });

  test('executeProgram rejects a custom program before any node request',
      () async {
    if (dyLib == null) {
      markTestSkipped(nativeLibMissingReason);
      return;
    }
    await expectLater(
      program.executeProgram(
          'APrivateKey1zkp', 'custom.aleo', 'foo', '[]', 1, url),
      unsupported,
    );
    expect(requests, 0, reason: 'must reject before reaching the node');
  });

  test('contractExecution rejects a custom program before any node request',
      () async {
    if (dyLib == null) {
      markTestSkipped(nativeLibMissingReason);
      return;
    }
    await expectLater(
      program.contractExecution(
          'APrivateKey1zkp', 'custom.aleo', 'foo', '[]', url),
      unsupported,
    );
    expect(requests, 0, reason: 'must reject before reaching the node');
  });

  test('contractFeeExecution rejects a custom program before any node request',
      () async {
    if (dyLib == null) {
      markTestSkipped(nativeLibMissingReason);
      return;
    }
    await expectLater(
      program.contractFeeExecution(
          'APrivateKey1zkp', 1, '{}', 'custom.aleo', url),
      unsupported,
    );
    expect(requests, 0, reason: 'must reject before reaching the node');
  });
}
