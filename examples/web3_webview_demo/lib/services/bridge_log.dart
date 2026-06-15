import 'package:flutter/widgets.dart';

/// Outcome of a single bridge call.
enum BridgeLogStatus {
  /// Resolved before the response came back — only used while a request is
  /// still in flight (typically waiting for user approval).
  pending,

  /// The wallet returned a value (which may be `null`).
  success,

  /// The wallet rejected the request or the dispatcher threw.
  error,
}

/// One round-trip recorded by the Phase 3 Browser-page wiring.
///
/// Entries are immutable snapshots; when the status flips from
/// [BridgeLogStatus.pending] to terminal we add a *new* entry rather than
/// mutate, so the log naturally renders as an append-only timeline.
@immutable
class BridgeLogEntry {
  /// Monotonically-increasing identifier; pairs a `pending` row with its
  /// terminal twin so the UI can collapse them or render a thread.
  final int id;

  /// Method name the DApp sent (`eth_sendTransaction`, `solana_account`,
  /// `personal_sign`, …). Captured verbatim so we surface anything the
  /// dispatcher might have missed.
  final String method;

  /// Wall-clock at the time of capture, used to display "5s ago" hints.
  final DateTime timestamp;

  /// Request payload as the DApp sent it.
  final Object? request;

  /// Response (success) or error (error). `null` while pending.
  final Object? response;

  final BridgeLogStatus status;

  /// Round-trip time in microseconds. `null` for `pending` entries.
  final int? elapsedMicros;

  const BridgeLogEntry({
    required this.id,
    required this.method,
    required this.timestamp,
    required this.request,
    required this.status,
    this.response,
    this.elapsedMicros,
  });

  BridgeLogEntry copyWith({
    BridgeLogStatus? status,
    Object? response,
    int? elapsedMicros,
  }) {
    return BridgeLogEntry(
      id: id,
      method: method,
      timestamp: timestamp,
      request: request,
      status: status ?? this.status,
      response: response ?? this.response,
      elapsedMicros: elapsedMicros ?? this.elapsedMicros,
    );
  }
}

/// In-memory ring buffer of bridge round-trips, surfaced via
/// `ChangeNotifier` so the debug panel can rebuild on every new entry
/// without polling.
///
/// Capacity defaults to 200 — enough to follow a multi-step DApp flow
/// without holding signed-tx blobs in memory forever.
class BridgeLog extends ChangeNotifier {
  BridgeLog({this.capacity = 200});

  final int capacity;

  final List<BridgeLogEntry> _entries = <BridgeLogEntry>[];
  int _nextId = 0;

  /// Oldest-first list. The browser-page debug strip reverses this for
  /// display so the most recent line is on top.
  List<BridgeLogEntry> get entries => List.unmodifiable(_entries);

  /// Record an in-flight request. Returns the entry id so the caller can
  /// pair the success / error completion via [resolve] / [reject].
  int begin({required String method, Object? request}) {
    final id = _nextId++;
    _append(BridgeLogEntry(
      id: id,
      method: method,
      timestamp: DateTime.now(),
      request: request,
      status: BridgeLogStatus.pending,
    ));
    return id;
  }

  void resolve(int id, {Object? response, Duration? elapsed}) {
    _complete(id,
        status: BridgeLogStatus.success,
        response: response,
        elapsed: elapsed);
  }

  void reject(int id, {Object? error, Duration? elapsed}) {
    _complete(id,
        status: BridgeLogStatus.error, response: error, elapsed: elapsed);
  }

  /// Convenience for cases where the resolution happens synchronously
  /// (e.g. auto-approved read-only methods): records the round-trip in a
  /// single call.
  void record({
    required String method,
    Object? request,
    Object? response,
    Object? error,
    Duration? elapsed,
  }) {
    final id = begin(method: method, request: request);
    if (error != null) {
      reject(id, error: error, elapsed: elapsed);
    } else {
      resolve(id, response: response, elapsed: elapsed);
    }
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }

  void _complete(
    int id, {
    required BridgeLogStatus status,
    Object? response,
    Duration? elapsed,
  }) {
    final index = _entries.lastIndexWhere((e) => e.id == id);
    if (index < 0) return;
    final current = _entries[index];
    _entries[index] = current.copyWith(
      status: status,
      response: response,
      elapsedMicros: elapsed?.inMicroseconds ?? current.elapsedMicros,
    );
    notifyListeners();
  }

  void _append(BridgeLogEntry entry) {
    _entries.add(entry);
    while (_entries.length > capacity) {
      _entries.removeAt(0);
    }
    notifyListeners();
  }
}

/// Inherited handle for the [BridgeLog], matching the
/// [WalletStateScope] pattern so widgets reach it through
/// `BridgeLogScope.of(context)`.
class BridgeLogScope extends InheritedNotifier<BridgeLog> {
  const BridgeLogScope({
    super.key,
    required BridgeLog super.notifier,
    required super.child,
  });

  static BridgeLog of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<BridgeLogScope>();
    assert(scope != null, 'BridgeLogScope missing in widget tree');
    return scope!.notifier!;
  }

  static BridgeLog read(BuildContext context) {
    final scope =
        context.getInheritedWidgetOfExactType<BridgeLogScope>();
    assert(scope != null, 'BridgeLogScope missing in widget tree');
    return scope!.notifier!;
  }
}
