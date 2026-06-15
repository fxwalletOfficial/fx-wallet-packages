import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/flutter_web3_webview.dart';

import 'package:web3_webview_demo/services/bridge_log.dart';
import 'package:web3_webview_demo/services/eth_signer.dart';
import 'package:web3_webview_demo/services/request_summary.dart';
import 'package:web3_webview_demo/services/sol_signer.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

void main() {
  final account = kDemoAccounts.first;

  group('MockEthSigner', () {
    const signer = MockEthSigner();

    test('personalSign returns a 65-byte 0x signature, stable per input',
        () async {
      final a = await signer.personalSign(account: account, message: '0xdead');
      final b = await signer.personalSign(account: account, message: '0xdead');
      final c = await signer.personalSign(account: account, message: '0xbeef');

      expect(a, startsWith('0x'));
      expect(a.length, 132); // 0x + 130 hex chars = 65 bytes
      expect(a, b, reason: 'deterministic for identical input');
      expect(a, isNot(c), reason: 'varies with the message');
    });

    test('sendTransaction returns a 32-byte 0x hash without broadcasting',
        () async {
      final tx = JsTransactionObject.fromJson({
        'from': account.evmAddress,
        'to': '0x0000000000000000000000000000000000000000',
        'value': '0x1',
      });
      final hash = await signer.sendTransaction(
        account: account,
        transaction: tx,
        broadcast: false,
        rpcUrl: 'https://example.invalid',
      );
      expect(hash, startsWith('0x'));
      expect(hash.length, 66); // 0x + 64 hex chars = 32 bytes
    });
  });

  group('MockSolSigner', () {
    const signer = MockSolSigner();

    test('signMessage returns an 88-char base58-ish signature', () async {
      final data = JsCallBackData(
          method: 'solana_signMessage', params: {'raw': '0xabcd'});
      final sig = await signer.signMessage(account: account, data: data);
      expect(sig.length, 88);
      // base58 never contains 0, O, I, or l.
      expect(sig, isNot(contains('0')));
      expect(sig, isNot(contains('O')));
      expect(sig, isNot(contains('I')));
      expect(sig, isNot(contains('l')));
    });
  });

  group('RequestSummary', () {
    test('decodes a hex-encoded personal_sign message to UTF-8', () {
      final hex = '0x${utf8.encode('gm fren').map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
      final summary = RequestSummary.ethMessage(
        title: 'Sign message',
        account: account.evmAddress,
        message: hex,
      );
      final messageRow =
          summary.rows.firstWhere((r) => r.key == 'Message').value;
      expect(messageRow, 'gm fren');
    });

    test('pulls domain + primaryType out of typed data', () {
      final payload = jsonEncode({
        'domain': {'name': 'My DApp'},
        'primaryType': 'Permit',
        'message': {'value': 1},
      });
      final summary = RequestSummary.ethTypedData(
        account: account.evmAddress,
        payload: payload,
      );
      expect(summary.rows.firstWhere((r) => r.key == 'Domain').value,
          'My DApp');
      expect(summary.rows.firstWhere((r) => r.key == 'Primary type').value,
          'Permit');
    });

    test('summarises a send-transaction with truncated calldata', () {
      final tx = JsTransactionObject.fromJson({
        'from': account.evmAddress,
        'to': '0xdeadbeef',
        'value': '0x2386f26fc10000',
        'data': '0x${'ab' * 100}',
      });
      final summary = RequestSummary.ethTransaction(transaction: tx);
      expect(summary.rows.firstWhere((r) => r.key == 'To').value, '0xdeadbeef');
      expect(summary.rows.firstWhere((r) => r.key == 'Data').value,
          contains('chars)'));
    });
  });

  group('BridgeLog round-trip semantics', () {
    test('begin → resolve records success with elapsed time', () {
      final log = BridgeLog();
      addTearDown(log.dispose);

      final id = log.begin(method: 'personal_sign', request: '0xdead');
      expect(log.entries.single.status, BridgeLogStatus.pending);

      log.resolve(id, response: '0xsig', elapsed: const Duration(milliseconds: 12));
      final entry = log.entries.single;
      expect(entry.status, BridgeLogStatus.success);
      expect(entry.response, '0xsig');
      expect(entry.elapsedMicros, 12000);
    });

    test('begin → reject records error', () {
      final log = BridgeLog();
      addTearDown(log.dispose);

      final id = log.begin(method: 'eth_sendTransaction', request: {});
      log.reject(id, error: 'user rejected');
      expect(log.entries.single.status, BridgeLogStatus.error);
      expect(log.entries.single.response, 'user rejected');
    });

    test('record() captures a synchronous round-trip in one call', () {
      final log = BridgeLog();
      addTearDown(log.dispose);

      log.record(method: 'eth_accounts', response: ['0xabc']);
      expect(log.entries.single.status, BridgeLogStatus.success);
    });

    test('honours the capacity bound', () {
      final log = BridgeLog(capacity: 2);
      addTearDown(log.dispose);

      log.record(method: 'a');
      log.record(method: 'b');
      log.record(method: 'c');
      expect(log.entries.map((e) => e.method), ['b', 'c']);
    });
  });
}
