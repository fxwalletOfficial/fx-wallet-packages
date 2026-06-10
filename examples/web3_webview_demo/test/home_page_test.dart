import 'package:flutter_test/flutter_test.dart';

import 'package:web3_webview_demo/app.dart';
import 'package:web3_webview_demo/data/chains.dart';
import 'package:web3_webview_demo/data/dapps.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

void main() {
  group('HomePage', () {
    testWidgets('renders the active identity card on first paint',
        (tester) async {
      final wallet = WalletState();
      addTearDown(wallet.dispose);

      await tester.pumpWidget(DemoApp(walletState: wallet));
      await tester.pumpAndSettle();

      expect(find.text(kDemoAccounts.first.label), findsOneWidget);
      expect(find.text('Ethereum'), findsOneWidget);
    });

    testWidgets('settings gear pushes the settings page', (tester) async {
      final wallet = WalletState();
      addTearDown(wallet.dispose);

      await tester.pumpWidget(DemoApp(walletState: wallet));
      await tester.pumpAndSettle();

      expect(find.text('Web3 WebView Demo'), findsOneWidget);
      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Active EVM chain'), findsOneWidget);
    });

    testWidgets(
      'WalletState changes propagate via InheritedNotifier without third-party state',
      (tester) async {
        final wallet = WalletState();
        addTearDown(wallet.dispose);

        await tester.pumpWidget(DemoApp(walletState: wallet));
        await tester.pumpAndSettle();

        // Default chain is Ethereum (chainId 1).
        expect(find.textContaining('Ethereum'), findsOneWidget);

        // Switch to Polygon and confirm the home card rebuilds.
        wallet.evmChainId = 137;
        await tester.pumpAndSettle();
        expect(find.textContaining('Polygon'), findsOneWidget);
      },
    );
  });

  group('chain + dapp registries', () {
    test('every kEvmChains entry has a unique chainId', () {
      final ids = kEvmChains.map((c) => c.chainId).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every kDAppCatalog entry has a non-empty URL and a known scheme',
        () {
      for (final dapp in kDAppCatalog) {
        expect(dapp.url, isNotEmpty, reason: dapp.name);
        final uri = Uri.parse(dapp.url);
        expect(uri.hasScheme, isTrue, reason: dapp.name);
        expect(uri.scheme, anyOf('http', 'https'), reason: dapp.name);
      }
    });

    test('evmChainById falls back to mainnet for unknown ids', () {
      expect(evmChainById(99999).chainId, kEvmChains.first.chainId);
    });
  });
}
