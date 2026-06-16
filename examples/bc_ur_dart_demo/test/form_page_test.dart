import 'package:bc_ur_dart_example/encode/form_page.dart';
import 'package:bc_ur_dart_example/encode/type_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('crypto multi accounts form generates params from chain list',
      (tester) async {
    final config = findConfig('crypto-multi-accounts')!;
    late Map<String, dynamic> qrExtra;

    final router = GoRouter(
      routes: [
        GoRoute(
          name: 'form',
          path: '/',
          builder: (_, __) => FormPage(config: config),
        ),
        GoRoute(
          name: 'qr',
          path: '/qr',
          builder: (_, state) {
            qrExtra = Map<String, dynamic>.from(state.extra as Map);
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Generate QR Code'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(qrExtra['type'], 'crypto-multi-accounts');
    final params = Map<String, dynamic>.from(qrExtra['params'] as Map);
    final chains = List<Map<String, dynamic>>.from(params['chains'] as List);

    expect(params['masterFingerprint'], '21d0ae26');
    expect(params['device'], 'Keystone 3 Pro');
    expect(params['deviceId'], '5d4a7f01b9225db8d1f510e0ee682c47b0c585d1');
    expect(params['version'], '2.0.4');
    expect(params['xfpFormat'], 'canonical');
    expect(chains, hasLength(3));
    expect(chains.first['childrenPath'], '0/*');
    expect(chains.first['publicKey'], startsWith('03d0f77d'));
    expect(chains.first['chainCode'], startsWith('9bdef1bf'));
    expect(chains.last['xpub'], isEmpty);
    expect(chains.last['publicKey'], startsWith('038e047b'));
  });
}
