import 'dart:async';
import 'dart:convert';

import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../common/copy_helper.dart';
import '../common/mock_data.dart';
import '../common/session_store.dart';
import '../encode/form_page.dart' show buildField, TransactionBuilderSheet; // 复用字段渲染和交易构建器
import '../encode/type_config.dart';
import '../encode/ur_encoder.dart';

class SignStep1Page extends StatefulWidget {
  const SignStep1Page({super.key, required this.config});
  final UrTypeConfig config;

  @override
  State<SignStep1Page> createState() => _SignStep1PageState();
}

class _SignStep1PageState extends State<SignStep1Page> {
  // ── QR 状态 ──────────────────────────────────────────────────
  UR? _ur;
  String? _requestId;
  String? _buildError;

  String _currentFrame = '';
  int _frameIndex = 0;
  int _totalFrames = 0;
  bool _isAnimating = true;
  int _maxLength = 50;

  Timer? _timer;
  static const _frameInterval = Duration(milliseconds: 300);

  // ── 参数编辑状态 ──────────────────────────────────────────────
  // controllers 和 dropdownValues 复用 FormPage 同款逻辑
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _dropdownValues = {};
  bool _paramsExpanded = false; // 参数面板是否展开
  
  // 表单验证 key
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // 交易构建器参数
  final Map<String, dynamic> _txBuilderParams = {};

  /// 判断当前是否为 ETH transaction 类型
  bool get _isEthTransactionType {
    final dataType = _dropdownValues['dataType'];
    return widget.config.type == 'eth-sign-request' &&
        (dataType == 'ETH_TRANSACTION_DATA' || dataType == 'ETH_TYPED_TRANSACTION');
  }

