import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// زخرفة إسلامية هندسية (علامة مائية) شفافة تُضاف خلف الكروت الرئيسية.
class GirihPattern extends StatelessWidget {
  const GirihPattern({
    super.key,
    this.opacity = 0.05,
    this.color = AppColors.gold,
    this.size = 180.0,
  });

  final double opacity;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          size: Size(size, size),
          painter: _GirihPainter(color: color),
        ),
      ),
    );
  }
}

class _GirihPainter extends CustomPainter {
  _GirihPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // رسم نجمة ثمانية هندسية منقوشة
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle1 = (i * 45) * math.pi / 180;
      final angle2 = ((i + 2) * 45) * math.pi / 180;
      final p1 = Offset(center.dx + radius * 0.8 * math.cos(angle1), center.dy + radius * 0.8 * math.sin(angle1));
      final p2 = Offset(center.dx + radius * 0.8 * math.cos(angle2), center.dy + radius * 0.8 * math.sin(angle2));

      if (i == 0) {
        path.moveTo(p1.dx, p1.dy);
      } else {
        path.lineTo(p1.dx, p1.dy);
      }
      path.lineTo(p2.dx, p2.dy);
    }
    path.close();

    canvas.drawCircle(center, radius * 0.85, paint);
    canvas.drawCircle(center, radius * 0.55, paint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
