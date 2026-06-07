import 'dart:convert';

import 'package:flutter_web3_webview/src/models/js_callback_data.dart';

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
    this.solAccount,
    this.solSignTransaction,
    this.solSignMessage,
    this.onDefaultCallback,
    required this.evaluateJavascript,
  });

  bool isImmediate(String method) => const {
        'eth_accounts',
        'eth_chainId',
        'solana_account',
      }.contains(method);

  Future<dynamic> dispatch(JsCallBackData data) {
    switch (data.method) {
      case 'eth_accounts':
      case 'eth_requestAccounts':
        return _ethAccounts();
      case 'eth_chainId':
        return _ethChainId();
      case 'wallet_switchEthereumChain':
      case 'wallet_addEthereumChain':
        return _walletSwitchEthereumChain(data);
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

  Future<String> _walletSwitchEthereumChain(JsCallBackData data) async {
    final callback = walletSwitchEthereumChain;
    if (callback == null) throw Exception('Invalid wallet');

    final params = data.getChainParams();
    if (!await callback(params)) throw Exception({'code': 4092});

    await evaluateJavascript(
      'window.ethereum.emitChainChanged(${jsonEncode(params.chainId)})',
    );
    return _ethChainId();
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
