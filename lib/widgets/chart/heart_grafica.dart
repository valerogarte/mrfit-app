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

  // Calcula las posiciones de las líneas verticales según el intervalo del eje X,
  // incluyendo el primer y último valor.
  List<VerticalLine> _buildVerticalLines({
    required double minX,
    required double maxX,
    required double interval,
    required Color color,
  }) {
    final List<VerticalLine> lines = [];
    // Añade línea en minX
    lines.add(
      VerticalLine(
        x: minX,
        color: color.withAlpha(51), // 0.2 * 255 ≈ 51
        strokeWidth: 1,
        dashArray: [4, 4],
      ),
    );
    // Añade líneas en los intervalos intermedios
    for (double x = minX + interval; x < maxX; x += interval) {
      lines.add(
        VerticalLine(
          x: x,
          color: color.withAlpha(51),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
      );
    }
    // Añade línea en maxX
    lines.add(
      VerticalLine(
        x: maxX,
        color: color.withAlpha(51),
        strokeWidth: 1,
        dashArray: [4, 4],
      ),
    );
    return lines;
  }

  // Calcula las posiciones de las líneas horizontales solo en minY, maxY y los valores de los rangos.
  List<HorizontalLine> _buildHorizontalLines({
    required double minY,
    required double maxY,
    required Color color,
  }) {
    final List<HorizontalLine> lines = [];
    // Línea en minY
    lines.add(
      HorizontalLine(
        y: minY,
        color: color.withAlpha(51),
        strokeWidth: 1,
        dashArray: [4, 4],
      ),
    );
    // Línea en maxY
    lines.add(
      HorizontalLine(
        y: maxY,
        color: color.withAlpha(51),
        strokeWidth: 1,
        dashArray: [4, 4],
      ),
    );
    // Líneas en los valores de los rangos, solo si están dentro del rango
    final Map<double, String> labeledValues = {
      94: 'Relax',
      113: 'Calentamiento',
      130: 'Quemas grasa',
      170: 'Cardio',
      187: 'Anaeróbico',
    };
    labeledValues.forEach((y, label) {
      if (y > minY && y < maxY) {
        lines.add(
          HorizontalLine(
            y: y,
            color: color.withAlpha(51),
            strokeWidth: 1,
            dashArray: [4, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.centerLeft,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
              padding: const EdgeInsets.only(top: 10),
              labelResolver: (_) => label,
            ),
          ),
        );
      }
    });
    return lines;
  }

  // Devuelve los valores y etiquetas a mostrar en el eje Y: min, max y los rangos definidos.
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
    // Si el valor es uno de los rangos, muestra el número
    final labeledValues = [94.0, 113.0, 130.0, 170.0, 187.0];
    if (labeledValues.contains(value)) {
      return value.toInt().toString();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const double xInterval = 6;
    const double yInterval = 50;
    final yAxisValues = _getYAxisValues(minY, maxY);

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: false, // No mostrar líneas horizontales automáticas
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
                // Solo muestra los valores definidos en yAxisValues
                getTitlesWidget: (value, meta) {
                  // Solo muestra el label si el valor está en yAxisValues
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
              // Sombra bajo la línea con gradiente del mismo color y opacidad decreciente
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.mutedRed.withAlpha(77), // 0.3 * 255 ≈ 77
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
              // Línea horizontal de la media
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
              // Solo líneas horizontales en min, max y labeledValues
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
