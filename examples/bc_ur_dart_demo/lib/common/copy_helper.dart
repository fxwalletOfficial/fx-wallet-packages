import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyHelper {
  CopyHelper._();

  static Future<void> copy(BuildContext context, String text, {String? label}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label != null ? 'Copied $label' : 'Copied to clipboard'),
          duration: const Duration(milliseconds: 1500),
          width: 220,
        ),
      );
    }
  }
}

/// 单行可复制字段 Widget — 显示 label + 值，整行可点击复制
class CopyableField extends StatelessWidget {
  const CopyableField({
    super.key,
    required this.label,
    required this.value,
    this.labelFontSize = 11,
    this.valueFontSize = 13,
    this.iconSize = 17,
    this.padding = const EdgeInsets.symmetric(vertical: 5),
    this.valueColor,
  });

  final String label;
  final String value;
  final double labelFontSize;
  final double valueFontSize;
  final double iconSize;
  final EdgeInsets padding;
  final Color? valueColor;

  void _handleTap(BuildContext context) {
    CopyHelper.copy(context, value, label: label);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: labelFontSize, color: scheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500, letterSpacing: 0.3),
          ),
          const SizedBox(height: 3),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _handleTap(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SelectableText(
                        value,
                        style: TextStyle(fontSize: valueFontSize, fontFamily: 'monospace', height: 1.5, color: valueColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy_rounded, size: iconSize, color: scheme.primary.withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
