import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../common/eth_tx_fields.dart';
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
          final chainsStr = chainsList is List ? chainsList.join(', ') : chainsList?.toString() ?? '';
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
    return collectEthTxParams(
      type: widget.config.type,
      fields: widget.config.fields,
      controllers: _controllers,
      dropdownValues: _dropdownValues,
      txBuilderParams: _txBuilderParams,
    );
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
    setState(() {
      fillMockToEthTxControllers(
        type: widget.config.type,
        fields: widget.config.fields,
        controllers: _controllers,
        dropdownValues: _dropdownValues,
        clearTxBuilderParams: () => _txBuilderParams.clear(),
      );
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
    // ETH transaction 类型显示交易构建器
    if (field.key == 'signData' && _isEthTransactionType) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: _buildTransactionBuilderField(field),
      );
    }
    return Padding(
      padding: EdgeInsets.only(bottom: field.type == FieldType.dropdown && _isEthTransactionType ? 6 : 14),
      child: switch (field.type) {
        FieldType.dropdown => _buildDropdown(field),
        FieldType.jsonList || FieldType.jsonMap => _buildJsonField(field),
        FieldType.chainList => _buildChainListField(field),
        _ => buildField(
          context: context,
          field: field,
          controllers: _controllers,
          dropdownValues: _dropdownValues,
          onDropdownChanged: (key, val) => setState(() => _dropdownValues[key] = val),
          onChanged: () => setState(() {}),
        ),
      },
    );
  }

  bool get _isEthSignRequest {
    return widget.config.type == 'eth-sign-request';
  }

  /// 判断当前是否为 ETH transaction 类型
  bool get _isEthTransactionType {
    final dataType = _dropdownValues['dataType'];
    return _isEthSignRequest && (dataType == 'ETH_TRANSACTION_DATA' || dataType == 'ETH_TYPED_TRANSACTION');
  }

  /// ETH 交易构建器字段
  Widget _buildTransactionBuilderField(FieldConfig field) {
    final hasTxData = _txBuilderParams.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        // 有交易数据时显示状态，可点击重新编辑
        if (hasTxData)
          GestureDetector(
            onTap: () => _showTransactionBuilder(field),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tx: ${_txBuilderParams['txType']} - ${_txBuilderParams['to']}',
                      style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Theme.of(context).colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                    onPressed: () => _showTransactionBuilder(field),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                  IconButton(
                    icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade400),
                    onPressed: () => setState(() => _txBuilderParams.clear()),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controllers[field.key],
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: field.hint ?? _hintForType(field.type),
                    suffixIcon: _controllers[field.key]!.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade400),
                            onPressed: () => setState(() {
                              _controllers[field.key]!.clear();
                              _txBuilderParams.clear();
                            }),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          )
                        : null,
                  ),
                  validator: field.required
                      ? (v) => (v == null || v.trim().isEmpty && _txBuilderParams.isEmpty) ? '${field.label} is required (enter hex or build transaction)' : null
                      : null,
                ),
              ),
              IconButton(
                icon: Icon(Icons.build, size: 18, color: Theme.of(context).colorScheme.primary),
                tooltip: 'Build Transaction',
                onPressed: () => _showTransactionBuilder(field),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
      ],
    );
  }

  /// 显示交易构建器弹窗
  void _showTransactionBuilder(FieldConfig field) {
    final chainId = int.tryParse(_controllers['chainId']?.text ?? '1') ?? 1;
    // 从 mock 数据获取默认测试私钥
    final mockData = kMockByType[widget.config.type];
    final testPrivKey = mockData?['_testPrivKey'] as String?;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => TransactionBuilderSheet(
        chainId: chainId,
        initialParams: _txBuilderParams.isNotEmpty ? Map.from(_txBuilderParams) : null,
        testPrivKey: testPrivKey,
        onComplete: (txParams) {
          setState(() {
            // 清空 signData，改为存储交易字段
            _controllers[field.key]!.text = '';
            // 将交易字段存入 _txBuilderParams
            _txBuilderParams.clear();
            _txBuilderParams.addAll(txParams);
            // 自动设置正确的 dataType
            if (_dropdownValues['dataType'] == null) {
              _dropdownValues['dataType'] = 'ETH_TRANSACTION_DATA';
            }
          });
        },
      ),
    );
  }

  // 存储交易构建器的参数
  final Map<String, dynamic> _txBuilderParams = {};

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
  String? Function(String?)? validator,
  VoidCallback? onChanged, // 清除按钮状态更新回调
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
                onPressed: () {
                  controllers[field.key]!.text = field.type == FieldType.jsonList ? '[]' : '{}';
                  onChanged?.call();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ),
            onChanged: (_) => onChanged?.call(),
          ),
        ],
      );

    default:
      final isMultiline = (field.type == FieldType.hex || field.type == FieldType.xpub) && field.label != 'Master Fingerprint';
      final effectiveValidator = validator ??
          (field.required ? (v) => (v == null || v.trim().isEmpty) ? '${field.label} is required' : null : null);
      return TextFormField(
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
          suffixIcon: controllers[field.key]!.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade400),
                  onPressed: () {
                    controllers[field.key]!.clear();
                    onChanged?.call();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                )
              : null,
        ),
        validator: effectiveValidator,
        onChanged: (_) => onChanged?.call(),
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