  @override
  void initState() {
    super.initState();
    _initControllers();
    // 使用 addPostFrameCallback 避免在 build 阶段调用 setState
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildQR());
  }

  // ── 参数初始化（复用 FormPage 逻辑）─────────────────────────
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

  Map<String, dynamic> _collectParams() {
    final params = <String, dynamic>{};
    for (final field in widget.config.fields) {
      // 跳过 signData 字段，使用交易构建器参数
      if (field.key == 'signData' && _txBuilderParams.isNotEmpty) {
        continue;
      }
      if (field.type == FieldType.dropdown) {
        params[field.key] = _dropdownValues[field.key];
      } else if (field.type == FieldType.jsonList || field.type == FieldType.jsonMap) {
        final text = _controllers[field.key]!.text.trim();
        if (text.isNotEmpty && text != '[]' && text != '{}') {
          try {
            params[field.key] = jsonDecode(text);
          } catch (_) {
            params[field.key] = text;
          }
        }
      } else {
        final val = _controllers[field.key]!.text.trim();
        if (val.isNotEmpty) params[field.key] = val;
      }
    }
    // 添加交易构建器参数
    if (_txBuilderParams.isNotEmpty) {
      params.addAll(_txBuilderParams);
    }
    return params;
  }

  void _resetToMock() {
    final mock = kMockByType[widget.config.type] ?? {};
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
    // 清除交易构建器参数
    _txBuilderParams.clear();
  }

  /// 显示交易构建器弹窗 (复用 FormPage 的弹窗)
  void _showTransactionBuilder() {
    final chainId = int.tryParse(_controllers['chainId']?.text ?? '1') ?? 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => TransactionBuilderSheet(
        chainId: chainId,
        initialParams: _txBuilderParams.isNotEmpty ? Map.from(_txBuilderParams) : null,
        onComplete: (txParams) {
          setState(() {
            // 清空 signData，存储交易字段
            _controllers['signData']?.text = '';
            _txBuilderParams.clear();
            _txBuilderParams.addAll(txParams);
            // 自动设置正确的 dataType
            if (_dropdownValues['dataType'] == null) {
              _dropdownValues['dataType'] = 'ETH_TRANSACTION_DATA';
            }
          });
          // 重新生成 QR
          _buildQR();
        },
      ),
    );
  }

  // ── QR 构建 ───────────────────────────────────────────────────
  void _buildQR() {
    _timer?.cancel();
    try {
      final params = _collectParams();
      final ur = buildUR(widget.config.type, params);
      ur.maxLength = _maxLength;

      final firstFrame = ur.next();
      final isMultiFrame = !ur.isSingle;
      final totalFrames = isMultiFrame ? _parseTotalFrames(firstFrame) : 1;
      final requestId = _extractRequestId(ur);

      setState(() {
        _ur = ur;
        _requestId = requestId;
        _currentFrame = firstFrame;
        _frameIndex = 1;
        _totalFrames = totalFrames;
        _buildError = null;
      });

      if (requestId != null && mounted) {
        context.read<SessionStore>().startSignSession(
              requestId: requestId,
              coinType: widget.config.label.replaceAll(' Sign Request', ''),
              signRequest: params,
            );
      }

      if (isMultiFrame) _startAnimation();
    } catch (e) {
      setState(() => _buildError = e.toString());
    }
  }

  String? _extractRequestId(UR ur) {
    try {
      final cbor = ur.decodeCBOR() as CborMap;
      final uuidVal = cbor[const CborSmallInt(1)];
      if (uuidVal is CborBytes) return hex.encode(uuidVal.bytes);
    } catch (_) {}
    return null;
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(_frameInterval, (_) {
      if (!_isAnimating || _ur == null) return;
      final frame = _ur!.next();
      if (mounted) {
        setState(() {
          _currentFrame = frame;
          _frameIndex = _parseFrameIndex(frame);
        });
      }
    });
  }

  int _parseTotalFrames(String frame) {
    try {
      final parts = frame.toUpperCase().split('/');
      if (parts.length >= 3) {
        final seqNums = parts[1].split('-');
        if (seqNums.length == 2) return int.tryParse(seqNums[1]) ?? 1;
      }
    } catch (_) {}
    return 1;
  }

  int _parseFrameIndex(String frame) {
    try {
      final parts = frame.toUpperCase().split('/');
      if (parts.length >= 3) {
        final seqNums = parts[1].split('-');
        if (seqNums.length == 2) return int.tryParse(seqNums[0]) ?? 1;
      }
    } catch (_) {}
    return 1;
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }


  // ── UI ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final coinName = widget.config.label.replaceAll(' Sign Request', '');

    return Scaffold(
      appBar: AppBar(
        title: Text('Step 1 — $coinName'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<SessionStore>().clearSignSession();
              context.goNamed('home');
            },
            child: const Text('Cancel'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset to defaults',
            onPressed: () {
              setState(_resetToMock);
              _buildQR();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _StepIndicator(current: 1),
          const SizedBox(height: 20),

          // ── QR 展示区 ─────────────────────────────────────────
          if (_buildError != null)
            _ErrorCard(error: _buildError!)
          else ...[
            _QrSection(
              currentFrame: _currentFrame,
              frameIndex: _frameIndex,
              totalFrames: _totalFrames,
              isAnimating: _isAnimating,
              maxLength: _maxLength,
              onToggleAnim: () {
                setState(() => _isAnimating = !_isAnimating);
                if (_isAnimating) _startAnimation();
              },
              onMaxLengthChanged: (v) {
                setState(() => _maxLength = v);
                _buildQR();
              },
            ),
            const SizedBox(height: 16),
            if (_requestId != null) _RequestIdCard(requestId: _requestId!),
          ],

          const SizedBox(height: 20),

          // ── 参数编辑面板 ──────────────────────────────────────
          _ParamsPanel(
            formKey: _formKey,
            expanded: _paramsExpanded,
            config: widget.config,
            controllers: _controllers,
            dropdownValues: _dropdownValues,
            onToggle: () => setState(() => _paramsExpanded = !_paramsExpanded),
            onDropdownChanged: (key, val) => setState(() => _dropdownValues[key] = val),
            onApply: () {
              if (_formKey.currentState!.validate()) {
                _buildQR();
              }
            },
            isEthTransactionType: _isEthTransactionType,
            txBuilderParams: _txBuilderParams,
            onShowTransactionBuilder: _showTransactionBuilder,
          ),

          const SizedBox(height: 24),

          FilledButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Signature'),
            onPressed: _buildError == null ? () => context.pushNamed('sign_step2') : null,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── QR 展示区 ─────────────────────────────────────────────────────

class _QrSection extends StatelessWidget {
  const _QrSection({
    required this.currentFrame,
    required this.frameIndex,
    required this.totalFrames,
    required this.isAnimating,
    required this.maxLength,
    required this.onToggleAnim,
    required this.onMaxLengthChanged,
  });

  final String currentFrame;
  final int frameIndex;
  final int totalFrames;
  final bool isAnimating;
  final int maxLength;
  final VoidCallback onToggleAnim;
  final ValueChanged<int> onMaxLengthChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayIndex = totalFrames > 1 ? ((frameIndex - 1) % totalFrames) + 1 : 1;

    return Column(
      children: [
        // QR 码
        Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 80),
            child: Container(
              key: ValueKey(currentFrame),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant, width: 0.5),
              ),
              child: QrImageView(
                data: currentFrame,
                size: 240,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 帧信息行
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              totalFrames > 1 ? 'Frame $displayIndex / $totalFrames' : 'Single-frame QR',
              style: TextStyle(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.5)),
            ),
            if (totalFrames > 1) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onToggleAnim,
                child: Icon(
                  isAnimating ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 4),
              // 复制当前帧
              GestureDetector(
                onTap: () => CopyHelper.copy(context, currentFrame, label: 'Current frame'),
                child: Icon(Icons.copy_outlined, color: scheme.primary, size: 18),
              ),
            ],
          ],
        ),

        // 进度条
        if (totalFrames > 1) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: displayIndex / totalFrames,
              minHeight: 4,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ],
    );
  }
}

