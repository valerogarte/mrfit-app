import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mrfit/utils/colors.dart';

class HeartGrafica extends StatelessWidget {
  final List<FlSpot> spots;
  final double minY;
  final double maxY;
  final double mean;

  const HeartGrafica({
    Key? key,
    required this.spots,
    required this.minY,
    required this.maxY,
    required this.mean,
  }) : super(key: key);

  // Construye una línea vertical personalizada.
  VerticalLine _buildVerticalLine(double x, Color color) {
    return VerticalLine(
      x: x,
      color: color.withAlpha(51),
      strokeWidth: 1,
      dashArray: [4, 4],
    );
  }

  // Genera las líneas verticales del gráfico.
  List<VerticalLine> _buildVerticalLines({
    required double minX,
    required double maxX,
    required double interval,
    required Color color,
  }) {
    final List<VerticalLine> lines = [];
    lines.add(_buildVerticalLine(minX, color));
    for (double x = minX + interval; x < maxX; x += interval) {
      lines.add(_buildVerticalLine(x, color));
    }
    lines.add(_buildVerticalLine(maxX, color));
    return lines;
  }

  // Devuelve el mapa de valores y etiquetas de los rangos cardíacos.
  Map<int, String> get _labeledValues => const {
        94: 'Relax',
        113: 'Calentamiento',
        130: 'Quema grasa',
        170: 'Cardio',
        187: 'Anaeróbico',
      };

  // Construye una línea horizontal con etiqueta opcional.
  HorizontalLine _buildHorizontalLine({
    required double y,
    required Color color,
    String? label,
    TextStyle? style,
    Color? labelColor,
    bool isDanger = false,
  }) {
    return HorizontalLine(
      y: y,
      color: isDanger ? Colors.red.withAlpha(100) : color.withAlpha(51),
      strokeWidth: isDanger ? 2 : 1,
      dashArray: [4, 4],
      label: label != null
          ? HorizontalLineLabel(
              show: true,
              alignment: Alignment.centerLeft,
              style: style ??
                  TextStyle(
                    color: labelColor ?? Colors.grey,
                    fontSize: isDanger ? 12 : 10,
                    fontWeight: isDanger ? FontWeight.bold : FontWeight.w400,
                  ),
              padding: const EdgeInsets.only(top: 10),
              labelResolver: (_) => label,
            )
          : null,
    );
  }

  // Genera las líneas horizontales del gráfico, incluyendo rangos y advertencias.
  List<HorizontalLine> _buildHorizontalLines({
    required double minY,
    required double maxY,
    required Color color,
  }) {
    final List<HorizontalLine> lines = [];
    lines.add(_buildHorizontalLine(y: minY, color: color));
    lines.add(_buildHorizontalLine(y: maxY, color: color));

    final List<double> inRangeKeys = [];
    // Se asegura que 'y' sea double al llamar a _buildHorizontalLine y al agregar a inRangeKeys
    _labeledValues.forEach((y, label) {
      if (y > minY && y < maxY) {
        lines.add(_buildHorizontalLine(
          y: y.toDouble(),
          color: color,
          label: label,
        ));
        inRangeKeys.add(y.toDouble());
      }
    });

    // Añade el siguiente rango superior si corresponde
    if (inRangeKeys.isNotEmpty) {
      final lastRange = inRangeKeys.last;
      if (maxY - lastRange >= 10) {
        final sortedKeys = _labeledValues.keys.toList()..sort();
        final nextKey = sortedKeys.firstWhere(
          (k) => k > lastRange,
          orElse: () => 0,
        );
        if (nextKey != 0) {
          lines.add(_buildHorizontalLine(
            y: maxY.toDouble(),
            color: color,
            label: _labeledValues[nextKey],
          ));
        }
      }
    }

    // Si el máximo supera 187, mostrar advertencia de peligro
    if (maxY > 187) {
      lines.add(_buildHorizontalLine(
        y: maxY,
        color: color,
        label: 'Peligroso',
        style: const TextStyle(
          color: Colors.red,
          fontSize: 10,
        ),
        isDanger: true,
      ));
    }

    return lines;
  }

  // Devuelve los valores y etiquetas a mostrar en el eje Y.
  List<double> _getYAxisValues(double minY, double maxY) {
    final List<double> values = [minY, maxY];
    const labeledKeys = [94.0, 113.0, 130.0, 170.0, 187.0];
    for (final y in labeledKeys) {
      if (y > minY && y < maxY) {
        values.add(y);
      }
    }
    values.sort();
    return values;
  }

  // Devuelve la etiqueta para cada valor del eje Y.
  String? _getYAxisLabel(double value, double minY, double maxY) {
    if (value == minY) return minY.toInt().toString();
    if (value == maxY) return maxY.toInt().toString();
    final labeledValues = [94.0, 113.0, 130.0, 170.0, 187.0];
    if (labeledValues.contains(value)) {
      return value.toInt().toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const double xInterval = 6;
    final yAxisValues = _getYAxisValues(minY, maxY);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: false,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: xInterval,
                getTitlesWidget: (value, meta) => Text('${value.toInt()}h', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (yAxisValues.contains(value)) {
                    final label = _getYAxisLabel(value, minY, maxY);
                    if (label != null) {
                      return Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12));
                    }
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 25,
                interval: 1,
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 24,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.mutedRed,
              barWidth: 1,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.mutedRed.withAlpha(77),
                    AppColors.mutedRed.withAlpha(77),
                    AppColors.mutedRed.withAlpha(0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: mean,
                color: AppColors.mutedRed,
                strokeWidth: 1,
                dashArray: [4, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  style: TextStyle(color: AppColors.mutedRed),
                  labelResolver: (line) => line.y.toInt().toString(),
                ),
              ),
              ..._buildHorizontalLines(
                minY: minY,
                maxY: maxY,
                color: Colors.grey,
              ),
            ],
            verticalLines: _buildVerticalLines(
              minX: 0,
              maxX: 24,
              interval: xInterval,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
