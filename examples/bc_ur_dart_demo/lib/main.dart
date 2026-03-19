import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'common/app_theme.dart';
import 'common/session_store.dart';
import 'encode/form_page.dart';
import 'sign_flow/sign_flow_entry_page.dart';
import 'sign_flow/sign_result_page.dart';
import 'sign_flow/sign_step1_page.dart';
import 'sign_flow/sign_step2_page.dart';
import 'encode/qr_display_page.dart';
import 'encode/type_config.dart';
import 'encode/type_selector_page.dart';
import 'home_page.dart';
import 'scan/result_page.dart';
import 'scan/scan_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionStore()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: const BcUrDartExampleApp(),
    ),
  );
}

/// Theme state notifier for manual theme switching
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  String get themeLabel {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', name: 'home', builder: (_, __) => const HomePage()),

    // ── 扫码 ──────────────────────────────────────────────────
    GoRoute(path: '/scan', name: 'scan', builder: (_, __) => const ScanPage()),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (_, state) => ResultPage(urData: (state.extra as Map<String, dynamic>?) ?? {}),
    ),

    // ── 生成 ──────────────────────────────────────────────────
    GoRoute(
      path: '/encode',
      name: 'encode',
      builder: (_, __) => const TypeSelectorPage(),
    ),
    GoRoute(
      path: '/encode/form',
      name: 'form',
      builder: (context, state) {
        final config = state.extra as UrTypeConfig?;
        if (config == null) {
          return const Scaffold(
            body: Center(child: Text('Error: Missing UR type config')),
          );
        }
        return FormPage(config: config);
      },
    ),
    GoRoute(
      path: '/encode/qr',
      name: 'qr',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null || extra['type'] == null || extra['params'] == null) {
          return const Scaffold(
            body: Center(child: Text('Error: Missing QR params')),
          );
        }
        return QrDisplayPage(
          type: extra['type'] as String,
          params: extra['params'] as Map<String, dynamic>,
        );
      },
    ),

    // ── 签名流程 ──────────────────────────────────────────────
    GoRoute(
      path: '/sign_flow',
      name: 'sign_flow',
      builder: (_, __) => const SignFlowEntryPage(),
    ),
    GoRoute(
      path: '/sign_flow/step1',
      name: 'sign_step1',
      builder: (_, state) => SignStep1Page(config: state.extra as UrTypeConfig),
    ),
    GoRoute(
      path: '/sign_flow/step2',
      name: 'sign_step2',
      builder: (_, __) => const SignStep2Page(),
    ),
    GoRoute(
      path: '/sign_flow/result',
      name: 'sign_result',
      builder: (_, state) => SignResultPage(data: state.extra as Map<String, dynamic>),
    ),
  ],
);

class BcUrDartExampleApp extends StatelessWidget {
  const BcUrDartExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp.router(
          title: 'bc_ur_dart Demo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeNotifier.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}
