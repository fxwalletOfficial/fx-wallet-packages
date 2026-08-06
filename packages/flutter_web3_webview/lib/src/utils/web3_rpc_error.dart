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
/// **Reaching the in-page DApp:** the `flutter_inappwebview` bridge re-wraps
/// the exception (see
/// `flutter_inappwebview_ios/in_app_webview_controller.dart:onCallJsHandler`),
/// so the JavaScript side receives a `string` of roughly the form
/// `Error: …, Exception: Web3RpcError: {"code":4001,...}`. The injected
/// provider bridge (`provider/packages/core/adapter/FlutterBridge.ts`) matches
/// the [sentinel] below, parses the trailing JSON, and re-throws a real
/// EIP-1193 `ProviderRpcError` carrying `code` / `message` / `data`, so DApps
/// can branch on `error.code` (e.g. `4902` → `wallet_addEthereumChain`).
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

  /// The wallet does not support the requested method (EIP-1193 `4200`).
  factory Web3RpcError.unsupportedMethod([
    String message = 'Unsupported method',
  ]) =>
      Web3RpcError(4200, message);

  /// The request was cancelled by the wallet before it produced a result.
  ///
  /// EIP-1193 has no dedicated "cancelled" code, so we reuse `4900`
  /// (*disconnected*): from the DApp's point of view the provider stopped
  /// serving that request, which is exactly what `4900` communicates and what
  /// existing DApp error handling already treats as retryable. `4001` is
  /// deliberately not used — it means *the user* rejected, and a
  /// wallet-initiated cancellation (page teardown, account switch, timeout)
  /// is not a user rejection.
  factory Web3RpcError.cancelled([
    String message = 'Request cancelled',
  ]) =>
      Web3RpcError(4900, message);

  /// Too many provider requests are already waiting for the wallet.
  ///
  /// JSON-RPC 2.0 reserved application code `-32005` ("limit exceeded") is the
  /// conventional choice here; EIP-1193 defines no provider code for
  /// back-pressure.
  factory Web3RpcError.limitExceeded([
    String message = 'Too many pending requests',
  ]) =>
      Web3RpcError(-32005, message);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      };

  @override
  String toString() => '$sentinel${jsonEncode(toJson())}';
}
