import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/utils/request_context.dart';
import 'package:flutter_web3_webview/src/utils/request_family.dart';
import 'package:flutter_web3_webview/src/utils/request_controller.dart';
import 'package:flutter_web3_webview/src/utils/serial_event_queue.dart';
import 'package:flutter_web3_webview/src/utils/web3_rpc_error.dart';

/// Matches a [Web3RpcError] carrying [code].
Matcher throwsWeb3RpcCode(int code) => throwsA(
      isA<Web3RpcError>().having((e) => e.code, 'code', code),
    );

void main() {
  group('queue ordering and family tagging', () {
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

  group('request identity', () {
    test('adopts the id supplied by the in-page provider', () async {
      final queue = SerialEventQueue();
      final blocker = Completer<void>();

      final future = queue.add(
        (token) async {
          await blocker.future;
          return token.id;
        },
        id: 'fxwabc123-7',
        method: 'personal_sign',
      );
      await Future<void>.delayed(Duration.zero);

      expect(queue.activeId, 'fxwabc123-7');
      expect(queue.snapshot().single.method, 'personal_sign');

      blocker.complete();
      expect(await future, 'fxwabc123-7');
    });

    test('substitutes a synthetic id when the payload carries none', () async {
      final queue = SerialEventQueue();
      final ids = <String>[
        await queue.add((token) => token.id),
        await queue.add((token) => token.id),
      ];

      expect(ids, ['local:1', 'local:2']);
    });

    test('substitutes a synthetic id when the page reuses one in flight',
        () async {
      final queue = SerialEventQueue();
      final blocker = Completer<void>();

      // A page can call the bridge directly, so a duplicate id is reachable.
      // Adopting it would make cancel() address the wrong request.
      final first = queue.add((token) async {
        await blocker.future;
        return token.id;
      }, id: 'dup');
      await Future<void>.delayed(Duration.zero);
      final second = queue.add((token) => token.id, id: 'dup');

      expect(queue.snapshot().map((e) => e.id), ['dup', 'local:1']);

      blocker.complete();
      expect(await first, 'dup');
      expect(await second, 'local:1');
    });

    test('an empty id is treated as absent', () async {
      final queue = SerialEventQueue();
      expect(await queue.add((token) => token.id, id: ''), 'local:1');
    });
  });

  group('attribution under load', () {
    test('each request resolves with its own result, out-of-order completion',
        () async {
      final queue = SerialEventQueue();
      final gates = <String, Completer<String>>{
        for (final id in ['a', 'b', 'c', 'd']) id: Completer<String>(),
      };

      // Every handler parks; the test releases them in an order unrelated to
      // arrival order to make sure nothing is positionally matched.
      final futures = <String, Future<String>>{
        for (final id in ['a', 'b', 'c', 'd'])
          id: queue.add((_) => gates[id]!.future, id: id),
      };

      // The queue is serial, so releases have to follow the run order; the
      // point is that each future carries its own payload back.
      for (final id in ['a', 'b', 'c', 'd']) {
        await Future<void>.delayed(Duration.zero);
        gates[id]!.complete('result-$id');
      }

      for (final id in ['a', 'b', 'c', 'd']) {
        expect(await futures[id]!, 'result-$id');
      }
    });

    test('a failing request terminates only itself', () async {
      final queue = SerialEventQueue();
      final ran = <String>[];

      final first = queue.add((_) async {
        ran.add('first');
        return 'ok-first';
      }, id: 'first');
      final boom = queue.add<String>((_) async {
        ran.add('boom');
        throw Web3RpcError.userRejected();
      }, id: 'boom');
      final third = queue.add((_) async {
        ran.add('third');
        return 'ok-third';
      }, id: 'third');

      expect(await first, 'ok-first');
      await expectLater(boom, throwsWeb3RpcCode(4001));
      expect(await third, 'ok-third');
      expect(ran, ['first', 'boom', 'third']);
    });

    test('a synchronously throwing request does not strand the queue',
        () async {
      final queue = SerialEventQueue();
      final boom = queue.add<String>((_) => throw StateError('sync boom'));
      final after = queue.add((_) => 'after');

      await expectLater(boom, throwsStateError);
      expect(await after, 'after');
    });
  });

  group('cancellation', () {
    test('cancelling a waiting request fails it with 4900 and never runs it',
        () async {
      final queue = SerialEventQueue();
      final blocker = Completer<void>();
      final ran = <String>[];

      final active = queue.add((_) async {
        ran.add('active');
        await blocker.future;
        return 'active-result';
      }, id: 'active');
      await Future<void>.delayed(Duration.zero);

      final doomed = queue.add((_) async {
        ran.add('doomed');
        return 'doomed-result';
      }, id: 'doomed');
      final survivor = queue.add((_) async {
        ran.add('survivor');
        return 'survivor-result';
      }, id: 'survivor');

      expect(queue.cancel('doomed', reason: 'navigated away'), isTrue);
      await expectLater(doomed, throwsWeb3RpcCode(4900));

      blocker.complete();
      expect(await active, 'active-result');
      expect(await survivor, 'survivor-result');
      expect(ran, ['active', 'survivor']);
    });

    test('cancelling the active request only flags it; the callback decides',
        () async {
      final queue = SerialEventQueue();
      final reached = Completer<void>();
      final release = Completer<void>();

      final active = queue.add((token) async {
        reached.complete();
        await release.future;
        // The host's chosen safe point, before anything irreversible.
        token.throwIfCancelled();
        return 'signed';
      }, id: 'active');

      await reached.future;
      expect(queue.cancel('active', reason: 'account switched'), isTrue);
      expect(queue.snapshot().single.isCancelled, isTrue);

      // Still running: cancellation did not complete the future for it.
      release.complete();
      await expectLater(
        active,
        throwsA(isA<Web3RpcError>()
            .having((e) => e.code, 'code', 4900)
            .having((e) => e.message, 'message', 'account switched')),
      );
    });

    test('an uncooperative callback still completes normally after cancel',
        () async {
      // Cancellation is cooperative by design: a flow already past the point
      // of no return must not be torn out from under the signer.
      final queue = SerialEventQueue();
      final reached = Completer<void>();
      final release = Completer<void>();

      final active = queue.add((_) async {
        reached.complete();
        await release.future;
        return 'broadcast-hash';
      }, id: 'active');

      await reached.future;
      queue.cancel('active');
      release.complete();

      expect(await active, 'broadcast-hash');
    });

    test('the queue keeps draining after the active request is cancelled',
        () async {
      final queue = SerialEventQueue();
      final reached = Completer<void>();
      final release = Completer<void>();

      final active = queue.add((token) async {
        reached.complete();
        await release.future;
        token.throwIfCancelled();
        return 'never';
      }, id: 'active');
      final next = queue.add((_) => 'next-result', id: 'next');

      await reached.future;
      queue.cancel('active');
      release.complete();

      await expectLater(active, throwsWeb3RpcCode(4900));
      expect(await next, 'next-result');
    });

    test('cancelling an already finished request reports false', () async {
      final queue = SerialEventQueue();
      final future = queue.add((_) => 'done', id: 'once');

      expect(await future, 'done');
      expect(queue.cancel('once'), isFalse);
      expect(queue.cancel('never-existed'), isFalse);
    });

    test('cancel racing completion does not disturb the delivered result',
        () async {
      final queue = SerialEventQueue();
      final release = Completer<String>();
      final future = queue.add((_) => release.future, id: 'racy');
      await Future<void>.delayed(Duration.zero);

      // Result produced, then cancel lands before the microtask drain.
      release.complete('winner');
      final cancelled = queue.cancel('racy');

      expect(await future, 'winner');
      // Whether cancel() saw it as active is timing-dependent, but it must
      // never turn a delivered result into an error.
      expect(cancelled, anyOf(isTrue, isFalse));
    });

    test('the first cancellation reason wins', () async {
      final queue = SerialEventQueue();
      final reached = Completer<void>();
      final release = Completer<void>();

      final active = queue.add((token) async {
        reached.complete();
        await release.future;
        token.throwIfCancelled();
        return 'never';
      }, id: 'active');

      await reached.future;
      queue.cancel('active', reason: 'account switched');
      queue.cancelAll(reason: 'generic sweep');
      release.complete();

      await expectLater(
        active,
        throwsA(isA<Web3RpcError>()
            .having((e) => e.message, 'message', 'account switched')),
      );
    });

    test('cancelAll flags the active request and fails every waiting one',
        () async {
      final queue = SerialEventQueue();
      final reached = Completer<void>();
      final release = Completer<void>();
      var waitingEntered = 0;

      final active = queue.add((token) async {
        reached.complete();
        await release.future;
        token.throwIfCancelled();
        return 'never';
      }, id: 'active');
      final waiting = <Future<String>>[
        queue.add((_) {
          waitingEntered++;
          return 'a';
        }, id: 'a'),
        queue.add((_) {
          waitingEntered++;
          return 'b';
        }, id: 'b'),
      ];

      await reached.future;
      expect(queue.cancelAll(), 3);

      // Dropped means dropped: a waiting request must fail without its callback
      // ever being entered. Hosts rely on this to guarantee that a signing
      // request queued under the previous wallet cannot reach the signer after
      // an account switch — failing the future alone would not be enough.
      expect(waitingEntered, 0);
      for (final future in waiting) {
        await expectLater(future, throwsWeb3RpcCode(4900));
      }

      // The flagged active request keeps its serial slot; only the waiting ones
      // leave the queue.
      final snapshot = queue.snapshot();
      expect(snapshot, hasLength(1));
      expect(snapshot.single.id, 'active');
      expect(snapshot.single.isActive, isTrue);
      expect(snapshot.single.isCancelled, isTrue);

      release.complete();
      await expectLater(active, throwsWeb3RpcCode(4900));
    });

    test('a cancelAll-flagged active request still delivers its own result when '
        'the callback ignores the flag', () async {
      final queue = SerialEventQueue();
      final reached = Completer<void>();
      final release = Completer<String>();

      // No throwIfCancelled: an uncooperative callback (or one already past its
      // point of no return) is never forced to fail by cancelAll.
      final active = queue.add<String>((_) async {
        reached.complete();
        return release.future;
      }, id: 'active');

      await reached.future;
      expect(queue.cancelAll(), 1);

      release.complete('active-result');
      expect(await active, 'active-result');
    });

    test('dispose drains the queue and rejects later requests', () async {
      final queue = SerialEventQueue();
      final reached = Completer<void>();
      final release = Completer<void>();

      final active = queue.add((token) async {
        reached.complete();
        await release.future;
        token.throwIfCancelled();
        return 'never';
      }, id: 'active');
      final waiting = queue.add((_) => 'waiting', id: 'waiting');

      await reached.future;
      queue.dispose();

      expect(queue.isDisposed, isTrue);
      await expectLater(waiting, throwsWeb3RpcCode(4900));
      await expectLater(queue.add((_) => 'late'), throwsWeb3RpcCode(4900));

      release.complete();
      await expectLater(active, throwsWeb3RpcCode(4900));
    });
  });

  group('queue depth', () {
    test('rejects with -32005 once the queue is saturated', () async {
      final queue = SerialEventQueue(maxPendingEvents: 2);
      final release = Completer<void>();

      // One active plus two waiting fills the allowance.
      final active = queue.add((_) => release.future.then((_) => 'active'));
      await Future<void>.delayed(Duration.zero);
      final first = queue.add((_) => 'first');
      final second = queue.add((_) => 'second');

      expect(queue.pendingLength, 2);
      await expectLater(queue.add((_) => 'overflow'), throwsWeb3RpcCode(-32005));

      release.complete();
      expect(await active, 'active');
      expect(await first, 'first');
      expect(await second, 'second');
    });

    test('a freed slot accepts new requests again', () async {
      final queue = SerialEventQueue(maxPendingEvents: 1);
      final release = Completer<void>();

      final active = queue.add((_) => release.future.then((_) => 'active'));
      await Future<void>.delayed(Duration.zero);
      final queued = queue.add((_) => 'queued');
      await expectLater(queue.add((_) => 'rejected'), throwsWeb3RpcCode(-32005));

      release.complete();
      expect(await active, 'active');
      expect(await queued, 'queued');

      expect(await queue.add((_) => 'accepted'), 'accepted');
    });

    test('a rejected overflow request does not disturb the queued ones',
        () async {
      final queue = SerialEventQueue(maxPendingEvents: 1);
      final release = Completer<void>();

      final active = queue.add((_) => release.future.then((_) => 'active'));
      await Future<void>.delayed(Duration.zero);
      final queued = queue.add((_) => 'queued', id: 'queued');
      await expectLater(queue.add((_) => 'x', id: 'x'), throwsWeb3RpcCode(-32005));

      expect(queue.snapshot().map((e) => e.id), ['local:1', 'queued']);

      release.complete();
      expect(await active, 'active');
      expect(await queued, 'queued');
    });
  });

  group('Web3RequestContext', () {
    test('exposes the running request across await boundaries', () async {
      final queue = SerialEventQueue();

      final seen = await queue.add((token) async {
        final before = Web3RequestContext.currentId;
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        return [before, Web3RequestContext.currentId, token.id];
      }, id: 'ctx-1');

      expect(seen, ['ctx-1', 'ctx-1', 'ctx-1']);
    });

    test('does not leak between requests', () async {
      final queue = SerialEventQueue();
      final first = queue.add((_) async {
        await Future<void>.delayed(Duration.zero);
        return Web3RequestContext.currentId;
      }, id: 'one');
      final second = queue.add((_) async {
        await Future<void>.delayed(Duration.zero);
        return Web3RequestContext.currentId;
      }, id: 'two');

      expect(await first, 'one');
      expect(await second, 'two');
      expect(Web3RequestContext.currentId, isNull);
    });

    test('is inert outside a dispatched request', () {
      expect(Web3RequestContext.current, isNull);
      expect(Web3RequestContext.isCancelled, isFalse);
      expect(Web3RequestContext.throwIfCancelled, returnsNormally);
    });

    test('ambient throwIfCancelled terminates the request with 4900', () async {
      final queue = SerialEventQueue();
      final reached = Completer<void>();
      final release = Completer<void>();

      final future = queue.add((_) async {
        reached.complete();
        await release.future;
        // Nested helper style: no token argument threaded through.
        Web3RequestContext.throwIfCancelled();
        return 'signed';
      }, id: 'ambient');

      await reached.future;
      queue.cancel('ambient');
      release.complete();

      await expectLater(future, throwsWeb3RpcCode(4900));
    });
  });

  group('Web3RequestController', () {
    test('is a safe no-op while unattached', () {
      final controller = Web3RequestController();

      expect(controller.isAttached, isFalse);
      expect(controller.requests, isEmpty);
      expect(controller.activeId, isNull);
      expect(controller.pendingLength, 0);
      expect(controller.cancel('anything'), isFalse);
      expect(controller.cancelAll(), 0);
    });

    test('reports and cancels through the attached queue', () async {
      final queue = SerialEventQueue();
      final controller = Web3RequestController()..attach(queue);
      final release = Completer<void>();

      final active = queue.add(
        (_) => release.future.then((_) => 'active'),
        id: 'active',
        method: 'eth_sendTransaction',
      );
      await Future<void>.delayed(Duration.zero);
      final waiting = queue.add((_) => 'waiting', id: 'waiting');

      expect(controller.isAttached, isTrue);
      expect(controller.activeId, 'active');
      expect(controller.pendingLength, 1);
      expect(
        controller.requests.map((e) => '${e.id}/${e.method}/${e.isActive}'),
        ['active/eth_sendTransaction/true', 'waiting//false'],
      );

      expect(controller.cancel('waiting'), isTrue);
      await expectLater(waiting, throwsWeb3RpcCode(4900));

      release.complete();
      expect(await active, 'active');
    });

    test('detach only releases the queue it is bound to', () {
      final queue = SerialEventQueue();
      final other = SerialEventQueue();
      final controller = Web3RequestController()..attach(queue);

      controller.detach(other);
      expect(controller.isAttached, isTrue);

      controller.detach(queue);
      expect(controller.isAttached, isFalse);
    });
  });
}
