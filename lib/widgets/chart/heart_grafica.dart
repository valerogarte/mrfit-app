import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/health/health.dart';

class HeartGrafica extends StatelessWidget {
  // Ahora recibe la lista original de datos
  final List<HealthDataPoint> dataPoints;
  final DateTime? startDate;
  final DateTime? endDate;
  final String granularity;

  /// [startDate] y [endDate] son opcionales. Si se proporcionan, el eje X se ajusta al rango horario entre ambas.
  const HeartGrafica({
    Key? key,
    required this.dataPoints,
    required this.granularity,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  // Convierte HealthDataPoint -> FlSpot internamente
  /// Convierte HealthDataPoint a FlSpot.
  /// Si [startDate] y [endDate] son nulos, pinta desde las 00:00 hasta las 23:59:59.
  List<FlSpot> _buildSpots() {
    if (dataPoints.isEmpty) return [];

    if (startDate != null) {
      final refStart = startDate!;
      final refEnd = endDate;
      return dataPoints.where((dp) {
        final d = dp.dateFrom;
        return !(refEnd != null && (d.isBefore(refStart) || d.isAfter(refEnd)));
      }).map((dp) {
        final secs = dp.dateFrom.difference(refStart).inSeconds.toDouble();
        final hours = secs / 3600.0;
        final value = (dp.value as NumericHealthValue).numericValue.toDouble();
        return FlSpot(hours, value);
      }).toList();
    } else {
      // Si no hay fechas, mapea cada punto al rango 0-24h (día completo)
      return dataPoints.map((dp) {
        final d = dp.dateFrom;
        final hours = d.hour + d.minute / 60.0 + d.second / 3600.0;
        final value = (dp.value as NumericHealthValue).numericValue.toDouble();
        return FlSpot(hours, value);
      }).toList();
    }
  }

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
    bool isRangeLabel = false, // Nuevo parámetro para distinguir los labels de rango
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
                    // Aplica sombra solo a los labels de rango
                    shadows: isRangeLabel
                        ? [
                            Shadow(
                              color: AppColors.background,
                              offset: const Offset(0, 0),
                              blurRadius: 1,
                            ),
                          ]
                        : null,
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
          isRangeLabel: true, // Aplica sombra a los labels de rango
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
            isRangeLabel: true, // Aplica sombra a los labels de rango
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
    final spots = _buildSpots();
    // Calcular dinámicamente minY y maxY según los datos disponibles
    final double minY = spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) : 0;
    final double maxY = spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) : 0;
    // Determina el rango del eje X según las fechas proporcionadas o por defecto 0-24h
    double minX, maxX;
    double xInterval;

    if (startDate != null && endDate != null) {
      // Calcula la diferencia en horas entre las fechas
      minX = 0;
      final duration = endDate!.difference(startDate!);
      maxX = duration.inMinutes / 60.0;
      // Intervalo dinámico para no saturar el eje X
      if (maxX <= 3) {
        xInterval = 0.5;
      } else if (maxX <= 6) {
        xInterval = 1;
      } else if (maxX <= 12) {
        xInterval = 2;
      } else {
        xInterval = 3;
      }
    } else {
      minX = 0;
      maxX = 24;
      xInterval = 6;
    }

    final mean = HealthUtils.getAvgByGranularity(dataPoints, granularity: granularity).toDouble();

    final yAxisValues = _getYAxisValues(minY, maxY);

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          LineChart(
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
                    getTitlesWidget: (value, meta) {
                      // Si hay fechas, mostrar la hora relativa al inicio
                      if (startDate != null && endDate != null) {
                        final minutes = (value * 60).round();
                        final labelTime = startDate!.add(Duration(minutes: minutes));
                        final hour = labelTime.hour.toString().padLeft(2, '0');
                        final minute = labelTime.minute.toString().padLeft(2, '0');
                        // Determina si es el último label (end)
                        final isEnd = (value - maxX).abs() < 0.01;
                        final isStart = (value - minX).abs() < 0.01;
                        // Usa un ancho fijo para todos los labels de hora y alinea el último a la derecha
                        return SizedBox(
                          width: 60,
                          child: Text(
                            '$hour:$minute',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: isStart
                                ? TextAlign.right
                                : isEnd
                                    ? TextAlign.left
                                    : TextAlign.center,
                          ),
                        );
                      }
                      // Por defecto, mostrar como "xh"
                      return Text('${value.toInt()}h', style: const TextStyle(color: Colors.grey, fontSize: 12));
                    },
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
              minX: minX,
              maxX: maxX,
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
                    // Eliminamos la etiqueta de la línea de la media
                    label: null,
                  ),
                  ..._buildHorizontalLines(
                    minY: minY,
                    maxY: maxY,
                    color: Colors.grey,
                  ),
                ],
                verticalLines: _buildVerticalLines(
                  minX: minX,
                  maxX: maxX,
                  interval: xInterval,
                  color: Colors.grey,
                ),
              ),
              // Añadimos configuración para mostrar el tooltip personalizado
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      String hourLabel;
                      if (startDate != null && endDate != null) {
                        final minutes = (spot.x * 60).round();
                        final labelTime = startDate!.add(Duration(minutes: minutes));
                        final hour = labelTime.hour.toString().padLeft(2, '0');
                        final minute = labelTime.minute.toString().padLeft(2, '0');
                        hourLabel = '$hour:$minute';
                      } else {
                        final hour = spot.x.floor().toString().padLeft(2, '0');
                        final minute = ((spot.x - spot.x.floor()) * 60).round().toString().padLeft(2, '0');
                        hourLabel = '$hour:$minute';
                      }
                      return LineTooltipItem(
                        '${spot.y.toInt()} - $hourLabel',
                        const TextStyle(
                          color: AppColors.mutedRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      );
                    }).toList();
                  },
                ),
                getTouchedSpotIndicator: (barData, spotIndexes) {
                  // Personaliza el indicador del punto tocado (dot pequeño y color personalizado)
                  return spotIndexes.map((index) {
                    return TouchedSpotIndicatorData(
                      FlLine(
                        color: AppColors.mutedRed,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.mutedRed,
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
          // Etiqueta de la media fuera del gráfico, alineada a la derecha
          Positioned(
            right: 0,
            // Calcula la posición vertical relativa a la media
            top: 200 * (1 - (mean - minY) / (maxY - minY)) - 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background.withAlpha(160),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                mean.toInt().toString(),
                style: TextStyle(
                  color: AppColors.mutedRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
