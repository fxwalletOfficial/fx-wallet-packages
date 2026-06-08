import 'dart:convert';

/// Provider-side error that mirrors EIP-1193 / EIP-3326 error semantics.
///
/// The wallet bridge funnels Dart exceptions back to the in-page provider as
/// strings, so the message is serialised as JSON to give DApps a stable way to
/// recover the structured `code` and `message` fields when they need them.
class Web3RpcError implements Exception {
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
  String toString() => jsonEncode(toJson());
}
