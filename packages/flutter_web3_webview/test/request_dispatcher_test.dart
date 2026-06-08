import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/models/js_callback_data.dart';
import 'package:flutter_web3_webview/src/utils/request_dispatcher.dart';
import 'package:flutter_web3_webview/src/utils/web3_rpc_error.dart';

void main() {
  group('Web3RequestDispatcher.isImmediate', () {
    test('identifies methods that bypass the serial event queue', () {
      final dispatcher = _dispatcher();

      for (final method in const [
        'eth_accounts',
        'eth_chainId',
      ]) {
        expect(dispatcher.isImmediate(method), isTrue, reason: method);
      }

      for (final method in const [
        'eth_requestAccounts',
        'eth_sendTransaction',
        'eth_sign',
        'personal_sign',
        'eth_signTypedData_v4',
        'wallet_switchEthereumChain',
        'wallet_addEthereumChain',
        'solana_account',
        'solana_signTransaction',
        'unknown_method',
      ]) {
        expect(dispatcher.isImmediate(method), isFalse, reason: method);
      }
    });
  });

  group('Web3RequestDispatcher.dispatch', () {
    test('routes account and chain requests', () async {
      final dispatcher = _dispatcher(
        ethAccounts: () async => ['0xaccount'],
        ethChainId: () async => 137,
        solAccount: () async => 'sol-account',
      );

      expect(await dispatcher.dispatch(_data('eth_accounts')), ['0xaccount']);
      expect(
        await dispatcher.dispatch(_data('eth_requestAccounts')),
        ['0xaccount'],
      );
      expect(await dispatcher.dispatch(_data('eth_chainId')), '0x89');
      expect(
        await dispatcher.dispatch(_data('solana_account')),
        'sol-account',
      );
    });

    test('routes transaction and signing requests with parsed params',
        () async {
      final received = <String, dynamic>{};
      final typedData = {
        'domain': {'name': 'Test'}
      };
      final dispatcher = _dispatcher(
        ethSendTransaction: (transaction) async {
          received['transaction'] = transaction.toJson();
          return 'tx-hash';
        },
        ethSign: (message) async {
          received['ethSign'] = message;
          return 'eth-signature';
        },
        ethPersonalSign: (message) async {
          received['personalSign'] = message;
          return 'personal-signature';
        },
        ethSignTypedData: (data) async {
          received['typedData'] = data;
          return 'typed-signature';
        },
      );

      expect(
        await dispatcher.dispatch(_data('eth_sendTransaction', [
          {'from': '0xfrom', 'nonce': '0x1'}
        ])),
        'tx-hash',
      );
      expect(
        await dispatcher.dispatch(
          _data('eth_sign', ['0xaddress', '0xmessage']),
        ),
        'eth-signature',
      );
      expect(
        await dispatcher.dispatch(
          _data('personal_sign', ['0xpersonal', '0xaddress']),
        ),
        'personal-signature',
      );

      for (final method in const [
        'eth_signTypedData',
        'eth_signTypedData_v3',
        'eth_signTypedData_v4',
      ]) {
        expect(
          await dispatcher.dispatch(_data(method, [typedData, '0xaddress'])),
          'typed-signature',
        );
      }

      expect(received['transaction'], containsPair('nonce', '0x1'));
      expect(received['ethSign'], '0xmessage');
      expect(received['personalSign'], '0xpersonal');
      expect(received['typedData'], jsonEncode(typedData));
    });

    test('routes Solana and default requests with original callback data',
        () async {
      final received = <JsCallBackData>[];
      final dispatcher = _dispatcher(
        solSignTransaction: (data) async {
          received.add(data);
          return 'sol-transaction-signature';
        },
        solSignMessage: (data) async {
          received.add(data);
          return 'sol-message-signature';
        },
        onDefaultCallback: (data) async {
          received.add(data);
          return {'handled': data.method};
        },
      );
      final transaction = _data('solana_signTransaction', {'raw': 'raw-tx'});
      final message = _data('solana_signMessage', {'raw': 'raw-message'});
      final unknown = _data('unknown_method', {'value': 1});

      expect(
        await dispatcher.dispatch(transaction),
        'sol-transaction-signature',
      );
      expect(await dispatcher.dispatch(message), 'sol-message-signature');
      expect(await dispatcher.dispatch(unknown), {'handled': 'unknown_method'});
      expect(received, [transaction, message, unknown]);
    });

    test('switches or adds a chain, emits the event, and returns chain id',
        () async {
      final scripts = <String>[];
      final receivedChainIds = <String?>[];
      final dispatcher = _dispatcher(
        ethChainId: () async => 10,
        walletSwitchEthereumChain: (chain) async {
          receivedChainIds.add(chain.chainId);
          return true;
        },
        evaluateJavascript: (source) async => scripts.add(source),
      );
      final params = [
        {'chainId': '0xa'}
      ];

      expect(
        await dispatcher.dispatch(_data('wallet_switchEthereumChain', params)),
        '0xa',
      );
      expect(
        await dispatcher.dispatch(_data('wallet_addEthereumChain', params)),
        '0xa',
      );
      expect(receivedChainIds, ['0xa', '0xa']);
      expect(scripts, [
        'window.ethereum.emitChainChanged("0xa")',
        'window.ethereum.emitChainChanged("0xa")',
      ]);
    });

    test('JSON-encodes chain id before emitting the chain event', () async {
      const unsafeChainId = '0x1); window.compromised = true; //';
      final scripts = <String>[];
      final dispatcher = _dispatcher(
        ethChainId: () async => 1,
        walletSwitchEthereumChain: (_) async => true,
        evaluateJavascript: (source) async => scripts.add(source),
      );

      await dispatcher.dispatch(
        _data('wallet_switchEthereumChain', [
          {'chainId': unsafeChainId}
        ]),
      );

      expect(
        scripts.single,
        'window.ethereum.emitChainChanged(${jsonEncode(unsafeChainId)})',
      );
      expect(scripts.single, isNot(contains('emitChainChanged(0x1)')));
    });

    test('does not emit chain event when switch is rejected', () async {
      final scripts = <String>[];
      final dispatcher = _dispatcher(
        ethChainId: () async => 1,
        walletSwitchEthereumChain: (_) async => false,
        evaluateJavascript: (source) async => scripts.add(source),
      );

      await expectLater(
        dispatcher.dispatch(
          _data('wallet_switchEthereumChain', [
            {'chainId': '0x1'}
          ]),
        ),
        throwsA(
          isA<Web3RpcError>()
              .having((error) => error.code, 'code', 4001)
              .having(
                (error) => error.toString(),
                'toString',
                contains('"code":4001'),
              ),
        ),
      );
      expect(scripts, isEmpty);
    });

    test('rejects switchEthereumChain without a usable chain id', () async {
      final scripts = <String>[];
      var callbackInvocations = 0;
      final dispatcher = _dispatcher(
        ethChainId: () async => 1,
        walletSwitchEthereumChain: (_) async {
          callbackInvocations += 1;
          return true;
        },
        evaluateJavascript: (source) async => scripts.add(source),
      );

      for (final params in <dynamic>[
        const <dynamic>[],
        [<String, dynamic>{}],
        [
          {'chainId': null}
        ],
        [
          {'chainId': ''}
        ],
        [
          {'chainId': 1}
        ],
      ]) {
        await expectLater(
          dispatcher.dispatch(_data('wallet_switchEthereumChain', params)),
          throwsA(
            isA<Web3RpcError>().having((error) => error.code, 'code', 4902),
          ),
          reason: params.toString(),
        );
      }

      expect(callbackInvocations, 0);
      expect(scripts, isEmpty);
    });

    test('throws Invalid wallet when the routed callback is missing', () async {
      final dispatcher = _dispatcher();

      for (final method in const [
        'eth_accounts',
        'eth_chainId',
        'eth_sendTransaction',
        'eth_sign',
        'personal_sign',
        'eth_signTypedData_v4',
        'wallet_switchEthereumChain',
        'solana_account',
        'solana_signTransaction',
        'solana_signMessage',
        'unknown_method',
      ]) {
        await expectLater(
          dispatcher.dispatch(_data(method)),
          throwsA(
            isA<Exception>().having(
              (error) => error.toString(),
              'message',
              contains('Invalid wallet'),
            ),
          ),
          reason: method,
        );
      }
    });

    test('propagates callback and JavaScript evaluation errors', () async {
      final callbackError = StateError('callback failed');
      final evaluateError = StateError('evaluation failed');

      await expectLater(
        _dispatcher(ethAccounts: () => Future.error(callbackError))
            .dispatch(_data('eth_accounts')),
        throwsA(same(callbackError)),
      );

      await expectLater(
        _dispatcher(
          ethChainId: () async => 1,
          walletSwitchEthereumChain: (_) async => true,
          evaluateJavascript: (_) => Future.error(evaluateError),
        ).dispatch(
          _data('wallet_switchEthereumChain', [
            {'chainId': '0x1'}
          ]),
        ),
        throwsA(same(evaluateError)),
      );
    });
  });
}

