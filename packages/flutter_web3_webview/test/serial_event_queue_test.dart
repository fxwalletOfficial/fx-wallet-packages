import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/utils/serial_event_queue.dart';

void main() {
  group('SerialEventQueue', () {
    test('runs events in FIFO order and returns each matching result',
        () async {
      final queue = SerialEventQueue();
      final firstCompleter = Completer<void>();
      final executionOrder = <String>[];

      final first = queue.add(() async {
        executionOrder.add('first-start');
        await firstCompleter.future;
        executionOrder.add('first-end');
        return 'first-result';
      });
      final second = queue.add(() async {
        executionOrder.add('second');
        return 'second-result';
      });
      final third = queue.add(() {
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

      final failed = queue.add<String>(() {
        executionOrder.add('failed');
        throw StateError('failed event');
      });
      final succeeded = queue.add(() {
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

      final first = queue.add(() async {
        executionOrder.add('first');
        await blocker.future;
      });
      await Future<void>.delayed(Duration.zero);

      final second = queue.add(() => executionOrder.add('second'));
      blocker.complete();

      await Future.wait([first, second]);
      expect(executionOrder, ['first', 'second']);
    });
  });
}
