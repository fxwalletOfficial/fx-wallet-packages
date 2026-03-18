import 'package:bc_ur_dart/bc_ur_dart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'ur_parser.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  // Core: One UR instance accumulates multi-frame
  UR _ur = UR();
  double _progress = 0.0;
  String? _lastFrame; // Prevent duplicate frame processing

  @override
  void initState() {
    super.initState();
    // Start camera when page is first loaded
    _cameraController.start();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _reset() {
    // Restart camera for re-scanning
    _cameraController.start();
    setState(() {
      _ur = UR();
      _progress = 0.0;
      _lastFrame = null;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    final frame = capture.barcodes.firstOrNull?.rawValue;
    if (frame == null || frame == _lastFrame) return;
    _lastFrame = frame;

    try {
      // ur.read() returns true when data is complete
      final done = _ur.read(frame);

      // Update progress
      final progress = calcProgress(_ur);
      if (mounted) setState(() => _progress = progress);

      if (done) {
        _cameraController.stop();
        final result = parseUR(_ur);
        // Brief delay for progress bar animation before navigating
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            context.pushNamed('result', extra: result);
            // Reset after return for re-scanning
            Future.delayed(const Duration(milliseconds: 400), _reset);
          }
        });
      }
    } catch (e) {
      // Non-UR format regular QR code
      _cameraController.stop();
      if (mounted) {
        context.pushNamed('result', extra: {
          'type': 'plain-text',
          'fields': {'raw': frame},
        });
        Future.delayed(const Duration(milliseconds: 400), _reset);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _cameraController.toggleTorch(),
            tooltip: 'Flashlight',
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _cameraController.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Camera Preview ──────────────────────────────────
          MobileScanner(controller: _cameraController, onDetect: _onDetect),

          // ── Scan Overlay ──────────────────────────────────
          const _ScanOverlay(),

          // ── Bottom Status Bar ──────────────────────────────────
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
                  // Progress text row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _progress == 0 ? 'Waiting to scan...' : 'Scanning multi-frame QR...',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Place QR code in frame, continue scanning until progress reaches 100%',
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

// ── Scan Overlay Widget ──────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      const cutOut = 260.0;
      final left = (size.width - cutOut) / 2;
      final top = (size.height - cutOut) / 2 - 40;
      return CustomPaint(
        size: size,
        painter: _OverlayPainter(Rect.fromLTWH(left, top, cutOut, cutOut)),
      );
    });
  }
}

class _OverlayPainter extends CustomPainter {
  const _OverlayPainter(this.cutOut);
  final Rect cutOut;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()..color = Colors.black54;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cutOut.top), shadow);
    canvas.drawRect(Rect.fromLTWH(0, cutOut.bottom, size.width, size.height - cutOut.bottom), shadow);
    canvas.drawRect(Rect.fromLTWH(0, cutOut.top, cutOut.left, cutOut.height), shadow);
    canvas.drawRect(Rect.fromLTWH(cutOut.right, cutOut.top, size.width - cutOut.right, cutOut.height), shadow);

    final corner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const L = 24.0;
    final r = cutOut;
    for (final path in [
      Path()..moveTo(r.left, r.top + L)..lineTo(r.left, r.top)..lineTo(r.left + L, r.top),
      Path()..moveTo(r.right - L, r.top)..lineTo(r.right, r.top)..lineTo(r.right, r.top + L),
      Path()..moveTo(r.left, r.bottom - L)..lineTo(r.left, r.bottom)..lineTo(r.left + L, r.bottom),
      Path()..moveTo(r.right - L, r.bottom)..lineTo(r.right, r.bottom)..lineTo(r.right, r.bottom - L),
    ]) {
      canvas.drawPath(path, corner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
