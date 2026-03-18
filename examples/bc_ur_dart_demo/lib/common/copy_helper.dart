import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyHelper {
  CopyHelper._();

  static Future<void> copy(BuildContext context, String text, {String? label}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(label != null ? '已复制 $label' : '已复制到剪贴板'),
          duration: const Duration(milliseconds: 1500),
          width: 220,
        ),
      );
    }
  }
}

/// 单行可复制字段 Widget — 显示 label + 值，右侧复制按钮
class CopyableField extends StatelessWidget {
  const CopyableField({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: scheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500, letterSpacing: 0.3),
          ),
          const SizedBox(height: 3),
          Container(
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
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace', height: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => CopyHelper.copy(context, value, label: label),
                  child: Tooltip(
                    message: '复制',
                    child: Icon(Icons.copy_rounded, size: 17, color: scheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
