import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../encode/type_config.dart';

/// 签名流程的所有支持币种（仅 SignRequest 类型）
final kSignFlowTypes = kUrTypeConfigs.where((c) => c.isSignRequest).toList();

class SignFlowEntryPage extends StatelessWidget {
  const SignFlowEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final groups = <String, List<UrTypeConfig>>{};
    for (final c in kSignFlowTypes) {
      groups.putIfAbsent(c.group, () => []).add(c);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Flow — Select Coin')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 流程说明
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 18, color: scheme.tertiary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Two-Step Signing Flow', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: scheme.onTertiaryContainer)),
                      const SizedBox(height: 4),
                      Text(
                        'Step 1: Build SignRequest → Show animated QR (hardware wallet scans)\n'
                        'Step 2: Scan hardware wallet\'s Signature QR → Validate requestId',
                        style: TextStyle(fontSize: 12, color: scheme.onTertiaryContainer.withValues(alpha: 0.8), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 币种列表
          Expanded(
            child: ListView(
              children: groups.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GroupHeader(label: entry.key),
                    ...entry.value.map((config) => _CoinTile(config: config)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
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

class _CoinTile extends StatelessWidget {
  const _CoinTile({required this.config});
  final UrTypeConfig config;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(
        // 去掉 "Sign Request" 后缀，只显示币种名
        config.label.replaceAll(' Sign Request', ''),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        config.type,
        style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: scheme.onSurface.withValues(alpha: 0.45)),
      ),
      trailing: Icon(Icons.chevron_right, color: scheme.onSurface.withValues(alpha: 0.3), size: 20),
      onTap: () => context.pushNamed('sign_step1', extra: config),
    );
  }
}
