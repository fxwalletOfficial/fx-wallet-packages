import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common/mock_data.dart';
import 'type_config.dart';

class FormPage extends StatefulWidget {
  const FormPage({super.key, required this.config});
  final UrTypeConfig config;

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _dropdownValues = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    final mock = kMockByType[widget.config.type] ?? {};

    for (final field in widget.config.fields) {
      final mockVal = mock[field.key];

      if (field.type == FieldType.dropdown) {
        _dropdownValues[field.key] = mockVal?.toString() ?? field.options!.first;
      } else if (field.type == FieldType.jsonList || field.type == FieldType.jsonMap) {
        final encoded = mockVal != null ? const JsonEncoder.withIndent('  ').convert(mockVal) : (field.type == FieldType.jsonList ? '[]' : '{}');
        _controllers[field.key] = TextEditingController(text: encoded);
      } else {
        _controllers[field.key] = TextEditingController(text: mockVal?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _collectParams() {
    final params = <String, dynamic>{};
    for (final field in widget.config.fields) {
      if (field.type == FieldType.dropdown) {
        params[field.key] = _dropdownValues[field.key];
      } else if (field.type == FieldType.jsonList || field.type == FieldType.jsonMap) {
        final text = _controllers[field.key]!.text.trim();
        if (text.isNotEmpty && text != '[]' && text != '{}') {
          try {
            params[field.key] = jsonDecode(text);
          } catch (_) {
            params[field.key] = text; // 让 encoder 层抛错
          }
        }
      } else {
        final val = _controllers[field.key]!.text.trim();
        if (val.isNotEmpty) params[field.key] = val;
      }
    }
    return params;
  }

  void _onGenerate() {
    if (!_formKey.currentState!.validate()) return;
    final params = _collectParams();
    context.pushNamed('qr', extra: {
      'type': widget.config.type,
      'params': params,
    });
  }

  void _onFillMock() {
    final mock = kMockByType[widget.config.type] ?? {};
    setState(() {
      for (final field in widget.config.fields) {
        final mockVal = mock[field.key];
        if (mockVal == null) continue;
        if (field.type == FieldType.dropdown) {
          _dropdownValues[field.key] = mockVal.toString();
        } else if (field.type == FieldType.jsonList || field.type == FieldType.jsonMap) {
          _controllers[field.key]?.text = const JsonEncoder.withIndent('  ').convert(mockVal);
        } else {
          _controllers[field.key]?.text = mockVal.toString();
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mock data filled'),
        duration: Duration(seconds: 1),
        width: 200,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.label),
        actions: [
          TextButton(
            onPressed: _onFillMock,
            child: const Text('Mock Data'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            // 类型标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.config.type,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: scheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(height: 16),

            // 字段列表
            ...widget.config.fields.map((field) => _buildField(field)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            onPressed: _onGenerate,
            icon: const Icon(Icons.qr_code),
            label: const Text('Generate QR Code'),
          ),
        ),
      ),
    );
  }

  Widget _buildField(FieldConfig field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: switch (field.type) {
        FieldType.dropdown => _buildDropdown(field),
        FieldType.jsonList || FieldType.jsonMap => _buildJsonField(field),
        _ => _buildTextField(field),
      },
    );
  }

  Widget _buildTextField(FieldConfig field) {
    final isMultiline = field.type == FieldType.hex || field.type == FieldType.xpub;

    return TextFormField(
      controller: _controllers[field.key],
      maxLines: isMultiline ? 3 : 1,
      style: TextStyle(
        fontSize: 13,
        fontFamily: isMultiline ? 'monospace' : null,
      ),
      decoration: InputDecoration(
        labelText: field.label + (field.required ? '' : '  (optional)'),
        hintText: field.hint ?? _hintForType(field.type),
        alignLabelWithHint: isMultiline,
      ),
      validator: field.required ? (v) => (v == null || v.trim().isEmpty) ? '${field.label} is required' : null : null,
    );
  }

  Widget _buildDropdown(FieldConfig field) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          items: field.options!.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _dropdownValues[field.key] = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildJsonField(FieldConfig field) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            field.label + (field.required ? '' : '  (optional)'),
            style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text('JSON', style: TextStyle(fontSize: 10, color: scheme.primary, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 6),
        TextFormField(
          controller: _controllers[field.key],
          maxLines: 5,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: field.hint,
            hintStyle: const TextStyle(fontSize: 11),
          ),
          validator: field.required
              ? (v) {
                  if (v == null || v.trim().isEmpty) {
                    return '${field.label} is required';
                  }
                  try {
                    jsonDecode(v);
                    return null;
                  } catch (_) {
                    return 'Please enter valid JSON';
                  }
                }
              : (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    try {
                      jsonDecode(v);
                    } catch (_) {
                      return 'Please enter valid JSON or leave empty';
                    }
                  }
                  return null;
                },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 顶层函数：供 sign_step1_page.dart 复用字段渲染，避免代码重复
// ─────────────────────────────────────────────────────────────

/// 渲染单个字段 Widget。
/// [onDropdownChanged] 仅 dropdown 类型需要，调用方负责更新状态。
Widget buildField({
  required BuildContext context,
  required FieldConfig field,
  required Map<String, TextEditingController> controllers,
  required Map<String, String> dropdownValues,
  required void Function(String key, String val) onDropdownChanged,
}) {
  final scheme = Theme.of(context).colorScheme;

  switch (field.type) {
    case FieldType.dropdown:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            items: field.options!.map((opt) => DropdownMenuItem(value: opt, child: Text(opt, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: (val) {
              if (val != null) onDropdownChanged(field.key, val);
            },
          ),
        ],
      );

    case FieldType.jsonList:
    case FieldType.jsonMap:
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              field.label + (field.required ? '' : '  (optional)'),
              style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Text('JSON', style: TextStyle(fontSize: 10, color: scheme.primary, fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 6),
          TextField(
            controller: controllers[field.key],
            maxLines: 4,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: field.hint,
              hintStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      );

    default:
      final isMultiline = field.type == FieldType.hex || field.type == FieldType.xpub;
      return TextField(
        controller: controllers[field.key],
        maxLines: isMultiline ? 3 : 1,
        style: TextStyle(
          fontSize: 13,
          fontFamily: isMultiline ? 'monospace' : null,
        ),
        decoration: InputDecoration(
          labelText: field.label + (field.required ? '' : '  (optional)'),
          hintText: field.hint ?? _hintForType(field.type),
          alignLabelWithHint: isMultiline,
        ),
      );
  }
}

String _hintForType(FieldType type) => switch (type) {
      FieldType.path => "m/44'/60'/0'/0/0",
      FieldType.hex => 'Hex, 0x prefix optional',
      FieldType.address => 'On-chain address',
      FieldType.integer => 'Integer',
      FieldType.xpub => 'xpub6...',
      _ => '',
    };
