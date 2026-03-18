import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'common/app_theme.dart';
import 'common/session_store.dart';
import 'home_page.dart';
import 'scan/result_page.dart';
import 'scan/scan_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => SessionStore(),
      child: const BcUrDartExampleApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', name: 'home', builder: (_, __) => const HomePage()),
    GoRoute(path: '/scan', name: 'scan', builder: (_, __) => const ScanPage()),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (_, state) => ResultPage(urData: (state.extra as Map<String, dynamic>?) ?? {}),
    ),
  ],
);

class BcUrDartExampleApp extends StatelessWidget {
  const BcUrDartExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'bc_ur_dart Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