// ─────────────────────────────────────────────────────────────
// ETH 交易构建器弹窗 (公开供复用)
// ─────────────────────────────────────────────────────────────

class TransactionBuilderSheet extends StatefulWidget {
  final int chainId;
  final Map<String, dynamic>? initialParams;
  final void Function(Map<String, dynamic> txParams) onComplete;

  /// 测试私钥，仅用于 EIP-7702 demo 签名
  /// ⚠️ Demo 用途，生产环境不应使用
  final String? testPrivKey;

  const TransactionBuilderSheet({
    required this.chainId,
    this.initialParams,
    required this.onComplete,
    this.testPrivKey,
  });

  @override
  State<TransactionBuilderSheet> createState() => TransactionBuilderSheetState();
}

class TransactionBuilderSheetState extends State<TransactionBuilderSheet> {
  final _toController = TextEditingController();
  final _valueController = TextEditingController();
  final _gasLimitController = TextEditingController(text: '21000');
  final _gasPriceController = TextEditingController();
  final _maxFeeController = TextEditingController();
  final _maxPriorityController = TextEditingController();
  final _nonceController = TextEditingController();
  final _dataController = TextEditingController();
  final _eip7702ContractController = TextEditingController(); // EIP7702 合约地址
  final _testPrivKeyController = TextEditingController(); // Demo 私钥

  String _txType = 'legacy'; // legacy, eip1559, eip7702

  @override
  void initState() {
    super.initState();
    _initFromParams();
  }

  void _initFromParams() {
    final params = widget.initialParams;

    // 始终初始化私钥（从 params 或 widget 属性）
    _testPrivKeyController.text = (params?['_testPrivKey'] as String?) ?? widget.testPrivKey ?? '';

    if (params == null || params.isEmpty) return;

    _txType = params['txType'] as String? ?? 'legacy';
    _toController.text = params['to'] as String? ?? '';
    final value = params['value'] as String? ?? '0';
    // 将 wei 转换为 ETH 显示
    try {
      final wei = BigInt.parse(value);
      final eth = wei ~/ BigInt.from(10).pow(18);
      _valueController.text = eth.toString();
    } catch (_) {
      _valueController.text = '0';
    }
    _gasLimitController.text = (params['gasLimit'] ?? 21000).toString();
    _gasPriceController.text = (params['gasPrice'] ?? '').toString();
    _maxFeeController.text = (params['maxFee'] ?? '').toString();
    _maxPriorityController.text = (params['maxPriority'] ?? '').toString();
    _nonceController.text = (params['nonce'] ?? '').toString();
    _dataController.text = params['data'] as String? ?? '';
    _eip7702ContractController.text = params['eip7702Contract'] as String? ?? '';
  }

  @override
  void dispose() {
    _toController.dispose();
    _valueController.dispose();
    _gasLimitController.dispose();
    _gasPriceController.dispose();
    _maxFeeController.dispose();
    _maxPriorityController.dispose();
    _nonceController.dispose();
    _dataController.dispose();
    _eip7702ContractController.dispose();
    _testPrivKeyController.dispose();
    super.dispose();
  }

