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
      // Padding vertical general para todo el widget
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            // Padding específico para el gráfico y el espacio superior
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
          // ExpansionPanelList.radio ahora se expandirá horizontalmente
          // al ancho del widget padre de GraficoCircularMusculosInvolucrados,
          // ya que no está restringido por un padding horizontal aquí.
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ExpansionPanelList.radio(
              elevation: 0,
              initialOpenPanelValue: _openPanel,
              expandedHeaderPadding: EdgeInsets.zero, // Controla el padding interno del header por defecto.
              dividerColor: Colors.transparent,
              materialGapSize: 0,
              expandIconColor: Colors.transparent, // Oculta el icono de expansión por defecto del ExpansionPanelList.
              children: _groups.entries.map((entry) {
                // ignore: unused_local_variable
                final bool isExpanded = _openPanel == entry.key;
                return ExpansionPanelRadio(
                  value: entry.key,
                  backgroundColor: Colors.transparent,
                  headerBuilder: (context, isPanelExpanded) {
                    // Este Container es el que da estilo al header.
                    // Se expandirá al ancho del ExpansionPanelRadio.
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 8.0), // Margen horizontal para el header si se desea que no pegue a los bordes de la pantalla
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isPanelExpanded ? AppColors.accentColor : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                color: isPanelExpanded ? AppColors.cardBackground : AppColors.textNormal,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(
                            isPanelExpanded ? Icons.expand_less : Icons.expand_more,
                            color: isPanelExpanded ? AppColors.cardBackground : AppColors.textMedium,
                          ),
                        ],
                      ),
                    );
                  },
                  body: Container(
                    // El margen del body debe coincidir con el del header para alineación.
                    margin: const EdgeInsets.symmetric(horizontal: 16.0).copyWith(bottom: 8.0, left: 16.0 + 4.0, right: 16.0 + 4.0),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accentColor.withAlpha(125))),
                    child: Column(
                      children: entry.value.map((mi) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          title: Text(
                            mi.musculo.titulo,
                            style: const TextStyle(color: AppColors.textNormal, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            mi.descripcionImplicacion,
                            style: TextStyle(color: AppColors.textMedium, fontSize: 12),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MusculoDetallePage(musculo: mi.musculo.titulo, entrenamientos: const []),
                            ),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          // Efecto visual al hacer hover o tap
                          hoverColor: AppColors.accentColor.withAlpha(25),
                          splashColor: AppColors.accentColor.withAlpha(50),
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
      // final Paint linePaint = Paint()
      //   ..strokeWidth = 1.0
      //   ..color = AppColors.textNormal;
      // canvas.drawLine(offset + Offset(textPainter.width / 2, textPainter.height), labelPos, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
