import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/screens/estado_fisico/recuperacion/musculo_detalle.dart';

class GraficoCircularMusculosInvolucrados extends StatelessWidget {
  final Ejercicio ejercicio;

  const GraficoCircularMusculosInvolucrados({
    Key? key,
    required this.ejercicio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Agrupar músculos por tipo
    final Map<String, List<MusculoInvolucrado>> muscleGroups = {};
    for (var mi in ejercicio.musculosInvolucrados) {
      muscleGroups[mi.tipoString] = (muscleGroups[mi.tipoString] ?? [])..add(mi);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gráfico circular con padding
          Center(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                top: 50.0,
                bottom: 8.0,
              ),
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _PieChartPainter(ejercicio.musculosInvolucrados),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Mostrar grupos de músculos en ExpansionTile
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: muscleGroups.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: ExpansionTile(
                  collapsedBackgroundColor: AppColors.accentColor,
                  backgroundColor: AppColors.advertencia,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  title: Text(
                    entry.key,
                    style: const TextStyle(
                      color: AppColors.cardBackground,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: entry.value.map((mi) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MusculoDetallePage(
                              musculo: mi.musculo.titulo,
                              entrenamientos: [],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.advertencia,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mi.musculo.titulo,
                              style: const TextStyle(
                                color: AppColors.cardBackground,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              mi.descripcionImplicacion,
                              style: const TextStyle(
                                color: AppColors.cardBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<MusculoInvolucrado> datos;
  _PieChartPainter(this.datos);

  @override
  void paint(Canvas canvas, Size size) {
    final double total = datos.fold(
      0.0,
      (sum, item) => sum + item.porcentajeImplicacion.toDouble(),
    );
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final double strokeWidth = radius * 0.7;
    double startAngle = -pi / 2;

    final colors = [
      AppColors.accentColor,
      AppColors.appBarBackground,
      AppColors.cardBackground,
    ];
    // Si hay número par de datos, quitamos el último color
    final List<Color> arcColors = List.from(colors);
    if (datos.length % 2 == 0) {
      arcColors.removeLast();
    }

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (int i = 0; i < datos.length; i++) {
      final item = datos[i];
      final double sweepAngle = total > 0 ? (item.porcentajeImplicacion.toDouble() / total) * 2 * pi : 0;
      arcPaint.color = arcColors[i % arcColors.length];

      // Dibujar el segmento
      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius - strokeWidth / 2,
        ),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );

      // Calcular ángulo medio
      final double midAngle = startAngle + sweepAngle / 2;
      // Posición del texto dentro del donut
      final double labelRadius = radius - strokeWidth / 2;
      final labelOffset = Offset(
        center.dx + labelRadius * cos(midAngle),
        center.dy + labelRadius * sin(midAngle),
      );

      final String labelText = '${item.porcentajeImplicacion}%\n${item.musculo.titulo}';
      final double availableArcLength = sweepAngle * labelRadius;
      const double margin = 4;

      if (availableArcLength >= margin * 2 + 50) {
        // Texto dentro
        final textSpan = TextSpan(
          children: [
            TextSpan(
              text: '${item.porcentajeImplicacion}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.advertencia,
              ),
            ),
            TextSpan(
              text: '\n${item.musculo.titulo}',
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final Offset textPosition = labelOffset - Offset(textPainter.width / 2, textPainter.height / 2);
        textPainter.paint(canvas, textPosition);
      } else {
        // Texto fuera con flecha
        const double offsetExtra = 30;
        final arrowStart = labelOffset;
        final textCenterPos = Offset(
          center.dx + (radius + offsetExtra) * cos(midAngle),
          center.dy + (radius + offsetExtra) * sin(midAngle),
        );
        final textSpan = TextSpan(
          children: [
            TextSpan(
              text: '${item.porcentajeImplicacion}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.advertencia,
              ),
            ),
            TextSpan(
              text: '\n${item.musculo.titulo}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.whiteText,
              ),
            ),
          ],
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final adjustedTextPos = textCenterPos - Offset(textPainter.width / 2, textPainter.height / 2);
        textPainter.paint(canvas, adjustedTextPos);

        // Línea desde el donut al texto
        final Offset textCenter = adjustedTextPos + Offset(textPainter.width / 2, textPainter.height / 2);
        final Offset v = arrowStart - textCenter;
        double factor = 1.0;
        if (v.dx != 0 && v.dy != 0) {
          final double tx = (textPainter.width / 2) / v.dx.abs();
          final double ty = (textPainter.height / 2) / v.dy.abs();
          factor = min(tx, ty);
        }
        final Offset arrowEndpoint = textCenter + v * (factor * 0.9);
        final arrowPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.0;
        canvas.drawLine(arrowEndpoint, arrowStart, arrowPaint);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
