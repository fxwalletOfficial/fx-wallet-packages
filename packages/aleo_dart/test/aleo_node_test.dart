import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aleo_dart/aleo.dart';
import 'package:test/test.dart';

/// A scriptable local node: each test installs a handler over the REST routes
/// AleoNode calls, so the whole class is covered offline (no native lib, no real
/// node). Records the requests it saw for assertions (retry counts, broadcast
/// body, header).
class _FakeNode {
  late final HttpServer _server;
  final List<HttpRequest> seen = [];
  late Future<void> Function(HttpRequest req) handler;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((req) async {
      seen.add(req);
      await handler(req);
    });
  }

  String get url => 'http://127.0.0.1:${_server.port}';
  Future<void> stop() => _server.close(force: true);
}

Future<void> _reply(HttpRequest req, String body, {int status = 200}) async {
  req.response.statusCode = status;
  req.response.write(body);
  await req.response.close();
}

void main() {
  late _FakeNode node;

  setUp(() async {
    node = _FakeNode();
    await node.start();
  });

  tearDown(() => node.stop());

  AleoNode aleo({Duration? timeout, List<String> Function(String)? imports}) =>
      AleoNode(node.url,
          network: 'testnet',
          requestTimeout: timeout ?? const Duration(seconds: 5),
          parseImports: imports);

  test('latestHeight parses a bare integer body', () async {
    node.handler = (req) => _reply(req, '123456');
    expect(await aleo().latestHeight(), 123456);
    expect(node.seen.single.uri.path, '/testnet/latest/height');
  });

  test('latestStateRoot strips the surrounding JSON quotes', () async {
    const root = 'sr1dz06ur5spdgzkguh4pr42mvft6u3nwsg5drh9rdja9v8jpcz3czsls9geg';
    node.handler = (req) => _reply(req, '"$root"');
    expect(await aleo().latestStateRoot(), root);
  });

  test('a state root over the byte budget is rejected mid-stream', () async {
    node.handler = (req) => _reply(req, '"${'a' * (AleoNode.maxStateRootBytes + 8)}"');
    await expectLater(aleo().latestStateRoot(),
        throwsA(isA<AleoNodeException>()));
  });

  test('statePaths returns [] for an empty set without hitting the node',
      () async {
    node.handler = (req) => _reply(req, 'should not be called', status: 500);
    expect(await aleo().statePaths(const []), '[]');
    expect(node.seen, isEmpty);
  });

  test('statePaths batches the commitments into one request', () async {
    node.handler = (req) => _reply(req, '[{"x":1},{"x":2}]');
    final body = await aleo().statePaths(['c1', 'c2']);
    expect(jsonDecode(body), hasLength(2));
    expect(node.seen.single.uri.path, '/testnet/statePaths');
    expect(node.seen.single.uri.queryParameters['commitments'], 'c1,c2');
  });

  test('statePaths rejects more entries than the budget', () async {
    final tooMany =
        jsonEncode(List.generate(AleoNode.maxStatePaths + 1, (i) => {'x': i}));
    node.handler = (req) => _reply(req, tooMany);
    await expectLater(
        aleo().statePaths(['c']), throwsA(isA<AleoNodeException>()));
  });

  test('programSource reads latest_edition then the source at that edition',
      () async {
    node.handler = (req) async {
      if (req.uri.path.endsWith('/latest_edition')) {
        await _reply(req, '3');
      } else {
        await _reply(req, jsonEncode('program token.aleo;'));
      }
    };
    final src = await aleo().programSource('token.aleo');
    expect(src.edition, 3);
    expect(src.source, 'program token.aleo;');
    expect(node.seen.map((r) => r.uri.path),
        ['/testnet/program/token.aleo/latest_edition', '/testnet/program/token.aleo/3']);
  });

  test('programSource rejects an oversized program body', () async {
    node.handler = (req) async {
      if (req.uri.path.endsWith('/latest_edition')) {
        await _reply(req, '1');
      } else {
        await _reply(req, jsonEncode('x' * (AleoNode.maxProgramSize + 1)));
      }
    };
    await expectLater(aleo().programSource('big.aleo'),
        throwsA(isA<AleoNodeException>()));
  });

  test('programClosure walks imports and skips credits.aleo', () async {
    // a.aleo imports b.aleo and credits.aleo; b.aleo imports credits.aleo.
    final imports = {
      'a.aleo': ['b.aleo', 'credits.aleo'],
      'b.aleo': ['credits.aleo'],
    };
    node.handler = (req) async {
      final id = req.uri.pathSegments[2]; // /testnet/program/<id>/...
      if (req.uri.path.endsWith('/latest_edition')) {
        await _reply(req, '1');
      } else {
        await _reply(req, jsonEncode('program $id;'));
      }
    };
    final closure =
        await aleo(imports: (src) => imports[_idOf(src)] ?? const []).programClosure('a.aleo');
    final decoded = (jsonDecode(closure) as List).cast<Map<String, dynamic>>();
    expect(decoded.map((e) => e['id']).toSet(), {'a.aleo', 'b.aleo'});
    expect(decoded.every((e) => e['edition'] == 1), isTrue);
  });

  test('programClosure terminates on an import cycle', () async {
    // a -> b -> a: the dedup set must stop the walk rather than loop forever.
    final imports = {
      'a.aleo': ['b.aleo'],
      'b.aleo': ['a.aleo'],
    };
    node.handler = (req) async {
      final id = req.uri.pathSegments[2];
      if (req.uri.path.endsWith('/latest_edition')) {
        await _reply(req, '1');
      } else {
        await _reply(req, jsonEncode('program $id;'));
      }
    };
    final closure = await aleo(imports: (src) => imports[_idOf(src)] ?? const [])
        .programClosure('a.aleo')
        .timeout(const Duration(seconds: 5));
    expect((jsonDecode(closure) as List), hasLength(2));
  });

  test('broadcast posts the transaction as application/json and returns the id',
      () async {
    String? body;
    String? contentType;
    node.handler = (req) async {
      body = await utf8.decodeStream(req);
      contentType = req.headers.contentType?.mimeType;
      await _reply(req, '"at1abcdef"');
    };
    final id = await aleo().broadcast('{"tx":"payload"}');
    expect(id, 'at1abcdef');
    expect(body, '{"tx":"payload"}');
    expect(contentType, 'application/json');
    expect(node.seen.single.uri.path, '/testnet/transaction/broadcast');
  });

  test('a GET retries a transient 5xx, then succeeds', () async {
    var hits = 0;
    node.handler = (req) async {
      hits++;
      if (hits < 3) {
        await _reply(req, 'busy', status: 503);
      } else {
        await _reply(req, '777');
      }
    };
    expect(await aleo().latestHeight(), 777);
    expect(hits, 3);
  });

  test('a GET does not retry a 4xx', () async {
    var hits = 0;
    node.handler = (req) async {
      hits++;
      await _reply(req, 'bad', status: 400);
    };
    await expectLater(aleo().latestHeight(), throwsA(isA<AleoNodeException>()));
    expect(hits, 1);
  });

  test('a stalled response is cancelled by the request timeout', () async {
    node.handler = (req) async {
      // Never reply; hold the socket open past the timeout.
      await Future<void>.delayed(const Duration(seconds: 30));
      await _reply(req, '0');
    };
    final stopwatch = Stopwatch()..start();
    await expectLater(
        aleo(timeout: const Duration(milliseconds: 300)).latestHeight(),
        throwsA(isA<AleoNodeException>()));
    stopwatch.stop();
    // Cancellation actually fires (well under the server's 30s hold).
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });

  // --- review fixes ---------------------------------------------------------

  test('a malformed statePaths body surfaces as AleoNodeException', () async {
    node.handler = (req) => _reply(req, 'not json at all {[');
    await expectLater(
        aleo().statePaths(['c1']), throwsA(isA<AleoNodeException>()));
  });

  test('a malformed program source body surfaces as AleoNodeException',
      () async {
    node.handler = (req) async {
      if (req.uri.path.endsWith('/latest_edition')) {
        await _reply(req, '1');
      } else {
        await _reply(req, 'definitely not json');
      }
    };
    await expectLater(
        aleo().programSource('x.aleo'), throwsA(isA<AleoNodeException>()));
  });

  test('a near-max program whose JSON wire form exceeds the decoded cap is accepted',
      () async {
    // 99000 newlines: decoded length 99000 (<= maxProgramSize), but the
    // JSON-escaped wire body is ~198002 bytes — far past the old maxProgramSize+2
    // streaming cap. The widened wire cap must let it through; the real bound is
    // the decoded-length check.
    final source = '\n' * 99000;
    node.handler = (req) async {
      if (req.uri.path.endsWith('/latest_edition')) {
        await _reply(req, '1');
      } else {
        await _reply(req, jsonEncode(source));
      }
    };
    final src = await aleo().programSource('big.aleo');
    expect(src.source.length, 99000);
  });

  test('retries are bounded by the overall requestTimeout, not attempts × timeout',
      () async {
    // Always-retryable 503: without an overall budget this is ~3s of backoff
    // (0.5+1.0+1.5) across 4 attempts; the overall deadline caps it near
    // requestTimeout.
    node.handler = (req) => _reply(req, 'busy', status: 503);
    final sw = Stopwatch()..start();
    await expectLater(
        aleo(timeout: const Duration(milliseconds: 800)).latestHeight(),
        throwsA(isA<AleoNodeException>()));
    sw.stop();
    expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('programClosure is bounded by closureDeadline even when an import stalls',
      () async {
    // a.aleo resolves fast and imports b.aleo, which stalls forever. The
    // deadline is threaded into the b.aleo fetch, so the closure fails near
    // closureDeadline rather than the 10s requestTimeout / 30s stall.
    node.handler = (req) async {
      final id = req.uri.pathSegments[2];
      if (id == 'a.aleo') {
        if (req.uri.path.endsWith('/latest_edition')) {
          await _reply(req, '1');
        } else {
          await _reply(req, jsonEncode('program a.aleo;'));
        }
      } else {
        await Future<void>.delayed(const Duration(seconds: 30));
        await _reply(req, '1');
      }
    };
    final node2 = AleoNode(node.url,
        network: 'testnet',
        requestTimeout: const Duration(seconds: 10),
        closureDeadline: const Duration(milliseconds: 600),
        parseImports: (src) =>
            _idOf(src) == 'a.aleo' ? ['b.aleo'] : const []);
    final sw = Stopwatch()..start();
    await expectLater(
        node2.programClosure('a.aleo'), throwsA(isA<AleoNodeException>()));
    sw.stop();
    expect(sw.elapsed, lessThan(const Duration(seconds: 3)));
  });

  test('a per-request timeout inside a closure retries while budget remains',
      () async {
    // b.aleo's first edition request stalls past requestTimeout, then succeeds.
    // The per-attempt timeout must NOT be fatal while the closure budget has
    // room — the request is retried and the closure completes.
    var bEditionHits = 0;
    node.handler = (req) async {
      final id = req.uri.pathSegments[2];
      final isEdition = req.uri.path.endsWith('/latest_edition');
      if (id == 'a.aleo') {
        await _reply(req, isEdition ? '1' : jsonEncode('program a.aleo;'));
      } else if (isEdition) {
        bEditionHits++;
        if (bEditionHits == 1) {
          await Future<void>.delayed(const Duration(seconds: 30));
        }
        await _reply(req, '1');
      } else {
        await _reply(req, jsonEncode('program b.aleo;'));
      }
    };
    final node2 = AleoNode(node.url,
        network: 'testnet',
        requestTimeout: const Duration(milliseconds: 400),
        closureDeadline: const Duration(seconds: 10),
        parseImports: (src) =>
            _idOf(src) == 'a.aleo' ? ['b.aleo'] : const []);
    final closure = await node2.programClosure('a.aleo');
    expect((jsonDecode(closure) as List), hasLength(2));
    expect(bEditionHits, greaterThanOrEqualTo(2)); // first timed out, retried
  });

  test('a permanently stalling closure import is bounded by closureDeadline across retries',
      () async {
    // closureDeadline (2s) is the binding bound; each request is capped at
    // requestTimeout (400ms) and retried, so the closure fails near
    // closureDeadline — not the 30s stall — having made multiple attempts.
    var bEditionHits = 0;
    node.handler = (req) async {
      final id = req.uri.pathSegments[2];
      if (id == 'a.aleo') {
        if (req.uri.path.endsWith('/latest_edition')) {
          await _reply(req, '1');
        } else {
          await _reply(req, jsonEncode('program a.aleo;'));
        }
      } else {
        if (req.uri.path.endsWith('/latest_edition')) bEditionHits++;
        await Future<void>.delayed(const Duration(seconds: 30));
        await _reply(req, '1');
      }
    };
    final node2 = AleoNode(node.url,
        network: 'testnet',
        requestTimeout: const Duration(milliseconds: 400),
        closureDeadline: const Duration(seconds: 2),
        parseImports: (src) =>
            _idOf(src) == 'a.aleo' ? ['b.aleo'] : const []);
    final sw = Stopwatch()..start();
    await expectLater(
        node2.programClosure('a.aleo'), throwsA(isA<AleoNodeException>()));
    sw.stop();
    expect(sw.elapsed, lessThan(const Duration(seconds: 4))); // ~2s, not 30s
    expect(bEditionHits, greaterThan(1)); // capped per request + retried
  });

  test('latestHeight rejects a height past u32 range', () async {
    node.handler = (req) => _reply(req, '4294967296'); // 2^32, over u32::MAX
    await expectLater(
        aleo().latestHeight(), throwsA(isA<AleoNodeException>()));
  });

  test('close() tears down a Dio the node created', () async {
    node.handler = (req) => _reply(req, '1');
    final owning = AleoNode(node.url, network: 'testnet');
    expect(await owning.latestHeight(), 1); // works before close
    owning.close();
    // The created Dio (and its pooled client) is closed, so further use fails.
    await expectLater(owning.latestHeight(), throwsA(anything));
  });

  test('close() leaves an injected Dio (owned by the caller) untouched',
      () async {
    node.handler = (req) => _reply(req, '7');
    final injected = AleoNode.defaultDio();
    final n = AleoNode(node.url, network: 'testnet', dio: injected);
    n.close(); // no-op: the caller owns `injected`
    expect(await n.latestHeight(), 7); // injected client still usable
    injected.close(force: true);
  });
}

/// Extracts the program id from our fake `program <id>;` source bodies.
String _idOf(String source) =>
    source.replaceFirst('program ', '').replaceFirst(';', '').trim();
