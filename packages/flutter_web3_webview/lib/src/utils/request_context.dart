import 'dart:async';

import 'package:flutter_web3_webview/src/utils/web3_rpc_error.dart';

/// Identity + cancellation signal for a single provider request.
///
/// One token exists per request that the wallet actually executes, and it
/// stays alive for the whole lifetime of that request. [id] is the authority
/// the host uses to address the request (cancel it, correlate logs with the
/// in-page DApp); see `Web3RequestController`.
///
/// ## Cancellation is cooperative
///
/// [cancel] only raises a flag. It does **not** interrupt the host callback,
/// unwind it, or complete its future — an approval flow that has already
/// reached signing or broadcast must be allowed to finish, because those
/// steps are not reversible from here.
///
/// The contract is therefore: host callbacks that perform long awaits should
/// call [throwIfCancelled] (or check [isCancelled]) at their own resume
/// points, at places where abandoning the request is still safe. A callback
/// that never checks simply runs to completion, exactly as it does today.
class Web3RequestToken {
  Web3RequestToken({required this.id, this.method = ''});

  /// Stable identity of this request.
  ///
  /// When the in-page provider supplied an `id` in the bridge payload this is
  /// that value, so the same string identifies the request on both sides of
  /// the bridge. Otherwise it is a queue-local synthetic id (see
  /// `SerialEventQueue.add`).
  final String id;

  /// The provider method being served, for diagnostics.
  final String method;

  bool _isCancelled = false;
  String _reason = 'Request cancelled';

  bool get isCancelled => _isCancelled;

  /// Why the request was cancelled. Meaningless while [isCancelled] is false.
  String get cancelReason => _reason;

  /// Flag the request as cancelled. Idempotent — the first reason wins, so a
  /// specific cause (e.g. account switch) is not overwritten by a later
  /// blanket cancellation.
  void cancel([String reason = 'Request cancelled']) {
    if (_isCancelled) return;
    _isCancelled = true;
    _reason = reason;
  }

  /// Terminate the current request with EIP-1193 `4900` if it was cancelled.
  void throwIfCancelled() {
    if (_isCancelled) throw Web3RpcError.cancelled(_reason);
  }
}

const Object _tokenZoneKey = #fxWalletWeb3RequestToken;

/// Ambient access to the [Web3RequestToken] of the request being served.
///
/// The queue runs every host callback inside a zone carrying its token, and
/// Dart propagates zone values across `await`, so nested helpers reach the
/// token without any of the host callback signatures having to change:
///
/// ```dart
/// Future<String> ethSendTransaction(JsTransactionObject tx) async {
///   final approved = await showApprovalSheet(tx);
///   Web3RequestContext.throwIfCancelled(); // safe point: nothing signed yet
///   return sign(tx);
/// }
/// ```
abstract final class Web3RequestContext {
  /// Token of the in-flight request, or `null` outside a dispatched request.
  static Web3RequestToken? get current {
    final value = Zone.current[_tokenZoneKey];
    return value is Web3RequestToken ? value : null;
  }

  /// Id of the in-flight request, or `null` outside a dispatched request.
  static String? get currentId => current?.id;

  /// Whether the in-flight request has been cancelled. `false` when there is
  /// no in-flight request, so callers outside a dispatch never see a
  /// spurious cancellation.
  static bool get isCancelled => current?.isCancelled ?? false;

  /// Terminate the in-flight request with EIP-1193 `4900` if it was
  /// cancelled. A no-op outside a dispatched request.
  static void throwIfCancelled() => current?.throwIfCancelled();

  /// Run [body] with [token] installed as the ambient request context.
  static R run<R>(Web3RequestToken token, R Function() body) =>
      runZoned(body, zoneValues: <Object, Object>{_tokenZoneKey: token});
}
