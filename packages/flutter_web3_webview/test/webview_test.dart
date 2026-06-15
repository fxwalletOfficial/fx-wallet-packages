import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web3_webview/src/models/settings.dart';
import 'package:flutter_web3_webview/src/utils/provider.dart';
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
}

Future<void> _pumpWebView(WidgetTester tester, Web3Webview webView) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: webView)));
  await tester.pump();
}
