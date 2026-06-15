import 'dart:convert';

import 'package:flutter_web3_webview/src/models/js_callback_data.dart';
import 'package:flutter_web3_webview/src/utils/web3_rpc_error.dart';

typedef EvaluateJavascript = Future<dynamic> Function(String source);

class Web3RequestDispatcher {
  final Future<List<String>> Function()? ethAccounts;
  final Future<int> Function()? ethChainId;
  final Future<String> Function(JsTransactionObject data)? ethSendTransaction;
  final Future<String> Function(String data)? ethSign;
  final Future<String> Function(String data)? ethPersonalSign;
  final Future<String> Function(String data)? ethSignTypedData;
  final Future<bool> Function(JsAddEthereumChain data)?
      walletSwitchEthereumChain;
  final Future<bool> Function(JsAddEthereumChain data)?
      walletAddEthereumChain;
  final Future<String> Function()? solAccount;
  final Future<String> Function(JsCallBackData data)? solSignTransaction;
  final Future<String> Function(JsCallBackData data)? solSignMessage;
  final Future<dynamic> Function(JsCallBackData data)? onDefaultCallback;
  final EvaluateJavascript evaluateJavascript;

  Web3RequestDispatcher({
    this.ethAccounts,
    this.ethChainId,
    this.ethSendTransaction,
    this.ethSign,
    this.ethPersonalSign,
    this.ethSignTypedData,
    this.walletSwitchEthereumChain,
    this.walletAddEthereumChain,
    this.solAccount,
    this.solSignTransaction,
    this.solSignMessage,
    this.onDefaultCallback,
    required this.evaluateJavascript,
  });

  bool isImmediate(String method) => const {
        'eth_accounts',
        'eth_chainId',
      }.contains(method);

  Future<dynamic> dispatch(JsCallBackData data) {
    switch (data.method) {
      case 'eth_accounts':
      case 'eth_requestAccounts':
        return _ethAccounts();
      case 'eth_chainId':
        return _ethChainId();
      case 'wallet_switchEthereumChain':
        return _walletSwitchEthereumChain(data);
      case 'wallet_addEthereumChain':
        return _walletAddEthereumChain(data);
      case 'solana_account':
        return _solAccount();
      case 'eth_sendTransaction':
        return _ethSendTransaction(data);
      case 'eth_sign':
        return _ethSign(data);
      case 'personal_sign':
        return _personalSign(data);
      case 'eth_signTypedData':
      case 'eth_signTypedData_v3':
      case 'eth_signTypedData_v4':
        return _ethSignTypedData(data);
      case 'solana_signTransaction':
        return _solSignTransaction(data);
      case 'solana_signMessage':
        return _solSignMessage(data);
      default:
        return _defaultCallback(data);
    }
  }

  Future<List<String>> _ethAccounts() {
    final callback = ethAccounts;
    if (callback == null) return Future.error(Exception('Invalid wallet'));
    return callback();
  }

  Future<String> _ethChainId() async {
    final callback = ethChainId;
    if (callback == null) throw Exception('Invalid wallet');
    final id = await callback();
    return '0x${id.toRadixString(16)}';
  }

  Future<String> _ethSendTransaction(JsCallBackData data) {
    final callback = ethSendTransaction;
    if (callback == null) return Future.error(Exception('Invalid wallet'));
    return callback(data.getTxParams());
  }

  Future<String> _ethSign(JsCallBackData data) {
    final callback = ethSign;
    if (callback == null) return Future.error(Exception('Invalid wallet'));
    return callback(data.getEthSignMsg());
  }

  Future<String> _personalSign(JsCallBackData data) {
    final callback = ethPersonalSign;
    if (callback == null) return Future.error(Exception('Invalid wallet'));
    return callback(data.getPersonalSignMsg());
  }

  Future<String> _ethSignTypedData(JsCallBackData data) {
    final callback = ethSignTypedData;
    if (callback == null) return Future.error(Exception('Invalid wallet'));
    return callback(data.getSignTypedDataParams());
  }

  /// EIP-3326 requires the chain id to be a `0x`-prefixed hexadecimal string.
  /// Accept upper or lower case `x` plus at least one hex digit; reject
  /// decimal strings (e.g. `'1'`), malformed hex (e.g. `'0xzz'`), surrounding
  /// whitespace, and `'0x'` with no payload.
  static final RegExp _chainIdPattern = RegExp(r'^0[xX][0-9a-fA-F]+$');

  Future<dynamic> _walletSwitchEthereumChain(JsCallBackData data) async {
    final callback = walletSwitchEthereumChain;
    if (callback == null) throw Exception('Invalid wallet');

    final params = data.getChainParams();
    final chainId = params.chainId;
    if (chainId == null || !_chainIdPattern.hasMatch(chainId)) {
      throw Web3RpcError.unrecognizedChain();
    }

    if (!await callback(params)) throw Web3RpcError.userRejected();

    // Target our own provider explicitly: under EIP-6963 coexistence
    // `window.ethereum` may belong to another wallet, while `fxwallet.ethereum`
    // is always this package's provider.
    await evaluateJavascript(
      'window.fxwallet.ethereum.emitChainChanged(${jsonEncode(chainId)})',
    );
    // EIP-3326: a successful switch resolves with null, not the chain id.
    return null;
  }

  /// EIP-3085 `wallet_addEthereumChain`: register the chain with the wallet
  /// and return `null` on success. Unlike a switch it must NOT change the
  /// active chain, so no `chainChanged` event is emitted here.
  ///
  /// With no dedicated [walletAddEthereumChain] handler the wallet does not
  /// support adding chains, so we reject with an unsupported-method error
  /// (EIP-1193 `4200`) rather than falling back to a switch — a fallback
  /// would let an add request silently change the active network.
  Future<dynamic> _walletAddEthereumChain(JsCallBackData data) async {
    final callback = walletAddEthereumChain;
    if (callback == null) throw Web3RpcError.unsupportedMethod();

    final params = data.getChainParams();
    final chainId = params.chainId;
    if (chainId == null || !_chainIdPattern.hasMatch(chainId)) {
      throw Web3RpcError.unrecognizedChain();
    }

    if (!await callback(params)) throw Web3RpcError.userRejected();
    return null;
  }

  Future<String> _solAccount() {
    final callback = solAccount;
    if (callback == null) return Future.error(Exception('Invalid wallet'));
    return callback();
  }

  Future<String> _solSignTransaction(JsCallBackData data) {
    final callback = solSignTransaction;
    if (callback == null) return Future.error(Exception('Invalid wallet'));
    return callback(data);
  }

  Future<String> _solSignMessage(JsCallBackData data) {
    final callback = solSignMessage;
    if (callback == null) return Future.error(Exception('Invalid wallet'));
    return callback(data);
  }

  Future<dynamic> _defaultCallback(JsCallBackData data) {
    final callback = onDefaultCallback;
    if (callback == null) return Future.error(Exception('Invalid wallet'));
    return callback(data);
  }
}