// ── 参数编辑面板 ───────────────────────────────────────────────────

class _ParamsPanel extends StatelessWidget {
  const _ParamsPanel({
    required this.formKey,
    required this.expanded,
    required this.config,
    required this.controllers,
    required this.dropdownValues,
    required this.onToggle,
    required this.onDropdownChanged,
    required this.onApply,
    required this.isEthTransactionType,
    required this.txBuilderParams,
    required this.onShowTransactionBuilder,
  });

  final GlobalKey<FormState> formKey;
  final bool expanded;
  final UrTypeConfig config;
  final Map<String, TextEditingController> controllers;
  final Map<String, String> dropdownValues;
  final VoidCallback onToggle;
  final void Function(String key, String val) onDropdownChanged;
  final VoidCallback onApply;
  final bool isEthTransactionType;
  final Map<String, dynamic> txBuilderParams;
  final VoidCallback onShowTransactionBuilder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 展开/收起标题行
          InkWell(
            onTap: onToggle,
            borderRadius: expanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(Icons.tune_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Edit Request Params',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: scheme.primary),
                  ),
                ),
                Text(
                  expanded ? 'Collapse' : 'Expand',
                  style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.5)),
                ),
                const SizedBox(width: 4),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  size: 20,
                ),
              ]),
            ),
          ),

          // 展开时的字段列表
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    ...config.fields.map((field) {
                      // ETH transaction 类型使用交易构建器
                      if (field.key == 'signData' && isEthTransactionType) {
                        return _buildTransactionBuilderField(context, field);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: buildField(
                          context: context,
                          field: field,
                          controllers: controllers,
                          dropdownValues: dropdownValues,
                          onDropdownChanged: onDropdownChanged,
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            onApply();
                          }
                        },
                        child: const Text('Apply → Regenerate QR'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建 ETH 交易字段 (与 FormPage 逻辑一致)
  Widget _buildTransactionBuilderField(BuildContext context, FieldConfig field) {
    final scheme = Theme.of(context).colorScheme;
    final hasTxData = txBuilderParams.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: TextStyle(fontSize: 12, color: scheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          if (hasTxData)
            GestureDetector(
              onTap: onShowTransactionBuilder,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tx: ${txBuilderParams['txType']} - ${txBuilderParams['to']}',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: scheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
                      onPressed: onShowTransactionBuilder,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                    IconButton(
                      icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade400),
                      onPressed: () {
                        txBuilderParams.clear();
                        onApply();
                      },
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
                    controller: controllers[field.key],
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText: field.hint,
                      suffixIcon: controllers[field.key]!.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 16, color: Colors.grey.shade400),
                              onPressed: () {
                                controllers[field.key]!.clear();
                                // 清除交易构建器参数并重新生成 QR
                                txBuilderParams.clear();
                                onApply();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            )
                          : null,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.build, size: 18, color: scheme.primary),
                  tooltip: 'Build Transaction',
                  onPressed: onShowTransactionBuilder,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── 其他子 Widgets ────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.error_outline, color: scheme.error, size: 16),
            const SizedBox(width: 6),
            Text('Build Failed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: scheme.error)),
          ]),
          const SizedBox(height: 8),
          SelectableText(error, style: const TextStyle(fontSize: 12, fontFamily: 'monospace', height: 1.5)),
        ],
      ),
    );
  }
}

class _RequestIdCard extends StatelessWidget {
  const _RequestIdCard({required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.key_outlined, size: 14, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Request ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.primary)),
                const SizedBox(height: 3),
                SelectableText(requestId, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.4)),
                const SizedBox(height: 3),
                Text('Written to Session; Step 2 scan auto-validates', style: TextStyle(fontSize: 10, color: scheme.onSurface.withValues(alpha: 0.45))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => CopyHelper.copy(context, requestId, label: 'Request ID'),
            child: Icon(Icons.copy_rounded, size: 15, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _StepDot(index: 1, current: current, label: 'Initiate Request'),
        Expanded(child: Container(height: 1.5, color: scheme.outlineVariant)),
        _StepDot(index: 2, current: current, label: 'Scan Signature'),
        Expanded(child: Container(height: 1.5, color: scheme.outlineVariant)),
        _StepDot(index: 3, current: current, label: 'Validate Result'),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.index, required this.current, required this.label});
  final int index;
  final int current;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = index < current;
    final isActive = index == current;
    final color = isDone || isActive ? scheme.primary : scheme.outlineVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive
                ? scheme.primary
                : isDone
                    ? scheme.primary.withValues(alpha: 0.2)
                    : scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: isActive ? 0 : 1.5),
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check, size: 14, color: scheme.primary)
                : Text('$index', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? scheme.onPrimary : color)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ],
    );
  }
}
