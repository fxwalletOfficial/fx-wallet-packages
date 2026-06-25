import 'dart:convert';
import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

import 'support/test_dylib.dart';

/// On-device proving is credits-only: [AleoProgram.executeProgram] /
/// [AleoProgram.executeProgramProof] must reject a non-`credits.aleo` program
/// **deterministically and before any node I/O** — so an unreachable / 404 / slow
/// / malicious node can never turn the rejection into an `AleoNodeException`.
/// These tests point the program at a loopback server that counts every request
/// and assert `unsupported_feature` is thrown and the server is never hit.
///
/// The authorize-only contract paths ([AleoProgram.contractExecution] /
/// [AleoProgram.contractFeeExecution]) are NOT credits-only — they delegate
/// proving to the server, so they accept any program and resolve its closure from
/// the node (verified below).
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

  // The authorize-only contract paths are NOT credits-gated: for a custom program
  // they now resolve its closure from the node (then authorize). The loopback
  // server 500s, so the closure fetch fails — but the point is it REACHES the node
  // (request count > 0) rather than rejecting with `unsupported_feature` first.
  test('contractExecution fetches a custom program closure from the node '
      '(no longer credits-gated)', () async {
    if (dyLib == null) {
      markTestSkipped(nativeLibMissingReason);
      return;
    }
    await expectLater(
      program.contractExecution(
          'APrivateKey1zkp', 'custom.aleo', 'foo', '[]', url),
      throwsA(anything),
    );
    expect(requests, greaterThan(0),
        reason: 'authorize path resolves the program closure from the node');
  });

  test('contractFeeExecution fetches a custom program closure from the node '
      '(no longer credits-gated)', () async {
    if (dyLib == null) {
      markTestSkipped(nativeLibMissingReason);
      return;
    }
    await expectLater(
      program.contractFeeExecution(
          'APrivateKey1zkp', 1, '{}', 'custom.aleo', url),
      throwsA(anything),
    );
    expect(requests, greaterThan(0),
        reason: 'authorize path resolves the program closure from the node');
  });

  // Positive: credits.aleo is built in (empty closure, no node fetch), so
  // contractExecution returns the AUTHORIZATION (not an on-device proof) — the
  // shape the wallet sends to its prove server.
  test('contractExecution returns a credits.aleo authorization without node I/O',
      () async {
    if (dyLib == null) {
      markTestSkipped(nativeLibMissingReason);
      return;
    }
    const privateKey =
        'APrivateKey1zkpC2CbihCvUyg8zcNXTngzGpmCzKTF8uZP4jfyu3LdfT8v';
    final recipient = AleoAccount(dyLib).privateKeyToAddress(privateKey);
    final auth = await program.contractExecution(
      privateKey,
      'credits.aleo',
      'transfer_public',
      '["$recipient", "1000000u64"]',
      url,
    );
    expect(auth, isNotEmpty);
    final decoded = json.decode(auth) as Map<String, dynamic>;
    expect(decoded, contains('requests'));
    expect(decoded, contains('transitions'));
    expect(requests, 0,
        reason: 'credits.aleo is built in — no node fetch for its empty closure');
  });
}
