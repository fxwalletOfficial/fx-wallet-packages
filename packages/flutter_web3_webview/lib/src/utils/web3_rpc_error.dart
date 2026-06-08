import 'dart:convert';

/// Provider-side error that mirrors EIP-1193 / EIP-3326 error semantics.
///
/// ## Scope
///
/// `Web3RpcError` standardises how the Flutter layer signals provider-level
/// failures (`code` + `message`) instead of using opaque `Exception` strings.
/// Down-stream wallet code can `catch (e) { if (e is Web3RpcError) … }` and
/// reason about the failure structurally.
///
/// **What this class does _not_ do today:** it does not, on its own, surface a
/// structured `error.code` to the in-page DApp. The `flutter_inappwebview`
/// bridge re-wraps the exception (see
/// `flutter_inappwebview_ios/in_app_webview_controller.dart:onCallJsHandler`),
/// so the JavaScript side receives a `string` message of roughly the form
/// `Error: …, Exception: Web3RpcError: {"code":4001,...}`. The injected
/// provider must therefore parse the trailing JSON before it can hand the
/// DApp a real `ProviderRpcError`. That parsing belongs in the provider
/// JavaScript bundle (see the parked `feature/web3-provider-js-tooling`
/// branch); until it lands, DApps still only see the wrapped string.
///
/// The [toString] output prefixes the JSON with a stable `Web3RpcError: `
/// sentinel so the future bridge code can match it with a single regex even
/// after the platform layer has wrapped the message further.
class Web3RpcError implements Exception {
  /// Sentinel that prefixes [toString] output so the provider bridge can
  /// reliably locate the JSON payload inside the wrapped exception string.
  static const String sentinel = 'Web3RpcError: ';

  /// EIP-1193 / EIP-3326 numeric error code.
  ///
  /// Common values:
  ///   * `4001` — user rejected the request.
  ///   * `4100` — unauthorized.
  ///   * `4200` — unsupported method.
  ///   * `4900` — disconnected.
  ///   * `4901` — chain disconnected.
  ///   * `4902` — unrecognized chain id.
  final int code;
  final String message;
  final Object? data;

  const Web3RpcError(this.code, this.message, {this.data});

  /// User explicitly rejected the request.
  factory Web3RpcError.userRejected([
    String message = 'User rejected the request',
  ]) =>
      Web3RpcError(4001, message);

  /// The chain referenced by the request has not been added to the wallet, or
  /// the request did not include a usable chain id.
  factory Web3RpcError.unrecognizedChain([
    String message = 'Unrecognized chain ID',
  ]) =>
      Web3RpcError(4902, message);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  @override
  String toString() => '$sentinel${jsonEncode(toJson())}';
}
