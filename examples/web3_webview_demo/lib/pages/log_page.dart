import 'package:flutter/material.dart';

import 'package:web3_webview_demo/services/bridge_log.dart';
import 'package:web3_webview_demo/widgets/debug_panel.dart';

/// Full-screen bridge-log viewer reached from Settings. Reuses
/// [BridgeLogList] so entries render the same as the browser-page sheet.
class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final log = BridgeLogScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bridge log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear',
            onPressed: log.clear,
          ),
        ],
      ),
      body: BridgeLogList(log: log),
    );
  }
}
