import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../common/copy_helper.dart';
import '../common/session_store.dart';

class SignResultPage extends StatelessWidget {
  const SignResultPage({super.key, required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final matched = data['matched'] as bool? ?? false;
    final isError = data['isError'] as bool? ?? false;
    final scannedId = data['scannedRequestId'] as String?;
    final sessionId = data['sessionRequestId'] as String?;
    final coinType = data['coinType'] as String? ?? '—';
    final parsed = data['parsed'] as Map<String, dynamic>? ?? {};
    final fields =
        (parsed['fields'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signing Result'),
        actions: [
          // 一键复制全部
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'Copy all',
            onPressed: () {
              final buf = StringBuffer();
              buf.writeln('Coin: $coinType');
              buf.writeln('Validation: ${matched ? "PASSED" : "FAILED"}');
              buf.writeln('Session requestId: $sessionId');
              buf.writeln('Signature requestId: $scannedId');
              buf.writeln('');
              fields.forEach((k, v) => buf.writeln('$k: $v'));
              CopyHelper.copy(context, buf.toString(), label: 'Signing Result');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── 校验结果 Banner ──────────────────────────────────
          _VerifyBanner(matched: matched, isError: isError),
          const SizedBox(height: 20),

          // ── requestId 对比 ───────────────────────────────────
          _IdCompareCard(
            sessionId: sessionId,
            scannedId: scannedId,
            matched: matched,
          ),
          const SizedBox(height: 20),

          // ── Signature 字段 ───────────────────────────────────
          Text(
            'Signature Data',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: 0.5),
                letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          ...fields.entries
              .where((e) => e.key != 'requestId') // requestId 已在上面展示
              .map((e) =>
                  CopyableField(label: e.key, value: e.value?.toString() ?? '—')),

          const SizedBox(height: 32),

          // ── 操作按钮 ─────────────────────────────────────────
          if (!matched) ...[
            FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan again'),
              onPressed: () {
                context.pop(); // 回到 step2
              },
            ),
            const SizedBox(height: 10),
          ],

          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Start new signing'),
            onPressed: () {
              context.read<SessionStore>().clearSignSession();
              context.go('/sign_flow');
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.home_outlined),
            label: const Text('Return home'),
            onPressed: () {
              context.read<SessionStore>().clearSignSession();
              context.goNamed('home');
            },
          ),
        ],
      ),
    );
  }
}

// ── 子 Widgets ───────────────────────────────────────────────────

class _VerifyBanner extends StatelessWidget {
  const _VerifyBanner({required this.matched, required this.isError});
  final bool matched;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (isError) {
      return _Banner(
        color: scheme.errorContainer,
        icon: Icons.error_outline,
        iconColor: scheme.error,
        title: 'Parse Failed',
        subtitle: 'Scanned QR cannot be parsed as a valid Signature',
      );
    }

    if (matched) {
      return _Banner(
        color: const Color(0xFFE1F5EE),
        icon: Icons.verified_rounded,
        iconColor: const Color(0xFF1D9E75),
        title: 'requestId Validation Passed',
        subtitle: 'Signature matches this signing request',
      );
    }

    return _Banner(
      color: scheme.errorContainer.withValues(alpha:0.4),
      icon: Icons.warning_amber_rounded,
      iconColor: scheme.error,
      title: 'requestId Mismatch',
      subtitle: 'Signature requestId does not match current Session — please confirm you scanned the correct QR',
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: iconColor)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: iconColor.withValues(alpha:0.75),
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdCompareCard extends StatelessWidget {
  const _IdCompareCard({
    required this.sessionId,
    required this.scannedId,
    required this.matched,
  });
  final String? sessionId;
  final String? scannedId;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matchColor =
        matched ? const Color(0xFF1D9E75) : scheme.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha:0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request ID Comparison',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha:0.55))),
          const SizedBox(height: 12),

          // Session（Step1 生成）
          _IdRow(
            label: 'Step 1 Generated',
            id: sessionId ?? '—',
            icon: Icons.send_outlined,
          ),

          const SizedBox(height: 2),
          Center(
            child: Icon(
              matched ? Icons.check_circle : Icons.close,
              color: matchColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 2),

          // Scanned（Step2 扫描）
          _IdRow(
            label: 'Step 2 Scanned',
            id: scannedId ?? '—',
            icon: Icons.qr_code_scanner,
          ),
        ],
      ),
    );
  }
}

class _IdRow extends StatelessWidget {
  const _IdRow({required this.label, required this.id, required this.icon});
  final String label;
  final String id;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: scheme.onSurface.withValues(alpha:0.45)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha:0.45))),
              const SizedBox(height: 2),
              SelectableText(
                id,
                style: const TextStyle(
                    fontSize: 12, fontFamily: 'monospace', height: 1.4),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => CopyHelper.copy(context, id, label: label),
          child: Icon(Icons.copy_rounded,
              size: 15, color: scheme.primary),
        ),
      ],
    );
  }
}
