import 'package:flutter/material.dart';

/// Shared scan overlay with corner brackets.
/// [topOffset] shifts the cutout up/down relative to center (sign_step2: -20, scan_page: -40).
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({super.key, this.topOffset = -20.0});

  final double topOffset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      const cutOut = 260.0;
      final left = (size.width - cutOut) / 2;
      final top = (size.height - cutOut) / 2 + topOffset;
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
