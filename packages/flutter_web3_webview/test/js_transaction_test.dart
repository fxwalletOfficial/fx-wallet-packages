import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/models/js_transaction.dart';

void main() {
  group('JsTransactionObject', () {
    test('creates an empty transaction', () {
      final transaction = JsTransactionObject();

      expect(transaction.toJson(), <String, dynamic>{});
    });

    test('parses and serializes every transaction field', () {
      final transaction = JsTransactionObject.fromJson({
        'gas': '0x5208',
        'value': '0x1',
        'from': '0xfrom',
        'to': '0xto',
        'data': '0xdata',
      });

      final json = transaction.toJson();

      expect(json, {
        'gas': '0x5208',
        'value': '0x1',
        'from': '0xfrom',
        'to': '0xto',
        'data': '0xdata',
      });
      expect(jsonEncode(json), contains('"data":"0xdata"'));
    });

    test(
      'exposes null typed getters for non-string values but preserves the '
      'raw payload so downstream wallets still see the DApp data',
      () {
        final transaction = JsTransactionObject.fromJson({
          'gas': 21000,
          'value': true,
          'from': const [],
          'to': const {},
          'data': 1,
        });

        expect(transaction.gas, isNull);
        expect(transaction.value, isNull);
        expect(transaction.from, isNull);
        expect(transaction.to, isNull);
        expect(transaction.data, isNull);

        expect(transaction.toJson(), {
          'gas': 21000,
          'value': true,
          'from': const [],
          'to': const {},
          'data': 1,
        });
      },
    );

    test('preserves EIP-1559 and unknown transaction fields', () {
      final transaction = JsTransactionObject.fromJson({
        'from': '0xfrom',
        'to': '0xto',
        'maxFeePerGas': '0x59682f00',
        'maxPriorityFeePerGas': '0x3b9aca00',
        'nonce': '0x1',
        'chainId': '0x1',
        'type': '0x2',
        'accessList': const [],
        'customField': 'custom-value',
      });

      expect(transaction.toJson(), {
        'from': '0xfrom',
        'to': '0xto',
        'maxFeePerGas': '0x59682f00',
        'maxPriorityFeePerGas': '0x3b9aca00',
        'nonce': '0x1',
        'chainId': '0x1',
        'type': '0x2',
        'accessList': const [],
        'customField': 'custom-value',
      });
    });

    test('does not expose a mutable reference to input data', () {
      final input = <String, dynamic>{
        'from': '0xfrom',
        'nonce': '0x1',
      };
      final transaction = JsTransactionObject.fromJson(input);

      input['nonce'] = '0x2';

      expect(transaction.toJson()['nonce'], '0x1');
    });

    test('typed setters update toJson, including clearing via null', () {
      final transaction = JsTransactionObject.fromJson({
        'gas': '0x5208',
        'value': '0x1',
        'from': '0xfrom',
        'to': '0xto',
        'data': '0xdata',
        'nonce': '0x1',
      });

      transaction.gas = '0xabcd';
      transaction.to = null;
      transaction.data = null;

      expect(transaction.gas, '0xabcd');
      expect(transaction.to, isNull);
      expect(transaction.data, isNull);
      expect(transaction.toJson(), {
        'gas': '0xabcd',
        'value': '0x1',
        'from': '0xfrom',
        'nonce': '0x1',
      });
    });

    test('typed setters replace non-string raw values', () {
      final transaction = JsTransactionObject.fromJson({
        'gas': 21000,
        'from': '0xfrom',
      });

      expect(transaction.gas, isNull);
      expect(transaction.toJson()['gas'], 21000);

      transaction.gas = '0x5208';

      expect(transaction.gas, '0x5208');
      expect(transaction.toJson(), {
        'gas': '0x5208',
        'from': '0xfrom',
      });
    });

    test('default constructor only emits provided fields', () {
      final transaction = JsTransactionObject(
        from: '0xfrom',
        to: '0xto',
      );

      expect(transaction.toJson(), {
        'from': '0xfrom',
        'to': '0xto',
      });
    });
  });
}
