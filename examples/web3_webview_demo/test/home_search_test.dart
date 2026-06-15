import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web3_webview_demo/app.dart';
import 'package:web3_webview_demo/services/recent_visits.dart';
import 'package:web3_webview_demo/services/wallet_state.dart';

void main() {
  testWidgets('search field filters the bookmark grid to matching dApps',
      (tester) async {
    final wallet = WalletState();
    addTearDown(wallet.dispose);

    await tester.pumpWidget(DemoApp(walletState: wallet));
    await tester.pumpAndSettle();

    // Grouped category headers are visible before searching.
    expect(find.text('DeFi'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Search bookmarks'), 'jupiter');
    await tester.pumpAndSettle();

    // Search mode replaces the grouped headers with a result count.
    expect(find.text('DeFi'), findsNothing);
    expect(find.textContaining('result(s)'), findsOneWidget);
    expect(find.text('Jupiter'), findsOneWidget);
    expect(find.text('Uniswap'), findsNothing);
  });

  testWidgets('search with no matches shows the empty-state message',
      (tester) async {
    final wallet = WalletState();
    addTearDown(wallet.dispose);

    await tester.pumpWidget(DemoApp(walletState: wallet));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Search bookmarks'), 'zzzznope');
    await tester.pumpAndSettle();

    expect(find.textContaining('No dApps match'), findsOneWidget);
  });

  testWidgets('a recorded recent visit surfaces a Recent chip',
      (tester) async {
    final wallet = WalletState();
    final recent = RecentVisits();
    addTearDown(wallet.dispose);
    addTearDown(recent.dispose);

    await tester.pumpWidget(
        DemoApp(walletState: wallet, recentVisits: recent));
    await tester.pumpAndSettle();

    // No Recent section until something is recorded.
    expect(find.text('Recent'), findsNothing);

    recent.record(url: 'https://app.uniswap.org', title: 'Uniswap');
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
    // The ActionChip carries the recorded title.
    expect(find.widgetWithText(ActionChip, 'Uniswap'), findsOneWidget);
  });

  testWidgets('invalid custom URL shows an inline error', (tester) async {
    final wallet = WalletState();
    addTearDown(wallet.dispose);

    await tester.pumpWidget(DemoApp(walletState: wallet));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Open a custom URL'), 'not a url');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid http(s) URL or host'), findsOneWidget);
  });
}
