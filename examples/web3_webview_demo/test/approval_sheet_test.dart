import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:web3_webview_demo/widgets/approval_sheet.dart';

void main() {
  // Pumps a host with an "open" button that stores the sheet's result into
  // [resultBox] when the async `ApprovalSheet.show` completes. Tests tap
  // "open", then drive the sheet and read `resultBox.value`.
  Future<void> pumpHost(WidgetTester tester, List<bool?> resultBox) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              resultBox[0] = await ApprovalSheet.show(
                context,
                title: 'Sign message',
                method: 'personal_sign',
                rows: const [
                  MapEntry('Account', '0xabc'),
                  MapEntry('Message', 'gm'),
                ],
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders title, method chip, and detail rows', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ApprovalSheet(
          title: 'Sign message',
          method: 'personal_sign',
          rows: [
            MapEntry('Account', '0xabc'),
            MapEntry('Message', 'gm'),
          ],
        ),
      ),
    ));

    expect(find.text('Sign message'), findsOneWidget);
    expect(find.text('personal_sign'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('gm'), findsOneWidget);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('Approve resolves to true', (tester) async {
    final result = <bool?>[null];
    await pumpHost(tester, result);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    expect(result[0], isTrue);
  });

  testWidgets('Reject resolves to false', (tester) async {
    final result = <bool?>[null];
    await pumpHost(tester, result);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();
    expect(result[0], isFalse);
  });

  testWidgets('barrier dismiss resolves to false', (tester) async {
    final result = <bool?>[null];
    await pumpHost(tester, result);

    // Tap above the sheet to dismiss it via the modal barrier.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(result[0], isFalse);
  });
}
