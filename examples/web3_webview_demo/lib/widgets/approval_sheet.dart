import 'package:flutter/material.dart';

/// A single labelled row in the approval sheet.
typedef ApprovalRow = MapEntry<String, String>;

/// Modal confirmation sheet shown before the demo signs / sends / switches
/// chain on a DApp's behalf. Returns `true` when the user approves and
/// `false` (or `null`, treated as reject) when they cancel or dismiss.
///
/// The browser page maps a `false` result to an EIP-1193 `4001`
/// user-rejected error so the DApp sees the same rejection it would from a
/// real wallet.
class ApprovalSheet extends StatelessWidget {
  const ApprovalSheet({
    super.key,
    required this.title,
    required this.rows,
    this.method,
    this.confirmLabel = 'Approve',
    this.dangerous = false,
  });

  final String title;
  final List<ApprovalRow> rows;

  /// Raw method name (`personal_sign`, `eth_sendTransaction`, …) shown as a
  /// monospace chip so testers can see exactly what the DApp asked for.
  final String? method;

  final String confirmLabel;

  /// When true the confirm button uses the error colour — used for
  /// send-transaction so it visually stands apart from read-only signs.
  final bool dangerous;

  /// Present the sheet and resolve to the user's decision. A barrier tap or
  /// back gesture resolves to `false` (reject).
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required List<ApprovalRow> rows,
    String? method,
    String confirmLabel = 'Approve',
    bool dangerous = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ApprovalSheet(
        title: title,
        rows: rows,
        method: method,
        confirmLabel: confirmLabel,
        dangerous: dangerous,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleLarge),
                ),
                if (method != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(method!,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (final row in rows) _DetailRow(row: row),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: dangerous
                        ? FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                          )
                        : null,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.row});

  final ApprovalRow row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.key,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  )),
          const SizedBox(height: 2),
          SelectableText(
            row.value,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            maxLines: 6,
          ),
        ],
      ),
    );
  }
}
