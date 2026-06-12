import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Thrown for any node-I/O failure: a transport error, a timeout/cancellation,
/// a non-2xx status, a malformed body, or a response that blows a safety
/// budget. The phase-1 FFI primitives collapse every error to `""`, so moving
/// node I/O here is also what finally lets a caller tell a network failure
/// apart from bad input.
class AleoNodeException implements Exception {
  final String message;
  AleoNodeException(this.message);

  @override
  String toString() => 'AleoNodeException: $message';
}

/// Owns all Aleo node REST I/O for the phase-2 orchestration, replacing the
/// blocking HTTP that used to live inside the synchronous FFI calls (PR #51's
/// recurring DoS/timeout finding class). The node provides exactly four reads —
/// block height, state root, state paths for a commitment set, and a program's
/// source at its current edition — plus the one write, broadcast.
///
/// Every request carries a dio [CancelToken] so a timeout actually *aborts* the
/// underlying socket: `Future.timeout` only stops awaiting and leaks the
/// connection, which would recreate the abandoned-worker leak we are leaving
/// Rust to escape. dio's own [BaseOptions.connectTimeout] / `receiveTimeout`
/// bound the connect and inter-chunk read phases; [requestTimeout] is the
/// **overall** wall-clock budget for one logical read (covering all retries and
/// their backoff, like the old Rust `http_get_until` deadline) — when it
/// expires the token is cancelled wherever the request blocks.
///
/// Untrusted node responses are budget-checked here on the fetch side, mirroring
/// the Rust parser's caps, and streamed so an oversized or endless body is
/// rejected — and the request cancelled — before it can exhaust memory.
class AleoNode {
  /// `{url}/{network}` — the REST base every route hangs off. Aleo's testnet
  /// runs the network-0 protocol under a `/testnet` path, so the network
  /// segment is caller-supplied rather than derived from the snarkVM type.
  final String base;

  final Dio _dio;

  /// **Overall** wall-clock budget for one logical read — every retry attempt
  /// and every backoff together must fit inside it, so a stalling node cannot
  /// stretch a read to `getAttempts × timeout`. On expiry the in-flight
  /// request's [CancelToken] is cancelled, aborting the socket.
  final Duration requestTimeout;

  /// Retries for an idempotent GET (the public node returns transient 5xx/522).
  /// A POST (broadcast) is never retried — re-submitting a transaction is not
  /// idempotent.
  final int getAttempts;

  /// Wall-clock ceiling on resolving one program import closure — threaded into
  /// every fetch it triggers (not just checked between fetches), so a single
  /// stalling import cannot overrun it. A DoS guard, not a protocol limit.
  final Duration closureDeadline;

  /// Resolves a program's direct imports from its source, so [programClosure]
  /// can walk the closure it must fetch. Supplied by [AleoProgram] as the pure
  /// `required_imports` FFI helper; kept as an injected callback so this class
  /// has no FFI dependency (and can be unit-tested with a fake resolver).
  final List<String> Function(String source)? parseImports;

  // --- Untrusted-response budgets (mirror the Rust parser in aleo_ffi) -------

  /// `MAX_INPUTS` (16) record inputs per transition across at most
  /// `Transaction::MAX_TRANSITIONS` (32) transitions — the most state paths any
  /// execution can require.
  static const int maxStatePaths = 16 * 32;

  /// Per-path byte budget; the array byte cap is `maxStatePaths * this`.
  static const int maxStatePathBytes = 16 * 1024;

  /// `latest/stateRoot` is a single `sr1…` string.
  static const int maxStateRootBytes = 256;

  /// `latest/height` is a small decimal; bound it generously anyway.
  static const int maxHeightBytes = 64;

  /// `MAX_IMPORT_PROGRAMS` — the program-count cap on one import closure.
  static const int maxImportPrograms = 256;

  /// `Net::MAX_PROGRAM_SIZE` — the per-program *decoded* source byte cap; a
  /// larger one cannot be a valid on-chain program.
  static const int maxProgramSize = 100 * 1000;

  /// Streaming cap on the *wire* (JSON-quoted, escape-expanded) program-source
  /// body. A program source is delivered as a JSON string, and JSON escaping can
  /// inflate it up to ~6× (`\uXXXX` per code unit) over the decoded length, so
  /// the wire cap must allow for that — the real `maxProgramSize` bound is then
  /// enforced on the *decoded* string. Sizing the wire cap at `maxProgramSize`
  /// would wrongly reject a legitimate near-max program full of newlines.
  static const int maxProgramSourceWireBytes = maxProgramSize * 6 + 64;