  void _build() {
    final to = _toController.text.trim();
    final value = _valueController.text.trim();
    if (to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('To address is required')),
      );
      return;
    }

    final chainId = widget.chainId;
    final gasLimit = int.tryParse(_gasLimitController.text) ?? 21000;
    final valueWei = (BigInt.tryParse(value) ?? BigInt.zero) * BigInt.from(10).pow(18);

    // 返回交易参数，而不是 hex
    final txParams = <String, dynamic>{
      'txType': _txType,
      'to': to,
      'value': valueWei.toString(),
      'gasLimit': gasLimit,
      'nonce': int.tryParse(_nonceController.text) ?? 0,
      'data': _dataController.text.trim(),
      'chainId': chainId,
    };

    if (_txType == 'legacy') {
      txParams['gasPrice'] = int.tryParse(_gasPriceController.text) ?? 0;
    } else if (_txType == 'eip1559') {
      txParams['maxFee'] = int.tryParse(_maxFeeController.text) ?? 0;
      txParams['maxPriority'] = int.tryParse(_maxPriorityController.text) ?? 0;
    } else if (_txType == 'eip7702') {
      txParams['maxFee'] = int.tryParse(_maxFeeController.text) ?? 0;
      txParams['maxPriority'] = int.tryParse(_maxPriorityController.text) ?? 0;
      txParams['eip7702Contract'] = _eip7702ContractController.text.trim();
      // 传入私钥用于签名 authorization (Demo 模式)
      final privKey = _testPrivKeyController.text.trim();
      if (privKey.isNotEmpty) {
        txParams['_testPrivKey'] = privKey;
      }
    }

    widget.onComplete(txParams);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Build Transaction', style: theme.textTheme.titleMedium),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transaction Type Toggle
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'legacy', label: Text('Legacy')),
              ButtonSegment(value: 'eip1559', label: Text('EIP-1559')),
              ButtonSegment(value: 'eip7702', label: Text('EIP-7702')),
            ],
            selected: {_txType},
            onSelectionChanged: (v) => setState(() => _txType = v.first),
          ),
          const SizedBox(height: 12),

          // 使用 ListView 实现滚动
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                const SizedBox(height: 16),
                // To Address
                _buildTextFieldWithClear(
                  controller: _toController,
                  label: 'To Address/Token Contract Address',
                  hint: '0x...',
                ),
                const SizedBox(height: 12),

                // Value
                _buildTextFieldWithClear(
                  controller: _valueController,
                  label: 'Value (ETH)',
                  hint: '0.0',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Gas Limit
                _buildTextFieldWithClear(
                  controller: _gasLimitController,
                  label: 'Gas Limit',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Conditional fields
                if (_txType == 'legacy') ...[
                  _buildTextFieldWithClear(
                    controller: _gasPriceController,
                    label: 'Gas Price (wei)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                ] else if (_txType == 'eip1559') ...[
                  _buildTextFieldWithClear(
                    controller: _maxFeeController,
                    label: 'Max Fee (wei)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildTextFieldWithClear(
                    controller: _maxPriorityController,
                    label: 'Max Priority (wei)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                ] else if (_txType == 'eip7702') ...[
                  _buildTextFieldWithClear(
                    controller: _maxFeeController,
                    label: 'Max Fee (wei)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildTextFieldWithClear(
                    controller: _maxPriorityController,
                    label: 'Max Priority (wei)',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildTextFieldWithClear(
                    controller: _eip7702ContractController,
                    label: 'EIP-7702 Contract',
                    hint: '0x... (authorization contract)',
                  ),
                  const SizedBox(height: 12),
                  // Demo: 私钥输入（仅用于签名 authorization）
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '⚠️ Demo Mode - Authorization Signing',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'EIP-7702 requires signing the authorization. Enter a private key (hex) to sign it.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _testPrivKeyController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                          decoration: InputDecoration(
                            labelText: 'Private Key (hex)',
                            hintText: widget.testPrivKey?.isNotEmpty == true 
                                ? 'Using default test key (0xac09...)' 
                                : '0x...',
                            hintStyle: const TextStyle(fontSize: 11),
                            isDense: true,
                            suffixIcon: _testPrivKeyController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _testPrivKeyController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Nonce
                _buildTextFieldWithClear(
                  controller: _nonceController,
                  label: 'Nonce (optional)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Data
                _buildTextFieldWithClear(
                  controller: _dataController,
                  label: 'Data (hex, optional)',
                  hint: 'Token transfer: 0xa9059cbb + recipient(32bytes) + amount(32bytes)',
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                // Token 转账提示
                if (_dataController.text.isNotEmpty && _dataController.text.toLowerCase().startsWith('0xa9059cbb'))
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 6),
                            Text(
                              'ERC-20 Token Transfer Detected',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '• Set Value = 0\n• To Address = Token Contract Address\n• Data contains transfer(recipient, amount)',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          FilledButton(
            onPressed: _build,
            child: const Text('Generate Sign Data'),
          ),
        ],
      ),
    );
  }

  /// 复用表单清除按钮逻辑
  Widget _buildTextFieldWithClear({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade400),
                onPressed: () {
                  controller.clear();
                  setState(() {});
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              )
            : null,
      ),
      onChanged: (_) => setState(() {}),
    );
  }
}
