import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web3_webview_demo/app.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

void main() {
  void useTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
  }

  testWidgets('EVM account picker updates WalletState', (tester) async {
    useTallViewport(tester);
    final wallet = WalletState();
    addTearDown(wallet.dispose);

    await tester.pumpWidget(DemoApp(walletState: wallet));
    await tester.pumpAndSettle();
    await openSettings(tester);

    expect(wallet.evmAccountIndex, 0);
    await tester.tap(find.text(kDemoAccounts[1].evmAddress));
    await tester.pumpAndSettle();
    expect(wallet.evmAccountIndex, 1);
  });

  testWidgets('EVM chain picker updates WalletState', (tester) async {
    useTallViewport(tester);
    final wallet = WalletState();
    addTearDown(wallet.dispose);

    await tester.pumpWidget(DemoApp(walletState: wallet));
    await tester.pumpAndSettle();
    await openSettings(tester);

    expect(wallet.evmChainId, 1);
    // Tap the Polygon row (subtitle carries the chainId).
    await tester.tap(find.text('chainId 137 · MATIC'));
    await tester.pumpAndSettle();
    expect(wallet.evmChainId, 137);
  });

  testWidgets('Solana cluster picker updates WalletState', (tester) async {
    useTallViewport(tester);
    final wallet = WalletState();
    addTearDown(wallet.dispose);

    await tester.pumpWidget(DemoApp(walletState: wallet));
    await tester.pumpAndSettle();
    await openSettings(tester);

    expect(wallet.solanaClusterId, 'mainnet-beta');
    await tester.tap(find.text('Solana Devnet'));
    await tester.pumpAndSettle();
    expect(wallet.solanaClusterId, 'devnet');
  });

  testWidgets('independent EVM and Solana account selection', (tester) async {
    useTallViewport(tester);
    final wallet = WalletState();
    addTearDown(wallet.dispose);

    await tester.pumpWidget(DemoApp(walletState: wallet));
    await tester.pumpAndSettle();
    await openSettings(tester);

    // The EVM and Solana account sections both list the same labels; the
    // Solana radios sit lower, so tap the *last* "Account 3" occurrence.
    await tester.tap(find.text('Account 3').last);
    await tester.pumpAndSettle();

    expect(wallet.solanaAccountIndex, 2);
    expect(wallet.evmAccountIndex, 0, reason: 'EVM selection unchanged');
  });
}
