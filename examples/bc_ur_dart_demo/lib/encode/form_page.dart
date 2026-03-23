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
  
  // chainList 专用状态
  final Map<String, List<Map<String, String>>> _chainLists = {}; // fieldKey -> list of chain data
  // chainList 的 TextEditingController：fieldKey -> [{path, chains, xpub}]
  final Map<String, List<Map<String, TextEditingController>>> _chainControllers = {};

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
      } else if (field.type == FieldType.chainList) {
        // 初始化 chainList：每个 chain 有 path, chains, xpub 三个字段
        final chains = (mockVal as List? ?? []).map((c) {
          final chainsList = (c as Map)['chains'];
          final chainsStr = chainsList is List
              ? chainsList.join(', ')
              : chainsList?.toString() ?? '';
          return {
            'path': (c)['path']?.toString() ?? '',
            'chains': chainsStr,
            'xpub': (c)['xpub']?.toString() ?? '',
          };
        }).toList();
        if (chains.isEmpty) {
          // 默认添加一个空 chain
          chains.add({'path': '', 'chains': '', 'xpub': ''});
        }
        _chainLists[field.key] = chains;
        // 同步初始化 controllers
        _chainControllers[field.key] = chains.map((c) {
          return {
            'path': TextEditingController(text: c['path'] ?? ''),
            'chains': TextEditingController(text: c['chains'] ?? ''),
            'xpub': TextEditingController(text: c['xpub'] ?? ''),
          };
        }).toList();
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
    // 清理 chain controllers
    for (final fieldControllers in _chainControllers.values) {
      for (final c in fieldControllers) {
        c['path']?.dispose();
        c['chains']?.dispose();
        c['xpub']?.dispose();
      }
    }
    super.dispose();
  }

  Map<String, dynamic> _collectParams() {
    final params = <String, dynamic>{};
    for (final field in widget.config.fields) {
      if (field.type == FieldType.dropdown) {
        params[field.key] = _dropdownValues[field.key];
      } else if (field.type == FieldType.chainList) {
        // 转换 chainList 为 [{path, chains: [...], xpub}, ...] 格式
        final chainControllers = _chainControllers[field.key] ?? [];
        final validChains = chainControllers
            .where((c) => c['path']!.text.isNotEmpty && c['xpub']!.text.isNotEmpty)
            .map((c) => {
                  'path': c['path']!.text,
                  'chains': c['chains']!.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
                  'xpub': c['xpub']!.text,
                })
            .toList();
        if (validChains.isNotEmpty) {
          params[field.key] = validChains;
        }
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
        } else if (field.type == FieldType.chainList) {
          final chains = (mockVal as List? ?? []).map((c) {
            final chainsList = (c as Map)['chains'];
            final chainsStr = chainsList is List
                ? chainsList.join(', ')
                : chainsList?.toString() ?? '';
            return {
              'path': (c)['path']?.toString() ?? '',
              'chains': chainsStr,
              'xpub': (c)['xpub']?.toString() ?? '',
            };
          }).toList();
          _chainLists[field.key] = chains;
          // 更新 controllers
          _chainControllers[field.key] = chains.map((c) {
            return {
              'path': TextEditingController(text: c['path'] ?? ''),
              'chains': TextEditingController(text: c['chains'] ?? ''),
              'xpub': TextEditingController(text: c['xpub'] ?? ''),
            };
          }).toList();
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
        FieldType.chainList => _buildChainListField(field),
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
        suffixIcon: _controllers[field.key]!.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade400),
                onPressed: () => setState(() => _controllers[field.key]!.clear()),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              )
            : null,
      ),
      validator: field.required ? (v) => (v == null || v.trim().isEmpty) ? '${field.label} is required' : null : null,
      onChanged: (_) => setState(() {}), // 更新 clear button 状态
    );
  }

  Widget _buildDropdown(FieldConfig field) {
    final scheme = Theme.of(context).colorScheme;
    final selectedValue = _dropdownValues[field.key];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: selectedValue,
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
            suffixIcon: _controllers[field.key]!.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade400),
                    onPressed: () => setState(() {
                      _controllers[field.key]!.text = field.type == FieldType.jsonList ? '[]' : '{}';
                    }),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  )
                : null,
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
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildChainListField(FieldConfig field) {
    final scheme = Theme.of(context).colorScheme;
    final chains = _chainLists[field.key] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              field.label + (field.required ? '' : '  (optional)'),
              style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _chainLists[field.key] ??= [];
                  _chainLists[field.key]!.add({'path': '', 'chains': '', 'xpub': ''});
                  _chainControllers[field.key] ??= [];
                  _chainControllers[field.key]!.add({
                    'path': TextEditingController(),
                    'chains': TextEditingController(),
                    'xpub': TextEditingController(),
                  });
                });
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Chain', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...chains.asMap().entries.map((entry) {
          final index = entry.key;
          final controllers = _chainControllers[field.key]![index];
          return _ChainItem(
            index: index,
            controllers: controllers,
            onRemove: chains.length > 1
                ? () {
                    setState(() {
                      // 清理被删除项的 controllers
                      _chainControllers[field.key]![index]['path']!.dispose();
                      _chainControllers[field.key]![index]['chains']!.dispose();
                      _chainControllers[field.key]![index]['xpub']!.dispose();
                      _chainControllers[field.key]!.removeAt(index);
                      _chainLists[field.key]!.removeAt(index);
                    });
                  }
                : null,
          );
        }),
      ],
    );
  }
}

/// 单个 Chain 项的 UI：path + chains + xpub + 删除按钮
class _ChainItem extends StatelessWidget {
  const _ChainItem({
    required this.index,
    required this.controllers,
    this.onRemove,
  });

  final int index;
  final Map<String, TextEditingController> controllers;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Chain ${index + 1}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer),
                ),
              ),
              const Spacer(),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.delete_outline, size: 18, color: scheme.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: 'Remove',
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Path field
          TextField(
            controller: controllers['path'],
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              labelText: 'Derivation Path',
              hintText: "m/44'/60'/0'",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 10),
          // Chains field
          TextField(
            controller: controllers['chains'],
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Chains (comma separated)',
              hintText: 'ETH, BTC',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 10),
          // Xpub field
          TextField(
            controller: controllers['xpub'],
            maxLines: 3,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            decoration: const InputDecoration(
              labelText: 'Extended Public Key (xpub)',
              hintText: 'xpub6...',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ],
      ),
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
            initialValue: dropdownValues[field.key],
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
              suffixIcon: IconButton(
                icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade400),
                onPressed: () => controllers[field.key]!.text = field.type == FieldType.jsonList ? '[]' : '{}',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
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
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade400),
            onPressed: () => controllers[field.key]!.clear(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
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
