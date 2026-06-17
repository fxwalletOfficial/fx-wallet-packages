import 'dart:convert';
import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'support/test_dylib.dart';

/// Serves the given path→bytes map on loopback. A path mapped to `null` 404s.
Future<HttpServer> serveBytes(Map<String, List<int>?> routes) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) async {
    final body = routes[req.uri.path];
    if (body == null) {
      req.response.statusCode = 404;
    } else {
      req.response.add(body);
    }
    await req.response.close();
  });
  return server;
}

MissingParam missingFor(
    String dir, String relPath, List<int> body, List<String> urls,
    {String reason = 'absent'}) {
  return MissingParam(
    function: 'test',
    relativePath: relPath,
    urls: urls,
    size: body.length,
    checksum: sha256.convert(body).toString(),
    reason: reason,
  );
}

void main() {
  final dyLib = tryLoadAleoLib();

  // ── Pure-Dart: envelope parser + latch (no FFI dir, no network) ─────────────
  // (Still needs the library handle to construct the provisioner.)
  group('envelope + latch', () {
    setUp(ParameterProvisioner.resetLatchForTest);
    tearDown(ParameterProvisioner.resetLatchForTest);

    test('parses ok / throws on errors / trips latch on restart_required', () {
      if (dyLib == null) return;
      final pv = ParameterProvisioner(dyLib, 'mainnet', Directory.systemTemp);

      expect(pv.parseEnvelopeForTest('{"ok":true,"data":"x"}')['data'], 'x');

      expect(() => pv.parseEnvelopeForTest('not json'),
          throwsA(isA<ProvisioningException>()));
      expect(
          () => pv.parseEnvelopeForTest(
              '{"ok":false,"code":"invalid_input","message":"m"}'),
          throwsA(isA<ProvisioningException>()));

      expect(ParameterProvisioner.provingDisabled, isFalse);
      expect(
          () => pv.parseEnvelopeForTest(
              '{"ok":false,"code":"restart_required","message":"m"}'),
          throwsA(isA<ProvingDisabledException>()));
      expect(ParameterProvisioner.provingDisabled, isTrue);
    });

    test(
        'provisionAndProveProgram checks the latch before the custom-closure check',
        () async {
      if (dyLib == null) return;
      final pv = ParameterProvisioner(dyLib, 'mainnet', Directory.systemTemp);
      // Poison the process.
      try {
        pv.parseEnvelopeForTest(
            '{"ok":false,"code":"restart_required","message":"m"}');
      } catch (_) {}
      expect(ParameterProvisioner.provingDisabled, isTrue);
      // A custom-program call now fail-fasts as ProvingDisabledException (Contract 3
      // — latch first), NOT unsupported_feature.
      await expectLater(
        pv.provisionAndProveProgram(
          authorization: '{}',
          programSources:
              '[{"id":"foo.aleo","edition":0,"source":"program foo.aleo;"}]',
          height: 17000000,
          consensusVersion: 13,
        ),
        throwsA(isA<ProvingDisabledException>()),
      );
    });
  }, skip: dyLib == null ? nativeLibMissingReason : null);

  // ── Downloader + single-flight (local server, no FFI dir set) ───────────────
  group('downloader', () {
    test('downloads, verifies size+checksum, atomic-renames into place',
        () async {
      if (dyLib == null) return;
      final dir = Directory.systemTemp.createTempSync('aleo_pv_dl_');
      final body = utf8.encode('a-fake-proving-key-${DateTime.now()}');
      final server = await serveBytes({'/k.prover': body});
      final port = server.port;
      try {
        final pv = ParameterProvisioner(dyLib, 'mainnet', dir);
        final param = missingFor(dir.path, 'resources/k.prover.abc1234', body,
            ['http://127.0.0.1:$port/k.prover']);
        await pv.provisionFileForTest(param);
        final target = File(p.join(dir.path, 'resources/k.prover.abc1234'));
        expect(target.existsSync(), isTrue);
        expect(target.readAsBytesSync(), body);
        // No leftover tmp.
        expect(Directory(p.join(dir.path, 'resources')).listSync().length, 1);
      } finally {
        await server.close(force: true);
        dir.deleteSync(recursive: true);
      }
    });

    test('falls back to the second url', () async {
      if (dyLib == null) return;
      final dir = Directory.systemTemp.createTempSync('aleo_pv_fb_');
      final body = utf8.encode('mirror-body');
      final server = await serveBytes({'/good': body}); // '/bad' 404s
      final port = server.port;
      try {
        final pv = ParameterProvisioner(dyLib, 'mainnet', dir);
        final param = missingFor(dir.path, 'resources/k.prover.def5678', body,
            ['http://127.0.0.1:$port/bad', 'http://127.0.0.1:$port/good']);
        await pv.provisionFileForTest(param);
        expect(
            File(p.join(dir.path, 'resources/k.prover.def5678')).existsSync(),
            isTrue);
      } finally {
        await server.close(force: true);
        dir.deleteSync(recursive: true);
      }
    });

    test('a corrupt primary url falls back to the verified mirror', () async {
      if (dyLib == null) return;
      final dir = Directory.systemTemp.createTempSync('aleo_pv_corrupt_');
      final good = utf8.encode('the-correct-proving-key');
      // Primary serves WRONG bytes (HTTP 200), mirror serves the correct body.
      final server = await serveBytes({
        '/primary': utf8.encode('corrupt-stale-body'),
        '/mirror': good,
      });
      final port = server.port;
      try {
        final pv = ParameterProvisioner(dyLib, 'mainnet', dir);
        final param = missingFor(dir.path, 'resources/k.prover.cor', good, [
          'http://127.0.0.1:$port/primary',
          'http://127.0.0.1:$port/mirror'
        ]);
        await pv.provisionFileForTest(param);
        final target = File(p.join(dir.path, 'resources/k.prover.cor'));
        expect(target.existsSync(), isTrue);
        expect(target.readAsBytesSync(), good);
      } finally {
        await server.close(force: true);
        dir.deleteSync(recursive: true);
      }
    });

    test('rejects a wrong-checksum body (verification), leaves no file',
        () async {
      if (dyLib == null) return;
      final dir = Directory.systemTemp.createTempSync('aleo_pv_bad_');
      final body = utf8.encode('actual-body');
      final server = await serveBytes({'/k': body});
      final port = server.port;
      try {
        final pv = ParameterProvisioner(dyLib, 'mainnet', dir);
        // checksum/size declared for DIFFERENT content.
        final param = MissingParam(
          function: 'test',
          relativePath: 'resources/k.prover.bad',
          urls: ['http://127.0.0.1:$port/k'],
          size: body.length,
          checksum: sha256.convert(utf8.encode('something-else')).toString(),
          reason: 'absent',
        );
        await expectLater(pv.provisionFileForTest(param),
            throwsA(isA<ProvisioningException>()));
        expect(File(p.join(dir.path, 'resources/k.prover.bad')).existsSync(),
            isFalse);
      } finally {
        await server.close(force: true);
        dir.deleteSync(recursive: true);
      }
    });

    test('single-flight: a concurrent provision sees the file already present',
        () async {
      if (dyLib == null) return;
      final dir = Directory.systemTemp.createTempSync('aleo_pv_sf_');
      final body = utf8.encode('single-flight-body');
      var hits = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        hits++;
        await Future.delayed(const Duration(milliseconds: 150));
        req.response.add(body);
        await req.response.close();
      });
      final port = server.port;
      try {
        final pv = ParameterProvisioner(dyLib, 'mainnet', dir);
        final param = missingFor(dir.path, 'resources/k.prover.sf', body,
            ['http://127.0.0.1:$port/k']);
        await Future.wait([
          pv.provisionFileForTest(param),
          pv.provisionFileForTest(param),
        ]);
        expect(File(p.join(dir.path, 'resources/k.prover.sf')).existsSync(),
            isTrue);
        // The exclusive single-flight lock serialized them: only one download.
        expect(hits, 1);
      } finally {
        await server.close(force: true);
        dir.deleteSync(recursive: true);
      }
    });
  }, skip: dyLib == null ? nativeLibMissingReason : null);

  // ── preflight (FFI): one shared, set-once, empty param dir ──────────────────
  group('preflight', () {
    // ffi_set_parameter_dir is process-global set-once, so every preflight test
    // shares ONE empty dir; the first call fixes it, the rest are idempotent.
    final shared = Directory.systemTemp.createTempSync('aleo_pv_pf_');

    test('empty dir reports all 16 credits files missing (absent)', () async {
      if (dyLib == null) return;
      final pv = ParameterProvisioner(dyLib, 'mainnet', shared);
      final missing = await pv.preflight(13);
      expect(missing.length, 16);
      expect(missing.every((m) => m.reason == 'absent'), isTrue);
      expect(missing.every((m) => m.urls.length == 2), isTrue);
      expect(missing.map((m) => m.function), contains('transfer_public'));
      expect(missing.map((m) => m.function), contains('inclusion'));
    });

    test('unknown network → ProvisioningException(unsupported_network)',
        () async {
      if (dyLib == null) return;
      final pv = ParameterProvisioner(dyLib, 'bogusnet', shared);
      await expectLater(
        pv.preflight(13),
        throwsA(isA<ProvisioningException>()
            .having((e) => e.code, 'code', 'unsupported_network')),
      );
    });

    test(
        'execute_program_proof_checked binding: custom sources → unsupported_feature',
        () {
      if (dyLib == null) return;
      final pv = ParameterProvisioner(dyLib, 'mainnet', shared);
      // A non-empty closure is rejected up front (before any param load), so the
      // authorization need not be valid — this just exercises the binding typedef.
      final env = jsonDecode(pv.callProgramProofForTest(
        '{}',
        '[{"id":"foo.aleo","edition":0,"source":"program foo.aleo;"}]',
        17000000,
        '',
        '',
      ));
      expect(env['ok'], false);
      expect(env['code'], 'unsupported_feature');
    });

    test('provisionAndProveProgram rejects custom sources BEFORE provisioning',
        () async {
      if (dyLib == null) return;
      final dir = Directory.systemTemp.createTempSync('aleo_pv_prog_');
      try {
        final pv = ParameterProvisioner(dyLib, 'mainnet', dir);
        await expectLater(
          pv.provisionAndProveProgram(
            authorization: '{}',
            programSources:
                '[{"id":"foo.aleo","edition":0,"source":"program foo.aleo;"}]',
            height: 17000000,
            consensusVersion: 13,
          ),
          throwsA(isA<ProvisioningException>()
              .having((e) => e.code, 'code', 'unsupported_feature')),
        );
        // Rejected before any provisioning: the dir was never even touched (no
        // ffi_set_parameter_dir, no preflight, no .locks/resources, no download).
        expect(dir.listSync(), isEmpty);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('consensus outside V8..=V13 → unsupported_consensus', () async {
      if (dyLib == null) return;
      final pv = ParameterProvisioner(dyLib, 'mainnet', shared);
      await expectLater(
        pv.preflight(0),
        throwsA(isA<ProvisioningException>()
            .having((e) => e.code, 'code', 'unsupported_consensus')),
      );
    });
  }, skip: dyLib == null ? nativeLibMissingReason : null);
}
