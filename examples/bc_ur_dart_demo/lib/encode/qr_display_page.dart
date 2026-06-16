import 'dart:async';
import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'ur_encoder.dart';
import '../common/copy_helper.dart';

class QrDisplayPage extends StatefulWidget {
  const QrDisplayPage({super.key, required this.type, required this.params});

  final String type;
  final Map<String, dynamic> params;

  @override
  State<QrDisplayPage> createState() => _QrDisplayPageState();
}

class _QrDisplayPageState extends State<QrDisplayPage> {
  UR? _ur;
  String? _error;

  // 当前显示的帧字符串
  String _currentFrame = '';
  int _frameIndex = 0;
  int _totalFrames = 0;
  bool _isAnimating = true;

  Timer? _timer;
  static const _frameInterval = Duration(milliseconds: 300);

  // 每帧最大字符数：控制分帧数量
  // 50 ≈ 硬件钱包屏幕常用值（30~60），让 demo 产生多帧动画效果
  int _maxLength = 50;

  // QR 尺寸控制
  double _qrSize = 280;

  @override
  void initState() {
    super.initState();
    _build();
  }

  void _build() {
    _timer?.cancel();
    try {
      final ur = buildUR(widget.type, widget.params);
      // maxLength 单位是字节（payload 分片大小）
      // ByteWords 编码后每字节 ≈ 2 字符，所以 10 字节 → 约 20 字符/帧
      // 实际硬件钱包常用 30~100 字节/帧，这里用 _maxLength 控制
      ur.maxLength = _maxLength;

      // ⚠️ 必须先调 next()，_partition() 才会懒触发、_fragments 才会被填充
      // ur.seq.length 在编码方向永远是 0，不能用它判断多帧
      // 正确判断：isSingle = (_fragments.length <= 1)，在 next() 后才准确
      // 总帧数从返回的帧字符串里解析（格式 "ur:type/SeqNum-TotalFrames/data"）
      final firstFrame = ur.next();
      final isMultiFrame = !ur.isSingle;
      final totalFrames = isMultiFrame ? _parseTotalFrames(firstFrame) : 1;

      setState(() {
        _ur = ur;
        _currentFrame = firstFrame;
        _frameIndex = 1;
        _totalFrames = totalFrames;
        _error = null;
      });
      if (isMultiFrame) _startAnimation();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(_frameInterval, (_) {
      if (!_isAnimating || _ur == null) return;
      final frame = _ur!.next();
      if (mounted) {
        setState(() {
          _currentFrame = frame;
          // 从帧字符串解析当前序号，ur.seq.num 在编码方向不可靠
          _frameIndex = _parseFrameIndex(frame);
        });
      }
    });
  }

  void _toggleAnimation() {
    setState(() => _isAnimating = !_isAnimating);
    if (_isAnimating) _startAnimation();
  }

  /// 从帧字符串解析总帧数
  /// 多帧格式: UR:TYPE/SeqNum-TotalFrames/data  → 取 TotalFrames
  /// 单帧格式: UR:TYPE/data                     → 返回 1
  int _parseTotalFrames(String frame) {
    try {
      final parts = frame.toUpperCase().split('/');
      if (parts.length >= 3) {
        final seqPart = parts[1]; // 如 "1-5"
        final seqNums = seqPart.split('-');
        if (seqNums.length == 2) {
          return int.tryParse(seqNums[1]) ?? 1;
        }
      }
    } catch (_) {}
    return 1;
  }

  /// 从帧字符串解析当前帧序号（1-based）
  int _parseFrameIndex(String frame) {
    try {
      final parts = frame.toUpperCase().split('/');
      if (parts.length >= 3) {
        final seqNums = parts[1].split('-');
        if (seqNums.length == 2) {
          return int.tryParse(seqNums[0]) ?? 1;
        }
      }
    } catch (_) {}
    return 1;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Copy current frame',
            onPressed: _currentFrame.isNotEmpty ? () => CopyHelper.copy(context, _currentFrame, label: 'Current frame') : null,
          ),
        ],
      ),
      body: _error != null
          ? _buildError()
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                // ── QR 码 ─────────────────────────────────────
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 80),
                    child: Container(
                      key: ValueKey(_currentFrame),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.outlineVariant, width: 0.5),
                      ),
                      child: QrImageView(
                        data: _currentFrame,
                        size: _qrSize,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── 帧信息 + 控制 ─────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // 帧计数
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _totalFrames > 1 ? 'Frame ${((_frameIndex - 1) % _totalFrames) + 1} / $_totalFrames' : 'Single frame QR',
                            style: TextStyle(fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.6)),
                          ),
                          if (_totalFrames > 1) ...[
                            const SizedBox(width: 16),
                            IconButton(
                              icon: Icon(_isAnimating ? Icons.pause_circle_outline : Icons.play_circle_outline),
                              onPressed: _toggleAnimation,
                              tooltip: _isAnimating ? 'Pause' : 'Play',
                            ),
                          ],
                        ],
                      ),

                      // 进度条（多帧时显示，value 限制在 0~1 防止溢出）
                      if (_totalFrames > 1) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (((_frameIndex - 1) % _totalFrames) + 1) / _totalFrames,
                            minHeight: 4,
                            backgroundColor: scheme.primary.withValues(alpha: 0.12),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // 每帧长度调节 + QR 尺寸调节
                      // 两行结构对齐：左 Icon(24) + Expanded(Slider) + 右 SizedBox(32)
                      _SliderRow(
                        icon: Icons.layers_outlined,
                        tooltip: 'Smaller = more frames',
                        slider: Slider(
                          value: _maxLength.toDouble(),
                          min: 10,
                          max: 100,
                          divisions: 9,
                          label: '$_maxLength bytes/frame',
                          onChanged: (v) {
                            setState(() => _maxLength = v.round());
                            _timer?.cancel();
                            _build();
                          },
                        ),
                        trailing: Text(
                          '$_maxLength maxLen',
                          style: TextStyle(fontSize: 12, color: scheme.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _SliderRow(
                        icon: Icons.crop_free,
                        tooltip: 'QR Size',
                        slider: Slider(
                          value: _qrSize,
                          min: 160,
                          max: 400,
                          divisions: 12,
                          label: '${_qrSize.round()}px',
                          onChanged: (v) => setState(() => _qrSize = v),
                        ),
                        trailing: Text(
                          '${_qrSize.round()} px',
                          style: TextStyle(fontSize: 12, color: scheme.primary),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 当前帧内容
                      _FrameContent(frame: _currentFrame),

                      const SizedBox(height: 16),

                      // Action buttons
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit parameters'),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.qr_code_scanner, size: 16),
                            label: const Text('Go verify by scanning'),
                            onPressed: () => context.pushNamed('scan'),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildError() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: 8),
            Text('Generation failed', style: TextStyle(fontWeight: FontWeight.w600, color: scheme.error)),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              _error!,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go back to edit'),
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

/// 统一的 Slider 行布局：左 Icon(固定24px) + Expanded(Slider) + 右 widget(固定48px)
/// 两行保持完全一致的左右宽度，Slider 才会真正对齐撑开
class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.slider,
    required this.trailing,
    this.tooltip,
  });

  final IconData icon;
  final Widget slider;
  final Widget trailing;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      size: 18,
      color: Theme.of(context).colorScheme.onSurface.withAlpha(80),
    );

    return Row(
      children: [
        SizedBox(
          width: 20,
          child: tooltip != null ? Tooltip(message: tooltip!, child: iconWidget) : iconWidget,
        ),
        Expanded(child: slider),
        SizedBox(width: 72, child: trailing),
      ],
    );
  }
}

class _FrameContent extends StatelessWidget {
  const _FrameContent({required this.frame});
  final String frame;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 截断显示，最多 160 字符
    final display = frame.length > 160 ? '${frame.substring(0, 160)}...' : frame;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              display,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.5),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => CopyHelper.copy(context, frame, label: 'Frame data'),
            child: Icon(Icons.copy_rounded, size: 16, color: scheme.primary),
          ),
        ],
      ),
    );
  }
}
