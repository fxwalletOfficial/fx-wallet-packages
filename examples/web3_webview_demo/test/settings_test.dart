import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web3_webview_demo/app.dart';
import 'package:web3_webview_demo/services/bridge_log.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

void main() {
  // The settings screen is a long ListView; a tall viewport keeps the
  // behaviour toggles + diagnostics tile on-screen so finders don't have
  // to scroll lazily-built rows into view.
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('auto-approve switch reflects and mutates WalletState',
      (tester) async {
    useTallViewport(tester);
    final wallet = WalletState(autoApproveReadMethods: true);
    addTearDown(wallet.dispose);

    await tester.pumpWidget(DemoApp(walletState: wallet));
    await tester.pumpAndSettle();
    await openSettings(tester);

    final switchFinder = find.widgetWithText(
        SwitchListTile, 'Auto-approve read-only methods');
    expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(wallet.autoApproveReadMethods, isFalse);
    expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
  });

  testWidgets('real-broadcast switch warns on a non-testnet chain',
      (tester) async {
    useTallViewport(tester);
    final wallet = WalletState(evmChainId: 1); // Ethereum mainnet
    addTearDown(wallet.dispose);

    await tester.pumpWidget(DemoApp(walletState: wallet));
    await tester.pumpAndSettle();
    await openSettings(tester);

    final switchFinder = find.widgetWithText(
        SwitchListTile, 'Broadcast transactions over RPC');
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(wallet.realBroadcast, isTrue);
    expect(find.textContaining('not a'), findsOneWidget);
    expect(find.textContaining('Ethereum'), findsWidgets);
  });

  testWidgets('bridge-log tile shows the entry count and opens the viewer',
      (tester) async {
    useTallViewport(tester);
    final wallet = WalletState();
    final log = BridgeLog();
    addTearDown(wallet.dispose);
    addTearDown(log.dispose);

    log.record(method: 'eth_accounts', response: ['0xabc']);
    log.record(method: 'personal_sign', response: '0xsig');

    await tester.pumpWidget(DemoApp(walletState: wallet, bridgeLog: log));
    await tester.pumpAndSettle();
    await openSettings(tester);

    // Count badge.
    expect(find.widgetWithText(Chip, '2'), findsOneWidget);

    await tester.tap(find.text('Bridge call log'));
    await tester.pumpAndSettle();

    // Full-screen viewer with both entries.
    expect(find.widgetWithText(AppBar, 'Bridge log'), findsOneWidget);
    expect(find.text('eth_accounts'), findsOneWidget);
    expect(find.text('personal_sign'), findsOneWidget);
  });

  testWidgets('log viewer Clear empties the list', (tester) async {
    useTallViewport(tester);
    final wallet = WalletState();
    final log = BridgeLog();
    addTearDown(wallet.dispose);
    addTearDown(log.dispose);

    log.record(method: 'eth_chainId', response: '0x1');

    await tester.pumpWidget(DemoApp(walletState: wallet, bridgeLog: log));
    await tester.pumpAndSettle();
    await openSettings(tester);
    await tester.tap(find.text('Bridge call log'));
    await tester.pumpAndSettle();

    expect(find.text('eth_chainId'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('eth_chainId'), findsNothing);
    expect(find.text('No bridge calls yet'), findsOneWidget);
  });
}
