import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/models/settings.dart';
import 'package:flutter_web3_webview/src/utils/provider.dart';
import 'package:flutter_web3_webview/src/utils/request_controller.dart';
import 'package:flutter_web3_webview/src/utils/web3_rpc_error.dart';
import 'package:flutter_web3_webview/src/webview.dart';

import 'support/fake_inappwebview_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeInAppWebViewPlatform platform;

  setUp(() async {
    platform = FakeInAppWebViewPlatform();
    InAppWebViewPlatform.instance = platform;
    Providers.resetForTesting();
    await Providers.init();
  });

  tearDown(Providers.resetForTesting);

  test('initializes provider JavaScript through the public entry point',
      () async {
    Providers.resetForTesting();

    await Web3Webview.initJs();

    expect(Providers.js, isNotEmpty);
  });

  testWidgets('injects provider scripts before caller scripts', (tester) async {
    final callerScript = UserScript(
      source: 'caller-script',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
    );

    await _pumpWebView(
      tester,
      Web3Webview(
        settings: Web3Settings(name: 'Custom Wallet'),
        initialUserScripts: [callerScript],
      ),
    );

    final scripts = platform.lastParams!.initialUserScripts!;
    expect(scripts, hasLength(3));
    expect(scripts[0].source, Providers.js);
    expect(scripts[1].source, contains('name: "Custom Wallet"'));
    expect(scripts[2], same(callerScript));
    expect(
      scripts.map((script) => script.injectionTime),
      everyElement(UserScriptInjectionTime.AT_DOCUMENT_START),
    );
  });

  testWidgets('does not inject provider scripts when Web3 is disabled',
      (tester) async {
    final callerScript = UserScript(
      source: 'caller-script',
      injectionTime: UserScriptInjectionTime.AT_DOCUMENT_END,
    );

    await _pumpWebView(
      tester,
      Web3Webview(
        isWeb3: false,
        initialUserScripts: [callerScript],
      ),
    );

    final scripts = platform.lastParams!.initialUserScripts!;
    expect(scripts, [same(callerScript)]);
  });

  testWidgets('forwards WebView configuration and callbacks', (tester) async {
    final settings = InAppWebViewSettings(javaScriptEnabled: false);
    final request = URLRequest(url: WebUri('https://example.com'));
    final loadStart = Completer<WebUri?>();
    Future<AjaxRequestAction?> onAjaxReadyStateChange(
      InAppWebViewController controller,
      AjaxRequest request,
    ) async {
      return AjaxRequestAction.PROCEED;
    }

    await _pumpWebView(
      tester,
      Web3Webview(
        initialSettings: settings,
        initialUrlRequest: request,
        onLoadStart: (_, url) => loadStart.complete(url),
        onAjaxReadyStateChange: onAjaxReadyStateChange,
      ),
    );

    final params = platform.lastParams!;
    expect(params.initialSettings, same(settings));
    expect(params.initialUrlRequest, same(request));
    expect(params.onLoadStart, isNotNull);
    expect(
      await params.onAjaxReadyStateChange!(
        InAppWebViewController.fromPlatform(
          platform: platform.lastController!,
        ),
        AjaxRequest(),
      ),
      AjaxRequestAction.PROCEED,
    );

    params.onLoadStart!(
      InAppWebViewController.fromPlatform(
        platform: platform.lastController!,
      ),
      request.url,
    );
    expect(await loadStart.future, request.url);
  });

  testWidgets('uses default settings and permission callback', (tester) async {
    await _pumpWebView(tester, const Web3Webview());

    final params = platform.lastParams!;
    expect(params.initialSettings?.supportMultipleWindows, isTrue);
    expect(params.initialSettings?.allowsInlineMediaPlayback, isTrue);
    expect(params.onPermissionRequest, isNotNull);
  });

  testWidgets('registers FxWalletHandler only once', (tester) async {
    var createdCount = 0;
    await _pumpWebView(
      tester,
      Web3Webview(onWebViewCreated: (_) => createdCount++),
    );

    final controller = platform.lastController!;
    final params = platform.lastParams!;
    expect(controller.handlers.keys, ['FxWalletHandler']);
    expect(createdCount, 1);

    params.onWebViewCreated!(
      InAppWebViewController.fromPlatform(platform: controller),
    );

    expect(controller.handlers.keys, ['FxWalletHandler']);
    expect(createdCount, 2);
  });

  testWidgets('routes immediate requests through the JavaScript handler',
      (tester) async {
    await _pumpWebView(
      tester,
      Web3Webview(ethChainId: () async => 137),
    );

    final result = await platform.lastController!.handlers['FxWalletHandler']!(
      [
        {'method': 'eth_chainId'}
      ],
    );

    expect(result, '0x89');
  });

  testWidgets('evaluates chain change events through the WebView controller',
      (tester) async {
    await _pumpWebView(
      tester,
      Web3Webview(
        ethChainId: () async => 10,
        walletSwitchEthereumChain: (_) async => true,
      ),
    );
    final controller = platform.lastController!;
    final handler = controller.handlers['FxWalletHandler']!;

    final result = await tester.runAsync(
      () => handler([
        {
          'method': 'wallet_switchEthereumChain',
          'params': [
            {'chainId': '0xa'}
          ],
        }
      ]),
    );

    // EIP-3326: a successful switch resolves with null but still emits the
    // chainChanged event into the page.
    expect(result, isNull);
    expect(
      controller.evaluatedScripts,
      ['window.fxwallet.ethereum.emitChainChanged("0xa")'],
    );
  });

  testWidgets('serializes user-confirmed requests through the handler',
      (tester) async {
    final startedMessages = <String>[];
    await _pumpWebView(
      tester,
      Web3Webview(
        ethPersonalSign: (message) async {
          startedMessages.add(message);
          if (message == 'first') {
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
          return '$message-signature';
        },
      ),
    );
    final handler = platform.lastController!.handlers['FxWalletHandler']!;

    await tester.runAsync(() async {
      final first = handler([
        {
          'method': 'personal_sign',
          'params': ['first', '0xaddress'],
        }
      ]);
      final second = handler([
        {
          'method': 'personal_sign',
          'params': ['second', '0xaddress'],
        }
      ]);

      await Future<void>.delayed(Duration.zero);
      expect(startedMessages, ['first']);

      expect(await first, 'first-signature');
      expect(await second, 'second-signature');
      expect(startedMessages, ['first', 'second']);
    });
  });


  testWidgets('surfaces bridge request ids to the host controller',
      (tester) async {
    final controller = Web3RequestController();
    // Created inside `runAsync` below: a Completer built here would belong to
    // the fake-async zone, which is not pumped while `runAsync` runs, so
    // completing it would never wake the handler.
    late Completer<String> release;

    await _pumpWebView(
      tester,
      Web3Webview(
        requestController: controller,
        ethPersonalSign: (_) => release.future,
      ),
    );
    final handler = platform.lastController!.handlers['FxWalletHandler']!;

    await tester.runAsync(() async {
      release = Completer<String>();
      final signed = handler([
        {
          'method': 'personal_sign',
          'params': ['first', '0xaddress'],
          'id': 'fxwzz-1',
        }
      ]);
      final queued = handler([
        {
          'method': 'personal_sign',
          'params': ['second', '0xaddress'],
          'id': 'fxwzz-2',
        }
      ]);
      await Future<void>.delayed(Duration.zero);

      // The id minted by the in-page bridge is what the host sees.
      expect(controller.activeId, 'fxwzz-1');
      expect(controller.requests.map((e) => e.id), ['fxwzz-1', 'fxwzz-2']);
      expect(controller.requests.first.method, 'personal_sign');

      // The waiting request is cancelled by that id and fails on its own.
      expect(controller.cancel('fxwzz-2', reason: 'account switched'), isTrue);
      expect(
        await _errorOf(queued),
        isA<Web3RpcError>()
            .having((e) => e.code, 'code', 4900)
            .having((e) => e.message, 'message', 'account switched'),
      );

      release.complete('first-signature');
      expect(await signed, 'first-signature');
    });
  });

  testWidgets('falls back to synthetic ids for payloads without one',
      (tester) async {
    final controller = Web3RequestController();
    // Created inside `runAsync` below: a Completer built here would belong to
    // the fake-async zone, which is not pumped while `runAsync` runs, so
    // completing it would never wake the handler.
    late Completer<String> release;

    await _pumpWebView(
      tester,
      Web3Webview(
        requestController: controller,
        ethPersonalSign: (_) => release.future,
      ),
    );
    final handler = platform.lastController!.handlers['FxWalletHandler']!;

    await tester.runAsync(() async {
      release = Completer<String>();
      // A DApp calling `callHandler` by hand sends no id; the request is
      // still addressable, just not correlatable with the in-page promise.
      final signed = handler([
        {
          'method': 'personal_sign',
          'params': ['first', '0xaddress'],
        }
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(controller.activeId, 'local:1');

      release.complete('first-signature');
      expect(await signed, 'first-signature');
    });
  });

  testWidgets('rejects requests past the configured queue depth',
      (tester) async {
    // See the note above: the Completer must be born inside `runAsync`.
    late Completer<String> release;

    await _pumpWebView(
      tester,
      Web3Webview(
        maxPendingRequests: 1,
        ethPersonalSign: (_) => release.future,
      ),
    );
    final handler = platform.lastController!.handlers['FxWalletHandler']!;

    Future<dynamic> sign(String message) => handler([
          {
            'method': 'personal_sign',
            'params': [message, '0xaddress'],
          }
        ]);

    await tester.runAsync(() async {
      release = Completer<String>();
      final active = sign('first');
      await Future<void>.delayed(Duration.zero);
      final queued = sign('second');

      expect(
        await _errorOf(sign('third')),
        isA<Web3RpcError>().having((e) => e.code, 'code', -32005),
      );

      release.complete('signature');
      expect(await active, 'signature');
      expect(await queued, 'signature');
    });
  });

  testWidgets('drains the queue when the WebView is disposed', (tester) async {
    final controller = Web3RequestController();
    // Created inside `runAsync` below: a Completer built here would belong to
    // the fake-async zone, which is not pumped while `runAsync` runs, so
    // completing it would never wake the handler.
    late Completer<String> release;

    await _pumpWebView(
      tester,
      Web3Webview(
        requestController: controller,
        ethPersonalSign: (_) => release.future,
      ),
    );
    final handler = platform.lastController!.handlers['FxWalletHandler']!;

    late Future<Object?> activeResult;
    late Future<Object?> queuedResult;

    await tester.runAsync(() async {
      release = Completer<String>();
      // Observe both futures up front so the drain below never surfaces as
      // an unhandled async error.
      activeResult = _settle(handler([
        {
          'method': 'personal_sign',
          'params': ['first', '0xaddress'],
          'id': 'active',
        }
      ]));
      await Future<void>.delayed(Duration.zero);
      queuedResult = _settle(handler([
        {
          'method': 'personal_sign',
          'params': ['second', '0xaddress'],
          'id': 'queued',
        }
      ]));
    });

    // Tear the WebView down. `pumpWidget` must sit outside `runAsync`.
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    // The controller is released along with the widget.
    expect(controller.isAttached, isFalse);

    await tester.runAsync(() async {
      // The waiting request fails with 4900 instead of hanging forever.
      expect(
        await queuedResult,
        isA<Web3RpcError>().having((e) => e.code, 'code', 4900),
      );

      // The in-flight request was only flagged, so it still delivers: a flow
      // already past the point of no return is never torn out from under it.
      release.complete('first-signature');
      expect(await activeResult, 'first-signature');
    });
  });
}

/// Await [future] and return whatever it produced — value or error.
///
/// `expectLater` cannot be used inside `tester.runAsync`: it schedules onto
/// the test's fake-async zone, which the real-async block never pumps.
Future<Object?> _settle(Future<dynamic> future) =>
    future.then<Object?>((value) => value, onError: (Object error) => error);

/// Await [future] expecting it to fail, and return the error it threw.
Future<Object?> _errorOf(Future<dynamic> future) async {
  try {
    final value = await future;
    fail('Expected a failure but got: $value');
  } catch (error) {
    return error;
  }
}

Future<void> _pumpWebView(WidgetTester tester, Web3Webview webView) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: webView)));
  await tester.pump();
}
