import 'dart:async';
import 'dart:collection';

import 'package:flutter_web3_webview/src/utils/request_context.dart';
import 'package:flutter_web3_webview/src/utils/request_family.dart';
import 'package:flutter_web3_webview/src/utils/web3_rpc_error.dart';

/// A queued unit of work. Receives the [Web3RequestToken] that identifies it,
/// which is also installed as the ambient `Web3RequestContext` while it runs.
typedef SerialEvent<T> = FutureOr<T> Function(Web3RequestToken token);

/// Snapshot of one request known to a [SerialEventQueue].
class Web3RequestInfo {
  const Web3RequestInfo({
    required this.id,
    required this.method,
    required this.family,
    required this.isActive,
    required this.isCancelled,
  });

  final String id;
  final String method;

  /// Chain family the request routes to (see `Web3RequestDispatcher.familyOf`),
  /// recorded at enqueue so the host can cancel in-flight requests by chain
  /// without re-parsing [method].
  final Web3RequestFamily family;

  /// Whether the request is the one currently executing (as opposed to
  /// waiting its turn).
  final bool isActive;
  final bool isCancelled;

  @override
  String toString() =>
      'Web3RequestInfo(id: $id, method: $method, family: $family, '
      'active: $isActive, cancelled: $isCancelled)';
}

/// Runs provider requests one at a time, in arrival order.
///
/// Every request carries a stable id (see [add]) so the host can address it
/// after the fact — cancel it, or correlate it with the in-page DApp request
/// that produced it.
///
/// ## Guarantees
///
///  * **Correct attribution.** Each [add] returns its own future, completed
///    only from its own event. There is no shared or positional lookup, so
///    queue depth and out-of-order completion inside a handler cannot make
///    one request resolve with another's result.
///  * **No hangs.** Every queued event completes exactly once — with its
///    result, with its own error, or with a cancellation error. A failing
///    event terminates only itself; the loop keeps draining. Nothing else in
///    the queue is left pending because of it.
///  * **Bounded depth.** At most [maxPendingEvents] requests may wait; past
///    that [add] fails closed with EIP-1193-style `-32005` rather than
///    letting a page queue work without limit.
class SerialEventQueue {
  /// Default ceiling on *waiting* requests.
  ///
  /// This is a safety valve against a page flooding the bridge, not a product
  /// policy: it sits far above any plausible legitimate burst (a DApp calling
  /// `signAllTransactions` over a batch), while still being finite. Hosts that
  /// want a tighter or looser bound pass their own [maxPendingEvents].
  static const int defaultMaxPendingEvents = 32;

  SerialEventQueue({this.maxPendingEvents = defaultMaxPendingEvents})
      : assert(maxPendingEvents > 0);

  /// Maximum number of requests that may be waiting to start. The request
  /// currently executing is not counted.
  final int maxPendingEvents;

  final Queue<_QueuedEvent<dynamic>> _events = Queue();
  _QueuedEvent<dynamic>? _active;
  bool _isProcessing = false;
  bool _isDisposed = false;
  int _localIdCounter = 0;

  /// Id of the request currently executing, or `null` when idle.
  String? get activeId => _active?.token.id;

  /// Number of requests waiting to start (excludes the active one).
  int get pendingLength => _events.length;

  bool get isDisposed => _isDisposed;

  /// The active request first (when there is one), then the waiting requests
  /// in the order they will run.
  List<Web3RequestInfo> snapshot() => <Web3RequestInfo>[
        if (_active != null) _active!.toInfo(isActive: true),
        for (final event in _events) event.toInfo(isActive: false),
      ];

  /// Queue [event].
  ///
  /// [id] is the identity supplied by the in-page provider. It is adopted
  /// verbatim when it is usable, so the same string names the request on both
  /// sides of the bridge. A queue-local synthetic id (`local:<n>`) is
  /// substituted when [id] is `null` (an older or hand-rolled caller that
  /// does not send one) or when it collides with a request already in the
  /// queue — a page can call the bridge directly and reuse an id, and letting
  /// it do so would make [cancel] address the wrong request.
  ///
  /// Fails with [Web3RpcError.limitExceeded] once [maxPendingEvents] requests
  /// are already waiting, and with [Web3RpcError.cancelled] after [dispose].
  Future<T> add<T>(
    SerialEvent<T> event, {
    String? id,
    String method = '',
    Web3RequestFamily family = Web3RequestFamily.evm,
  }) {
    if (_isDisposed) {
      return Future<T>.error(Web3RpcError.cancelled('Request queue is closed'));
    }

    if (_events.length >= maxPendingEvents) {
      return Future<T>.error(Web3RpcError.limitExceeded());
    }

    final token = Web3RequestToken(id: _resolveId(id), method: method);
    final entry = _QueuedEvent<T>(token, event, family);
    _events.add(entry);
    _process();
    return entry.completer.future;
  }

