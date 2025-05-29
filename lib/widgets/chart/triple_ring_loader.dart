import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class TripleRingLoaderPainter extends CustomPainter {
  final double pasosPercent;
  final double minutosPercent;
  final double kcalPercent;
  final bool trainedToday;
  final Color backgroundColorRing;
  final bool showNumberLap;

  static const double _strokeFactor = 0.2;

  const TripleRingLoaderPainter({
    required this.pasosPercent,
    required this.minutosPercent,
    required this.kcalPercent,
    required this.trainedToday,
    required this.backgroundColorRing,
    this.showNumberLap = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double maxRadius = size.width / (2 + _strokeFactor);
    final center = Offset(size.width / 2, size.height / 2);

    final radii = [
      maxRadius,
      maxRadius * 0.75,
      maxRadius * 0.5,
    ];

    final ringWidths = List.filled(3, maxRadius * _strokeFactor);
    final percentages = [pasosPercent, minutosPercent, kcalPercent];
    final colors = [
      AppColors.accentColor,
      AppColors.mutedAdvertencia,
      AppColors.mutedGreen,
    ];

    for (int i = 0; i < 3; i++) {
      // fondo
      final bgPaint = Paint()
        ..color = backgroundColorRing
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidths[i];

      // progreso
      final fgPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = ringWidths[i];

      canvas.drawCircle(center, radii[i], bgPaint);

      final sweep = 2 * pi * percentages[i].clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radii[i]),
        -pi / 2,
        sweep,
        false,
        fgPaint,
      );

      // marcador si >100 %
      if (percentages[i] > 1.0) {
        final endAngle = -pi / 2 + 2 * pi * (percentages[i] % 1);
        final dx = center.dx + cos(endAngle) * radii[i];
        final dy = center.dy + sin(endAngle) * radii[i];
        canvas.drawCircle(
          Offset(dx, dy),
          ringWidths[i] * 0.5,
          Paint()
            ..color = AppColors.textMedium.withOpacity(0.75)
            ..style = PaintingStyle.fill,
        );
      }

      // vueltas completas
      if (showNumberLap) {
        final vueltas = percentages[i].floor();
        if (vueltas > 0) {
          final fontSizeNumber = ringWidths[i] * 0.8;
          final textPainter = TextPainter(
            text: TextSpan(
              text: '$vueltas',
              style: TextStyle(
                fontSize: fontSizeNumber,
                color: AppColors.background,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final dxText = center.dx - textPainter.width / 2;
          final dyText = center.dy - radii[i] - (fontSizeNumber / 2);
          textPainter.paint(canvas, Offset(dxText, dyText));
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TripleRingLoaderPainter oldDelegate) {
    return pasosPercent != oldDelegate.pasosPercent || minutosPercent != oldDelegate.minutosPercent || kcalPercent != oldDelegate.kcalPercent || trainedToday != oldDelegate.trainedToday;
  }
}
