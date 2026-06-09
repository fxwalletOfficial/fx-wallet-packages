import 'package:flutter/material.dart';

import 'package:web3_webview_demo/services/bridge_log.dart';

/// Bottom-sheet view of the [BridgeLog]. Phase 3 surfaces it from the
/// browser page's AppBar so a tester can immediately see the request /
/// response JSON for whatever the DApp just triggered. Phase 6 reuses the
/// same entry rendering in the full settings log viewer.
class DebugPanel extends StatelessWidget {
  const DebugPanel({super.key, required this.log});

  final BridgeLog log;

  static Future<void> show(BuildContext context, BridgeLog log) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, controller) => DebugPanel(log: log),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: log,
      builder: (context, _) {
        final entries = log.entries.reversed.toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Bridge log',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: log.clear,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('No bridge calls yet'))
                  : ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) => _LogTile(entry: entries[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final BridgeLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (entry.status) {
      BridgeLogStatus.pending => (Icons.hourglass_empty, Colors.orange),
      BridgeLogStatus.success => (Icons.check_circle_outline, Colors.green),
      BridgeLogStatus.error => (Icons.error_outline, Colors.red),
    };
    final ms = entry.elapsedMicros == null
        ? ''
        : ' · ${(entry.elapsedMicros! / 1000).toStringAsFixed(1)}ms';

    return ExpansionTile(
      leading: Icon(icon, color: color),
      title: Text(entry.method,
          style: const TextStyle(fontFamily: 'monospace')),
      subtitle: Text('${_time(entry.timestamp)}$ms'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _JsonBlock(label: 'request', value: entry.request),
        if (entry.response != null)
          _JsonBlock(label: 'response', value: entry.response),
      ],
    );
  }

  String _time(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

class _JsonBlock extends StatelessWidget {
  const _JsonBlock({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
          const SizedBox(height: 2),
          SelectableText(
            '$value',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
