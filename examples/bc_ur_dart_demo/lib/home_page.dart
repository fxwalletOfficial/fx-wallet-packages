import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'main.dart' show ThemeNotifier;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('bc_ur_dart Demo'),
        actions: [
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, _) {
              return IconButton(
                icon: Icon(_getThemeIcon(themeNotifier.themeMode)),
                tooltip: 'Theme: ${themeNotifier.themeLabel}',
                onPressed: () => themeNotifier.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'bc_ur_dart Demo',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.qr_code_2, size: 48),
              applicationLegalese: 'Debug & development tool App',
              children: [
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Text('Supported Chains',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChip('ETH'),
                    _buildChip('Cosmos'),
                    _buildChip('Solana'),
                    _buildChip('Tron'),
                    _buildChip('Alephium'),
                    _buildChip('PSBT'),
                    _buildChip('GSPL'),
                    _buildChip('CryptoHDKey'),
                    _buildChip('CryptoMultiAccounts'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Top Info ─────────────────────────────────────
          _InfoBanner(scheme: scheme),
          const SizedBox(height: 24),

          // ── Sprint 1: Scan ────────────────────────────
          _SectionLabel(title: 'Scan', icon: Icons.qr_code_scanner),
          const SizedBox(height: 8),
          _ModuleCard(
            title: 'Scan UR QR Code',
            subtitle: 'Supports multi-frame QR, auto type detection, all fields copyable',
            icon: Icons.camera_alt_outlined,
            color: scheme.tertiary,
            onTap: () => context.pushNamed('scan'),
          ),

          const SizedBox(height: 24),

          // ── Sprint 2: Generate ─────────────────────────
          _SectionLabel(title: 'Generate QR', icon: Icons.qr_code),
          const SizedBox(height: 8),
          _ModuleCard(
            title: 'Fill Params → Generate QR',
            subtitle: 'Select UR type, fill or use mock data, generate scannable QR',
            icon: Icons.edit_note_outlined,
            color: scheme.primary,
            onTap: () => context.pushNamed('encode'),
          ),

          const SizedBox(height: 24),

          // ── Sprint 3: Signing ───────────────────────────
          _SectionLabel(title: 'Signing Flow', icon: Icons.verified_outlined),
          const SizedBox(height: 8),
          _ModuleCard(
            title: 'Two-Step Sign Flow',
            subtitle: 'Step 1 — Initiate Sign Request\nStep 2 — Scan Signature Result',
            icon: Icons.verified_outlined,
            color: const Color(0xFF1D9E75),
            onTap: () => context.pushNamed('sign_flow'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }
}

// ── Sub Widgets ────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_2, color: scheme.primary, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('bc_ur_dart debugging tool',
                    style: TextStyle(fontWeight: FontWeight.w600, color: scheme.primary, fontSize: 14)),
                const SizedBox(height: 2),
                Text('Mock data only · No real on-chain transactions',
                    style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    return Row(children: [
      Icon(icon, size: 16, color: c),
      const SizedBox(width: 6),
      Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c, letterSpacing: 0.4)),
    ]);
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      if (badge != null) ...[
                        const SizedBox(width: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(badge!,
                              style: TextStyle(fontSize: 10, color: scheme.onSecondaryContainer, fontWeight: FontWeight.w500)),
                        ),
                      ]
                    ]),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.55), height: 1.4)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurface.withValues(alpha: 0.25)),
            ],
          ),
        ),
      ),
    );
  }
}

