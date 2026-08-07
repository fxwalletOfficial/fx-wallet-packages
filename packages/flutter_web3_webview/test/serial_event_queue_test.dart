import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/utils/request_family.dart';
import 'package:flutter_web3_webview/src/utils/serial_event_queue.dart';

void main() {
  group('SerialEventQueue', () {
    test('records the request family on the snapshot, defaulting to EVM',
        () async {
      final queue = SerialEventQueue();
      final release = Completer<void>();

      // Active request carries an explicit Solana tag; the queued one relies on
      // the default so the host still sees a family for legacy callers.
      queue.add((_) => release.future,
          id: 'sol', method: 'solana_signTransaction',
          family: Web3RequestFamily.solana);
      queue.add((_) => 'later', id: 'plain', method: 'eth_sendTransaction');
      await Future<void>.delayed(Duration.zero);

      final snapshot = {for (final info in queue.snapshot()) info.id: info};
      expect(snapshot['sol']!.family, Web3RequestFamily.solana);
      expect(snapshot['plain']!.family, Web3RequestFamily.evm);

      release.complete();
    });

    test('runs events in FIFO order and returns each matching result',
        () async {
      final queue = SerialEventQueue();
      final firstCompleter = Completer<void>();
      final executionOrder = <String>[];

      final first = queue.add((_) async {
        executionOrder.add('first-start');
        await firstCompleter.future;
        executionOrder.add('first-end');
        return 'first-result';
      });
      final second = queue.add((_) async {
        executionOrder.add('second');
        return 'second-result';
      });
      final third = queue.add((_) {
        executionOrder.add('third');
        return 'third-result';
      });

      await Future<void>.delayed(Duration.zero);
      expect(executionOrder, ['first-start']);

      firstCompleter.complete();

      expect(await Future.wait([first, second, third]), [
        'first-result',
        'second-result',
        'third-result',
      ]);
      expect(executionOrder, [
        'first-start',
        'first-end',
        'second',
        'third',
      ]);
    });

    test('continues processing after an event fails', () async {
      final queue = SerialEventQueue();
      final executionOrder = <String>[];

      final failed = queue.add<String>((_) {
        executionOrder.add('failed');
        throw StateError('failed event');
      });
      final succeeded = queue.add((_) {
        executionOrder.add('succeeded');
        return 'result';
      });

      await expectLater(failed, throwsStateError);
      expect(await succeeded, 'result');
      expect(executionOrder, ['failed', 'succeeded']);
    });

    test('processes events added while another event is running', () async {
      final queue = SerialEventQueue();
      final blocker = Completer<void>();
      final executionOrder = <String>[];

      final first = queue.add((_) async {
        executionOrder.add('first');
        await blocker.future;
      });
      await Future<void>.delayed(Duration.zero);

      final second = queue.add((_) => executionOrder.add('second'));
      blocker.complete();

      await Future.wait([first, second]);
      expect(executionOrder, ['first', 'second']);
    });
  });
}