JsCallBackData _data(String method, [dynamic params = const []]) {
  return JsCallBackData(method: method, params: params);
}

Web3RequestDispatcher _dispatcher({
  Future<List<String>> Function()? ethAccounts,
  Future<int> Function()? ethChainId,
  Future<String> Function(JsTransactionObject data)? ethSendTransaction,
  Future<String> Function(String data)? ethSign,
  Future<String> Function(String data)? ethPersonalSign,
  Future<String> Function(String data)? ethSignTypedData,
  Future<bool> Function(JsAddEthereumChain data)? walletSwitchEthereumChain,
  Future<String> Function()? solAccount,
  Future<String> Function(JsCallBackData data)? solSignTransaction,
  Future<String> Function(JsCallBackData data)? solSignMessage,
  Future<dynamic> Function(JsCallBackData data)? onDefaultCallback,
  EvaluateJavascript? evaluateJavascript,
}) {
  return Web3RequestDispatcher(
    ethAccounts: ethAccounts,
    ethChainId: ethChainId,
    ethSendTransaction: ethSendTransaction,
    ethSign: ethSign,
    ethPersonalSign: ethPersonalSign,
    ethSignTypedData: ethSignTypedData,
    walletSwitchEthereumChain: walletSwitchEthereumChain,
    solAccount: solAccount,
    solSignTransaction: solSignTransaction,
    solSignMessage: solSignMessage,
    onDefaultCallback: onDefaultCallback,
    evaluateJavascript: evaluateJavascript ?? (_) async {},
  );
}
