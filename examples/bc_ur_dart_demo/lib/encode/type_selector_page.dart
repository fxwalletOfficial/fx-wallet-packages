import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'type_config.dart';

class TypeSelectorPage extends StatelessWidget {
  const TypeSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = kUrTypesByGroup;

    return Scaffold(
      appBar: AppBar(title: const Text('Select UR Type')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: groups.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GroupHeader(label: entry.key),
              ...entry.value.map((config) => _TypeTile(config: config)),
              const SizedBox(height: 4),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c, letterSpacing: 0.6)));
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.config});
  final UrTypeConfig config;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(config.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Text(
        config.type,
        style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: scheme.onSurface.withValues(alpha: 0.45)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.isSignRequest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Sign', style: TextStyle(fontSize: 10, color: scheme.onTertiaryContainer)),
            ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: scheme.onSurface.withValues(alpha: 0.3), size: 20),
        ],
      ),
      onTap: () => context.pushNamed(
        'form',
        extra: config,
      ),
    );
  }
}