  AleoNode(
    String url, {
    String network = 'testnet',
    Dio? dio,
    this.requestTimeout = const Duration(seconds: 30),
    this.getAttempts = 4,
    this.closureDeadline = const Duration(seconds: 120),
    this.parseImports,
  })  : base = '${url.replaceAll(RegExp(r'/+$'), '')}/$network',
        _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              // We read the raw bytes ourselves (bounded), so dio must not try
              // to JSON-decode or buffer the body for us.
              responseType: ResponseType.stream,
            ));

  /// Current block height — selects the consensus version proving pins.
  Future<int> latestHeight() async {
    final body = await _getWithRetry('latest/height', maxBytes: maxHeightBytes);
    final height = int.tryParse(_unquote(body));
    if (height == null || height < 0) {
      throw AleoNodeException('latest/height returned a non-integer: $body');
    }
    return height;
  }

  /// Latest global state root (the opaque `sr1…` string), for public flows that
  /// have no state path to derive it from. Passed straight through to the FFI.
  Future<String> latestStateRoot() async {
    final body =
        await _getWithRetry('latest/stateRoot', maxBytes: maxStateRootBytes);
    final root = _unquote(body);
    if (root.isEmpty) {
      throw AleoNodeException('latest/stateRoot returned an empty root');
    }
    return root;
  }

  /// State paths for [commitments] (the global input-record commitments
  /// `required_commitments` reported), as the raw JSON array the FFI's
  /// `*_static` primitives parse. One batch request so every path is anchored to
  /// a single block — per-commitment fetches can straddle a block and the
  /// inclusion prover rejects paths that disagree on the root. Returns `[]` for
  /// an empty set (a public flow), without a request.
  Future<String> statePaths(List<String> commitments) async {
    if (commitments.isEmpty) return '[]';
    final route = 'statePaths?commitments=${commitments.join(',')}';
    final body = await _getWithRetry(route,
        maxBytes: maxStatePaths * maxStatePathBytes);
    final dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (e) {
      throw AleoNodeException('statePaths response was not valid JSON: ${e.message}');
    }
    if (decoded is! List) {
      throw AleoNodeException('statePaths response was not a JSON array');
    }
    if (decoded.length > maxStatePaths) {
      throw AleoNodeException(
          'statePaths returned ${decoded.length} entries, over the '
          '$maxStatePaths-entry budget');
    }
    return body.trim();
  }

  /// A program's source at its current on-chain edition. The edition and source
  /// are read in that order (`/program/{id}/latest_edition`, then
  /// `/program/{id}/{edition}`) so they stay consistent across a concurrent
  /// upgrade. The decoded source must not exceed [maxProgramSize]. [deadline],
  /// when supplied, bounds both reads against one shared budget (the closure
  /// walk passes its own).
  Future<({int edition, String source})> programSource(String id,
      {DateTime? deadline}) async {
    final editionBody = await _getWithRetry('program/$id/latest_edition',
        maxBytes: maxHeightBytes, deadline: deadline);
    final edition = int.tryParse(_unquote(editionBody));
    if (edition == null || edition < 0) {
      throw AleoNodeException(
          "program/$id/latest_edition returned a non-integer: $editionBody");
    }
    final sourceBody = await _getWithRetry('program/$id/$edition',
        maxBytes: maxProgramSourceWireBytes, deadline: deadline);
    final dynamic decoded;
    try {
      decoded = jsonDecode(sourceBody);
    } on FormatException catch (e) {
      throw AleoNodeException('program/$id/$edition was not valid JSON: ${e.message}');
    }
    if (decoded is! String) {
      throw AleoNodeException('program/$id/$edition was not a JSON string');
    }
    if (decoded.length > maxProgramSize) {
      throw AleoNodeException(
          "program '$id' source is ${decoded.length} bytes, over the "
          '$maxProgramSize-byte maximum');
    }
    return (edition: edition, source: decoded);
  }

  /// The full import closure of [rootId] as the `program_sources_json` the FFI
  /// program-proof primitives load: a JSON array of `{id, edition, source}`,
  /// imports included, any order (Rust adds them imports-before-importers).
  /// `credits.aleo` is built in and never fetched. Bounded on every axis a
  /// hostile node can stretch an honest, acyclic, individually-valid chain:
  /// program count, cumulative bytes, and wall-clock time (the deadline is
  /// threaded into each fetch, so a single stalling import cannot overrun it).
  Future<String> programClosure(String rootId) async {
    final resolve = parseImports;
    if (resolve == null) {
      throw AleoNodeException(
          'programClosure needs an import resolver (required_imports); '
          'construct AleoNode with parseImports');
    }
    final deadline = DateTime.now().add(closureDeadline);
    final fetched = <String, Map<String, dynamic>>{};
    final queue = <String>[rootId];
    var totalBytes = 0;
    while (queue.isNotEmpty) {
      if (DateTime.now().isAfter(deadline)) {
        throw AleoNodeException(
            'program closure load exceeded its $closureDeadline time budget');
      }
      final id = queue.removeAt(0);
      if (id == 'credits.aleo' || fetched.containsKey(id)) continue;
      if (fetched.length >= maxImportPrograms) {
        throw AleoNodeException(
            'program closure exceeded its $maxImportPrograms-program budget');
      }
      final program = await programSource(id, deadline: deadline);
      // Aleo program sources are ASCII, so code-unit length == byte length; use
      // the UTF-8 byte length anyway so the budget faithfully mirrors the Rust
      // total-byte cap regardless of content.
      totalBytes += utf8.encode(program.source).length;
      if (totalBytes > maxImportPrograms * maxProgramSize) {
        throw AleoNodeException(
            'program closure exceeded its total-byte budget');
      }
      fetched[id] = {
        'id': id,
        'edition': program.edition,
        'source': program.source,
      };
      queue.addAll(resolve(program.source));
    }
    return jsonEncode(fetched.values.toList());
  }

  /// Broadcasts a serialized transaction, returning the node's response (the
  /// `at1…` transaction id on success). Not retried.
  Future<String> broadcast(String transaction) async {
    final token = CancelToken();
    final timer = Timer(requestTimeout,
        () => token.cancel('broadcast exceeded $requestTimeout'));
    try {
      final resp = await _dio.post<ResponseBody>(
        '$base/transaction/broadcast',
        data: transaction,
        options: Options(
          contentType: 'application/json',
          responseType: ResponseType.stream,
        ),
        cancelToken: token,
      );
      final body = await _readBounded(resp.data!,
          maxBytes: maxStateRootBytes, token: token);
      return _unquote(body);
    } on DioException catch (e) {
      throw _wrap('transaction/broadcast', e);
    } finally {
      timer.cancel();
    }
  }

  // --- internals ------------------------------------------------------------

  /// GET `route` with a bounded body and a few retries on a transient failure,
  /// the whole sequence (attempts + backoff) capped by one **overall** deadline
  /// — `requestTimeout` from now, or the caller-supplied [deadline] (the closure
  /// walk shares one across all its fetches). Each attempt is given only the
  /// time left, and a backoff never runs past the deadline.
  Future<String> _getWithRetry(String route,
      {required int maxBytes, DateTime? deadline}) async {
    final overall = deadline ?? DateTime.now().add(requestTimeout);
    DioException? last;
    for (var attempt = 0; attempt < getAttempts; attempt++) {
      final remaining = overall.difference(DateTime.now());
      if (remaining <= Duration.zero) break;
      try {
        return await _getOnce(route, maxBytes: maxBytes, timeout: remaining);
      } on DioException catch (e) {
        last = e;
        if (!_isRetryable(e) || attempt + 1 == getAttempts) {
          throw _wrap(route, e);
        }
        final left = overall.difference(DateTime.now());
        if (left <= Duration.zero) break;
        final backoff = Duration(milliseconds: 500 * (attempt + 1));
        await Future<void>.delayed(backoff < left ? backoff : left);
      }
    }
    if (last != null) throw _wrap(route, last);
    throw AleoNodeException('$route timed out (overall budget exceeded)');
  }

  Future<String> _getOnce(String route,
      {required int maxBytes, required Duration timeout}) async {
    final token = CancelToken();
    final timer = Timer(
        timeout, () => token.cancel('$route exceeded its time budget'));
    try {
      final resp = await _dio.get<ResponseBody>(
        '$base/$route',
        options: Options(responseType: ResponseType.stream),
        cancelToken: token,
      );
      return await _readBounded(resp.data!, maxBytes: maxBytes, token: token);
    } finally {
      timer.cancel();
    }
  }

  /// Streams a response body, accumulating into memory but **cancelling the
  /// request and aborting** the instant it passes [maxBytes], so a malicious
  /// node cannot exhaust the heap with one giant body (cancelling is what
  /// actually closes the socket — throwing alone would leak the connection).
  Future<String> _readBounded(ResponseBody body,
      {required int maxBytes, CancelToken? token}) async {
    final builder = BytesBuilder(copy: false);
    await for (final Uint8List chunk in body.stream) {
      builder.add(chunk);
      if (builder.length > maxBytes) {
        token?.cancel('response exceeded its $maxBytes-byte budget');
        throw AleoNodeException(
            'node response exceeded its $maxBytes-byte budget');
      }
    }
    try {
      return utf8.decode(builder.takeBytes());
    } on FormatException catch (e) {
      throw AleoNodeException('node response was not valid UTF-8: ${e.message}');
    }
  }

  /// Retry only on errors a retry could actually fix: connection/timeout
  /// failures and 5xx (the public node's transient 522). A 4xx is the node
  /// rejecting our input — retrying just repeats it. A cancel (our overall
  /// timeout) is never retryable: the overall deadline has passed.
  bool _isRetryable(DioException e) {
    if (CancelToken.isCancel(e)) return false;
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode ?? 0;
        return status >= 500;
      default:
        return false;
    }
  }

  AleoNodeException _wrap(String route, DioException e) {
    if (CancelToken.isCancel(e)) {
      return AleoNodeException('$route timed out (budget exceeded)');
    }
    final status = e.response?.statusCode;
    final suffix = status != null ? ' (HTTP $status)' : '';
    return AleoNodeException('$route request failed$suffix: ${e.message}');
  }

  /// Strips one layer of surrounding double quotes from a JSON-string body
  /// (`"sr1…"` -> `sr1…`), leaving a bare value untouched.
  static String _unquote(String body) {
    final trimmed = body.trim();
    if (trimmed.length >= 2 &&
        trimmed.startsWith('"') &&
        trimmed.endsWith('"')) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    return trimmed;
  }
}
