import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../common/scan_overlay.dart';
import '../common/session_store.dart';
import '../scan/ur_parser.dart';

class SignStep2Page extends StatefulWidget {
  const SignStep2Page({super.key});

  @override
  State<SignStep2Page> createState() => _SignStep2PageState();
}

class _SignStep2PageState extends State<SignStep2Page> {
  final _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  UR _ur = UR();
  double _progress = 0.0;
  String? _lastFrame;
  bool _done = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _ur = UR();
      _progress = 0.0;
      _lastFrame = null;
      _done = false;
    });
    _cameraController.start();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    final frame = capture.barcodes.firstOrNull?.rawValue;
    if (frame == null || frame == _lastFrame) return;
    _lastFrame = frame;

    try {
      final done = _ur.read(frame);
      final progress = calcProgress(_ur);
      if (mounted) setState(() => _progress = progress);

      if (done) {
        _done = true;
        _cameraController.stop();
        _handleComplete(_ur);
      }
    } catch (e) {
      // 非 UR 格式，忽略
    }
  }

  void _handleComplete(UR ur) {
    final session = context.read<SessionStore>();

    // 解析 Signature
    final parsed = parseUR(ur);
    final fields = parsed['fields'] as Map<String, dynamic>? ?? {};
    final isError = parsed['isError'] == true;

    // 从扫描结果取 requestId
    final scannedRequestId = fields['requestId']?.toString();

    // 与 Session 中保存的 requestId 做对比
    final sessionRequestId = session.currentRequestId;
    final matched = scannedRequestId != null && sessionRequestId != null && scannedRequestId.toLowerCase() == sessionRequestId.toLowerCase();

    // 跳转结果页
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        context.pushNamed('sign_result', extra: {
          'parsed': parsed,
          'matched': matched,
          'isError': isError,
          'scannedRequestId': scannedRequestId,
          'sessionRequestId': sessionRequestId,
          'coinType': session.currentCoinType,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<SessionStore>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Step 2 — Scan ${session.currentCoinType ?? ''} Signature'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _cameraController.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _cameraController, onDetect: _onDetect),

          // 扫描框
          const ScanOverlay(),

          // Session 信息栏（顶部）
          if (session.hasActiveSession)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.key_outlined, size: 13, color: Colors.white70),
                      const SizedBox(width: 6),
                      const Text('Expected Request ID to validate', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      session.currentRequestId ?? '—',
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

          // 底部进度栏
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 44),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Scanning hardware wallet Signature QR...', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: scheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Scan the corresponding XX-signature QR for this coin',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  if (_progress > 0) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Reset', style: TextStyle(color: Colors.white60)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scan overlay moved to common/scan_overlay.dart ──────────────
