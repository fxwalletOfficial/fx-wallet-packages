import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/models/js_callback_data.dart';

void main() {
  group('JsCallBackData.fromData', () {
    test('parses a callback payload wrapped in a list', () {
      final data = JsCallBackData.fromData([
        {
          'method': 'eth_sendTransaction',
          'params': [
            {'from': '0xfrom', 'to': '0xto'}
          ],
        }
      ]);

      expect(data.method, 'eth_sendTransaction');
      expect(data.params, [
        {'from': '0xfrom', 'to': '0xto'}
      ]);
    });

    test('parses a callback payload passed directly as a map', () {
      final data = JsCallBackData.fromData({
        'method': 'solana_account',
        'params': const <String, dynamic>{},
      });

      expect(data.method, 'solana_account');
      expect(data.params, isEmpty);
    });

    test('uses defaults for empty or invalid payloads', () {
      for (final payload in <dynamic>[
        null,
        'invalid',
        1,
        const [],
        [null]
      ]) {
        final data = JsCallBackData.fromData(payload);

        expect(data.method, isEmpty);
        expect(data.params, isEmpty);
      }
    });

    test('uses defaults for invalid method and null params', () {
      final data = JsCallBackData.fromData([
        {'method': 1, 'params': null}
      ]);

      expect(data.method, isEmpty);
      expect(data.params, isEmpty);
    });
  });

  group('transaction params', () {
    test('parses the first transaction from a params list', () {
      final transaction = JsCallBackData(params: [
        {
          'gas': '0x5208',
          'value': '0x1',
          'from': '0xfrom',
          'to': '0xto',
          'data': '0xdata',
        }
      ]).getTxParams();

      expect(transaction.toJson(), {
        'gas': '0x5208',
        'value': '0x1',
        'from': '0xfrom',
        'to': '0xto',
        'data': '0xdata',
      });
    });

    test('parses transaction params passed directly as a map', () {
      final transaction = JsCallBackData(params: {
        'from': '0xfrom',
        'to': '0xto',
      }).getTxParams();

      expect(transaction.from, '0xfrom');
      expect(transaction.to, '0xto');
    });

    test('returns an empty transaction for invalid params', () {
      final transaction = JsCallBackData(params: 'invalid').getTxParams();

      expect(transaction.toJson().values, everyElement(isNull));
    });
  });

  group('signing params', () {
    test('extracts eth_sign message from string or dynamic list params', () {
      expect(JsCallBackData(params: '0xmessage').getEthSignMsg(), '0xmessage');
      expect(
        JsCallBackData(
          params: <dynamic>['0xaddress', '0xmessage'],
        ).getEthSignMsg(),
        '0xmessage',
      );
    });

    test('returns empty eth_sign message for invalid params', () {
      expect(JsCallBackData(params: const []).getEthSignMsg(), isEmpty);
      expect(
        JsCallBackData(params: const ['0xaddress', 1]).getEthSignMsg(),
        isEmpty,
      );
    });

    test('extracts personal_sign message from common param shapes', () {
      expect(
        JsCallBackData(params: '0xmessage').getPersonalSignMsg(),
        '0xmessage',
      );
      expect(
        JsCallBackData(
          params: <dynamic>['0xmessage', '0xaddress'],
        ).getPersonalSignMsg(),
        '0xmessage',
      );
      expect(
        JsCallBackData(
          params: <dynamic>[
            {'message': 'hello'},
            '0xaddress',
          ],
        ).getPersonalSignMsg(),
        jsonEncode({'message': 'hello'}),
      );
    });

    test('returns empty personal_sign message for invalid params', () {
      expect(JsCallBackData(params: null).getPersonalSignMsg(), isEmpty);
      expect(JsCallBackData(params: const []).getPersonalSignMsg(), isEmpty);
    });

    test('extracts typed data with address first or typed data first', () {
      const typedDataJson = '{"domain":{"name":"Test"}}';
      final typedDataMap = {
        'domain': {'name': 'Test'}
      };

      expect(
        JsCallBackData(
          params: <dynamic>['0xaddress', typedDataJson],
        ).getSignTypedDataParams(),
        typedDataJson,
      );
      expect(
        JsCallBackData(
          params: <dynamic>[typedDataMap, '0xaddress'],
        ).getSignTypedDataParams(),
        jsonEncode(typedDataMap),
      );
    });

    test('returns empty typed data for invalid params', () {
      expect(JsCallBackData(params: null).getSignTypedDataParams(), isEmpty);
      expect(
        JsCallBackData(params: const ['only-one-item'])
            .getSignTypedDataParams(),
        isEmpty,
      );
    });
  });

  group('chain params', () {
    test('parses the first chain from a params list', () {
      final chain = JsCallBackData(params: [
        {
          'chainId': '0x1',
          'chainName': 'Ethereum',
        }
      ]).getChainParams();

      expect(chain.chainId, '0x1');
      expect(chain.data?['chainName'], 'Ethereum');
    });

    test('returns an empty chain for invalid params', () {
      final chain = JsCallBackData(params: 'invalid').getChainParams();

      expect(chain.chainId, isNull);
      expect(chain.data, isEmpty);
    });
  });
}
