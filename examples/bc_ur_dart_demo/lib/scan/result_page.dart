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
          else ...[
            ...fields.entries.map((e) => CopyableField(label: e.key, value: e.value?.toString() ?? '—')),
            
            // ── Chain Details Section ─────────────────────────
            if (urData['chainDetails'] != null) ...[
              const SizedBox(height: 24),
              _ChainDetailsSection(
                chains: (urData['chainDetails'] as List).cast<Map<String, dynamic>>(),
              ),
            ],
          ],

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

/// Displays crypto-multi-accounts chain details with expandable cards
class _ChainDetailsSection extends StatelessWidget {
  const _ChainDetailsSection({required this.chains});
  final List<Map<String, dynamic>> chains;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.account_tree_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              'Chain Accounts',
              style: TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.w600, 
                color: scheme.onSurface,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${chains.length}',
                style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Chain list
        ...chains.asMap().entries.map((entry) {
          final index = entry.key;
          final chain = entry.value;
          return _ChainCard(index: index + 1, data: chain);
        }),
      ],
    );
  }
}

/// Individual chain card with expandable details
class _ChainCard extends StatefulWidget {
  const _ChainCard({required this.index, required this.data});
  final int index;
  final Map<String, dynamic> data;

  @override
  State<_ChainCard> createState() => _ChainCardState();
}

class _ChainCardState extends State<_ChainCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final data = widget.data;
    final coin = data['coin'] ?? 'Unknown';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Header (clickable to expand)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Coin badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      coin.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.w700, 
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Derivation path
                  Expanded(
                    child: Text(
                      data['derivationPath'] ?? '',
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Copy derivation path
                  GestureDetector(
                    onTap: () => CopyHelper.copy(context, data['derivationPath'] ?? '', label: 'Derivation Path'),
                    child: Tooltip(
                      message: 'Copy',
                      child: Icon(Icons.copy_rounded, size: 17, color: scheme.primary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Expand icon
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 20, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  // Chains label
                  _DetailRow(label: 'Chains', value: data['chains'] ?? ''),
                  _DetailRow(label: 'Public Key', value: data['publicKey'] ?? ''),
                  if ((data['chainCode'] as String?)?.isNotEmpty ?? false)
                    _DetailRow(label: 'Chain Code', value: data['chainCode'] ?? ''),
                  if ((data['extendedPublicKey'] as String?)?.isNotEmpty ?? false)
                    _DetailRow(label: 'Extended Public Key', value: data['extendedPublicKey'] ?? ''),
                  if ((data['masterFingerprint'] as String?)?.isNotEmpty ?? false)
                    _DetailRow(label: 'Master Fingerprint', value: data['masterFingerprint'] ?? ''),
                ],
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Single detail row with label and copyable value
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueColor = scheme.onSurface.withValues(alpha: 0.8);
    
    return CopyableField(
      label: label,
      value: value,
      labelFontSize: 10,
      valueFontSize: 12,
      iconSize: 15,
      padding: const EdgeInsets.only(bottom: 8),
      valueColor: valueColor,
    );
  }
}
