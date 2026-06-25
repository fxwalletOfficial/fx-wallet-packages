// Smoke test: the example UI builds and shows the trigger button WITHOUT loading
// native code. AleoFlutter.load() needs the build-time-bundled library, which is
// not present in the Dart test VM, so the test deliberately does not tap "run" —
// the real load/API acceptance happens on a simulator/emulator/device (spec §9).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aleo_flutter_example/main.dart';

void main() {
  testWidgets('renders the run button without invoking native code',
      (tester) async {
    await tester.pumpWidget(const AleoFlutterDemo());

    expect(find.byKey(const Key('run')), findsOneWidget);
    expect(find.text('Load & derive address'), findsOneWidget);
  });
}
