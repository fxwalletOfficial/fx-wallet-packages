import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common/copy_helper.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({super.key, required this.urData});

  /// urData format:
  /// { 'type': 'eth-sign-request', 'fields': { 'requestId': '...', ... }, 'isError': false }
  final Map<String, dynamic> urData;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = urData['type'] as String? ?? 'unknown';
    final fields = (urData['fields'] as Map<String, dynamic>?) ?? {};
    final isError = urData['isError'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'Copy all fields',
            onPressed: () {
              final buf = StringBuffer('UR Type: $type\n\n');
              fields.forEach((k, v) => buf.writeln('$k: $v'));
              CopyHelper.copy(context, buf.toString(), label: 'All fields');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Type Badge Row ──────────────────────────────────
          Row(
            children: [
              _TypeBadge(type: type, isError: isError),
              const Spacer(),
              Text(
                '${fields.length} fields',
                style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.45)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Field List ────────────────────────────────────
          if (isError)
            _ErrorSection(fields: fields)
          else
            ...fields.entries.map((e) => CopyableField(label: e.key, value: e.value?.toString() ?? '—')),

          const SizedBox(height: 32),

          // ── Action Buttons ──────────────────────────────────
          FilledButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Again'),
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
            onPressed: () => context.goNamed('home'),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.isError});
  final String type;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isError ? scheme.errorContainer : scheme.primaryContainer;
    final fg = isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    final icon = isError ? Icons.error_outline : Icons.verified_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(
            type,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  const _ErrorSection({required this.fields});
  final Map<String, dynamic> fields;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.warning_amber_rounded, color: scheme.error, size: 18),
            const SizedBox(width: 8),
            Text('Parse Failed', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.error)),
          ]),
          const SizedBox(height: 12),
          ...fields.entries.map((e) => CopyableField(label: e.key, value: e.value.toString())),
        ],
      ),
    );
  }
}
