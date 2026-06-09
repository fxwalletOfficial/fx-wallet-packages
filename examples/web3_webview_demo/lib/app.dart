import 'package:flutter/material.dart';

import 'package:web3_webview_demo/pages/browser_page.dart';
import 'package:web3_webview_demo/pages/home_page.dart';
import 'package:web3_webview_demo/pages/settings_page.dart';
import 'package:web3_webview_demo/services/bridge_log.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

/// Root widget. Hosts the two long-lived services ([WalletState],
/// [BridgeLog]) at the top of the tree via the matching `*Scope`
/// [InheritedNotifier]s so every descendant can read or subscribe without
/// pulling in a third-party state-management package.
class DemoApp extends StatefulWidget {
  const DemoApp({
    super.key,
    WalletState? walletState,
    BridgeLog? bridgeLog,
  })  : _walletState = walletState,
        _bridgeLog = bridgeLog;

  // Tests inject their own instances so each `pumpWidget` starts from a
  // known state; production code constructs the defaults in [initState].
  final WalletState? _walletState;
  final BridgeLog? _bridgeLog;

  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  late final WalletState _walletState;
  late final BridgeLog _bridgeLog;

  @override
  void initState() {
    super.initState();
    _walletState = widget._walletState ?? WalletState();
    _bridgeLog = widget._bridgeLog ?? BridgeLog();
  }

  @override
  void dispose() {
    if (widget._walletState == null) _walletState.dispose();
    if (widget._bridgeLog == null) _bridgeLog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WalletStateScope(
      notifier: _walletState,
      child: BridgeLogScope(
        notifier: _bridgeLog,
        child: MaterialApp(
          title: 'Flutter Web3 WebView Demo',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          initialRoute: '/',
          onGenerateRoute: _onGenerateRoute,
        ),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomePage(),
        );
      case '/settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsPage(),
        );
      case '/browser':
        final args = settings.arguments;
        if (args is! BrowserPageArgs) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const _RouteErrorPage(
                message: 'Browser route requires a BrowserPageArgs'),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BrowserPage(args: args),
        );
      default:
        return null;
    }
  }
}

class _RouteErrorPage extends StatelessWidget {
  const _RouteErrorPage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routing error')),
      body: Center(child: Text(message)),
    );
  }
}
