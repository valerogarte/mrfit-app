import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/screens/estado_fisico/recuperacion/musculo_detalle.dart';

/// Gráfico circular + acordeón de músculos, solo un panel abierto.
class GraficoCircularMusculosInvolucrados extends StatefulWidget {
  final Ejercicio ejercicio;
  const GraficoCircularMusculosInvolucrados({super.key, required this.ejercicio});

  @override
  State<GraficoCircularMusculosInvolucrados> createState() => _GraficoCircularMusculosInvolucradosState();
}

class _GraficoCircularMusculosInvolucradosState extends State<GraficoCircularMusculosInvolucrados> {
  late final Map<String, List<MusculoInvolucrado>> _groups;
  String? _openPanel;

  @override
  void initState() {
    super.initState();
    _groups = _groupByType(widget.ejercicio.musculosInvolucrados);
  }

  Map<String, List<MusculoInvolucrado>> _groupByType(List<MusculoInvolucrado> list) {
    final map = <String, List<MusculoInvolucrado>>{};
    for (var mi in list) {
      map.putIfAbsent(mi.tipoString, () => []).add(mi);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 50),
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _PieChartPainter(widget.ejercicio.musculosInvolucrados),
            ),
          ),
          const SizedBox(height: 16),
          ExpansionPanelList.radio(
            elevation: 0,
            initialOpenPanelValue: _openPanel,
            expandedHeaderPadding: EdgeInsets.zero,
            dividerColor: Colors.transparent,
            materialGapSize: 0, // elimina el “hueco” blanco
            children: _groups.entries.map((entry) {
              final bool isExpanded = _openPanel == entry.key;
              return ExpansionPanelRadio(
                value: entry.key,
                backgroundColor: isExpanded ? AppColors.mutedAdvertencia : AppColors.appBarBackground, // pinta toda la fila
                headerBuilder: (context, _) {
                  return Container(
                    margin: EdgeInsets.only(bottom: isExpanded ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    // solo bordes superiores cuando está expandido,
                    // todos los bordes cuando está cerrado.
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: isExpanded ? AppColors.background : AppColors.textMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                body: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.mutedAdvertencia,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Column(
                    children: entry.value.map((mi) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        title: Text(
                          mi.musculo.titulo,
                          style: const TextStyle(color: AppColors.cardBackground, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(mi.descripcionImplicacion, style: const TextStyle(color: AppColors.cardBackground)),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MusculoDetallePage(musculo: mi.musculo.titulo, entrenamientos: const []),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                canTapOnHeader: true,
              );
            }).toList(),
            expansionCallback: (index, isOpen) {
              setState(() {
                final key = _groups.keys.elementAt(index);
                _openPanel = isOpen ? null : key;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<MusculoInvolucrado> datos;
  static const _palette = [
    AppColors.accentColor,
    AppColors.appBarBackground,
    AppColors.cardBackground,
  ];

  _PieChartPainter(this.datos);

  @override
  void paint(Canvas canvas, Size size) {
    final double total = datos.fold(0.0, (double sum, item) => sum + item.porcentajeImplicacion.toDouble());
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.7;
    double startAngle = -pi / 2;

    final List<Color> colors = List<Color>.from(_palette);
    if (datos.length.isEven) colors.removeLast();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    for (var i = 0; i < datos.length; i++) {
      final item = datos[i];
      final double sweep = total > 0 ? (item.porcentajeImplicacion.toDouble() / total) * 2 * pi : 0.0;
      paint.color = colors[i % colors.length];

      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweep, false, paint);
      _drawLabel(canvas, center, radius, strokeWidth, startAngle, sweep, item);
      startAngle += sweep;
    }
  }

  void _drawLabel(Canvas canvas, Offset center, double radius, double strokeWidth, double startAngle, double sweepAngle, MusculoInvolucrado item) {
    final double midAngle = startAngle + sweepAngle / 2;
    final double labelRadius = radius - strokeWidth / 2;
    final Offset labelPos = Offset(center.dx + labelRadius * cos(midAngle), center.dy + labelRadius * sin(midAngle));

    const double minArcLength = 50.0;
    final double arcLength = sweepAngle * labelRadius;
    final bool inside = arcLength >= minArcLength;

    final textSpan = TextSpan(
      children: [
        TextSpan(text: '${item.porcentajeImplicacion}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.mutedAdvertencia)),
        TextSpan(text: '\n${item.musculo.titulo}', style: const TextStyle(fontSize: 14, color: AppColors.textNormal)),
      ],
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

    if (inside) {
      final offset = labelPos - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, offset);
    } else {
      const double extra = 30.0;
      final Offset outside = Offset(center.dx + (radius + extra) * cos(midAngle), center.dy + (radius + extra) * sin(midAngle));
      final offset = outside - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, offset);
      final Paint linePaint = Paint()
        ..strokeWidth = 1.0
        ..color = AppColors.textNormal;
      canvas.drawLine(offset + Offset(textPainter.width / 2, textPainter.height / 2), labelPos, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
