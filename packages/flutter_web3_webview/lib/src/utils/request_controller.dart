import 'package:flutter_web3_webview/src/utils/serial_event_queue.dart';

/// Host-side handle onto a `Web3Webview`'s provider request queue.
///
/// Pass one to `Web3Webview(requestController: ...)` and the widget binds it
/// to its queue for as long as it is mounted. The controller only exposes
/// mechanism — inspect what is in flight, cancel by id. *When* to cancel
/// (account switch, chain switch, navigation away, an approval timeout) is a
/// wallet policy decision and stays with the host.
///
/// Cancellation semantics are documented on [SerialEventQueue.cancel]: a
/// request that has not started is dropped and fails with EIP-1193 `4900`, a
/// request already executing is only flagged for its callback to observe.
class Web3RequestController {
  SerialEventQueue? _queue;

  /// Whether a `Web3Webview` is currently bound. Every accessor below is a
  /// safe no-op while unbound, so a controller held across widget rebuilds or
  /// created ahead of its WebView never throws.
  bool get isAttached => _queue != null;

  /// The active request first (when there is one), then the waiting requests
  /// in the order they will run.
  List<Web3RequestInfo> get requests => _queue?.snapshot() ?? const [];

  /// Id of the request currently being served, or `null` when idle.
  String? get activeId => _queue?.activeId;

  /// Number of requests waiting to start, excluding the active one.
  int get pendingLength => _queue?.pendingLength ?? 0;

  /// Cancel one request. Returns `false` when it is already finished or was
  /// never queued.
  bool cancel(String id, {String reason = 'Request cancelled'}) =>
      _queue?.cancel(id, reason: reason) ?? false;

  /// Cancel every known request; returns how many were affected.
  int cancelAll({String reason = 'Request cancelled'}) =>
      _queue?.cancelAll(reason: reason) ?? 0;

  /// Bind this controller to [queue]. Called by `Web3WebviewState`; not part
  /// of the host-facing API.
  void attach(SerialEventQueue queue) => _queue = queue;

  /// Unbind [queue] if it is the one currently bound. Called by
  /// `Web3WebviewState`; not part of the host-facing API.
  void detach(SerialEventQueue queue) {
    if (identical(_queue, queue)) _queue = null;
  }
}