  /// Cancel the request identified by [id].
  ///
  /// Returns `false` when no such request is known — it already finished, or
  /// the id never existed.
  ///
  /// A request that has not started yet is dropped from the queue and its
  /// future fails immediately with EIP-1193 `4900`; it never reaches the host
  /// callback at all.
  ///
  /// A request that is already executing is only *flagged*: its token is
  /// marked cancelled so the host callback can bail out at its next safe
  /// point (see [Web3RequestToken]). It is deliberately not force-completed,
  /// because doing so would let the queue advance while the previous
  /// approval, signing or broadcast was still running.
  bool cancel(String id, {String reason = 'Request cancelled'}) {
    final active = _active;
    if (active != null && active.token.id == id) {
      active.token.cancel(reason);
      return true;
    }

    _QueuedEvent<dynamic>? queued;
    for (final event in _events) {
      if (event.token.id == id) {
        queued = event;
        break;
      }
    }
    if (queued == null) return false;

    _events.remove(queued);
    queued.cancelBeforeStart(reason);
    return true;
  }

  /// Cancel every known request and return how many were affected. The active
  /// request is flagged, waiting requests are dropped and failed — same
  /// semantics as [cancel].
  int cancelAll({String reason = 'Request cancelled'}) {
    final active = _active;
    var count = 0;

    if (active != null && !active.token.isCancelled) {
      active.token.cancel(reason);
      count++;
    }

    while (_events.isNotEmpty) {
      _events.removeFirst().cancelBeforeStart(reason);
      count++;
    }

    return count;
  }

  /// Close the queue. Everything known is cancelled and later [add] calls
  /// fail immediately, so tearing the WebView down cannot leave an in-page
  /// promise pending forever.
  void dispose({String reason = 'Request queue is closed'}) {
    if (_isDisposed) return;
    _isDisposed = true;
    cancelAll(reason: reason);
  }

  String _resolveId(String? id) {
    if (id != null && id.isNotEmpty && !_isIdInUse(id)) return id;
    return 'local:${++_localIdCounter}';
  }

  bool _isIdInUse(String id) {
    if (_active?.token.id == id) return true;
    for (final event in _events) {
      if (event.token.id == id) return true;
    }
    return false;
  }

  Future<void> _process() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_events.isNotEmpty) {
        final event = _events.removeFirst();
        _active = event;
        try {
          await event.run();
        } finally {
          _active = null;
        }
      }
    } finally {
      _isProcessing = false;
    }
  }
}

class _QueuedEvent<T> {
  _QueuedEvent(this.token, this.event, this.family);

  final Web3RequestToken token;
  final SerialEvent<T> event;
  final Web3RequestFamily family;
  final Completer<T> completer = Completer<T>();

  Web3RequestInfo toInfo({required bool isActive}) => Web3RequestInfo(
        id: token.id,
        method: token.method,
        family: family,
        isActive: isActive,
        isCancelled: token.isCancelled,
      );

  /// Fail a request that was removed from the queue before it ever ran.
  void cancelBeforeStart(String reason) {
    token.cancel(reason);
    if (completer.isCompleted) return;
    completer.completeError(Web3RpcError.cancelled(reason), StackTrace.current);
  }

  /// Run the event and complete this entry exactly once. Errors are captured
  /// rather than propagated so a failing request cannot break the drain loop
  /// and strand the requests behind it.
  Future<void> run() async {
    try {
      final result = await Web3RequestContext.run<Future<T>>(
        token,
        () async => await event(token),
      );
      if (!completer.isCompleted) completer.complete(result);
    } catch (error, stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    }
  }
}
