import 'dart:math';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class TripleRingLoaderPainter extends CustomPainter {
  final double pasosPercent;
  final double minutosPercent;
  final double kcalPercent;
  final bool trainedToday;

  const TripleRingLoaderPainter({
    required this.pasosPercent,
    required this.minutosPercent,
    required this.kcalPercent,
    required this.trainedToday,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double maxRadius = size.width / 2 - 8;

    final radii = [
      maxRadius,
      maxRadius * 0.75,
      maxRadius * 0.5,
    ];
    final ringWidths = List.filled(3, maxRadius * 0.2);
    final percentages = [
      pasosPercent,
      minutosPercent,
      kcalPercent,
    ];
    final colors = [
      AppColors.accentColor,
      AppColors.mutedRed,
      AppColors.mutedAdvertencia,
    ];

    for (int i = 0; i < 3; i++) {
      // pintura de fondo y arco
      final bgPaint = Paint()
        ..color = AppColors.background
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidths[i];
      final fgPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = ringWidths[i];

      canvas.drawCircle(center, radii[i], bgPaint);

      final sweep = 2 * pi * percentages[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radii[i]),
        -pi / 2,
        sweep,
        false,
        fgPaint,
      );

      // marcador verde al final del arco (si sobrepasa 100%)
      if (percentages[i] > 1.0) {
        final endAngle = -pi / 2 + sweep;
        final dx = center.dx + cos(endAngle) * radii[i];
        final dy = center.dy + sin(endAngle) * radii[i];
        final markerPaint = Paint()
          ..color = AppColors.textColor.withAlpha((255 * 0.75).toInt())
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(dx, dy),
          ringWidths[i] * 0.5,
          markerPaint,
        );
      }

      // número de vueltas completas dentro del anillo, en la posición “12 h”
      final vueltas = percentages[i].floor();
      if (vueltas > 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$vueltas',
            style: TextStyle(
              fontSize: ringWidths[i] * 0.8,
              color: AppColors.background,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final dxText = center.dx - textPainter.width / 2;
        final dyText = (center.dy - radii[i] + ringWidths[i] / 2 - textPainter.height / 2) - ringWidths[i] * 0.45;
        textPainter.paint(canvas, Offset(dxText, dyText));
      }
    }

    // icono central
    final iconPainter = TextPainter(
      text: TextSpan(
        text: trainedToday ? '🔥' : '😴',
        style: TextStyle(
          fontSize: 20,
          color: AppColors.textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
