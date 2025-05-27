import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/not_found/not_found.dart';

class ChartWidget extends StatelessWidget {
  final String? title;
  final List<String> labels;
  final List<double> values;
  final String textNoResults;

  const ChartWidget({
    Key? key,
    this.title,
    required this.labels,
    required this.values,
    this.textNoResults = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty || labels.isEmpty) {
      if (textNoResults.isEmpty) {
        return const SizedBox.shrink();
      }
      return NotFoundData(
        title: "Sin datos disponibles",
        textNoResults: textNoResults,
      );
    }

    final List<FlSpot> spots = List.generate(
      values.length,
      (i) => FlSpot(i.toDouble(), values[i]),
    );

    final double maxVal = values.reduce((a, b) => a > b ? a : b);
    final double minVal = values.reduce((a, b) => a < b ? a : b);

    // Ajusta un poco para que no quede pegado a los bordes
    final double computedMaxY = maxVal * 1.2;
    final double computedMinY = minVal > 0 ? minVal * 0.8 : minVal;

    // Define cuántas divisiones quieres en el eje Y
    const int divisions = 5; // Esto te generará 5 marcas en el eje
    final double range = computedMaxY - computedMinY;
    final double computedInterval = divisions > 1 ? range / (divisions - 1) : 1;

    // Determina los índices para las etiquetas del eje X
    final int totalLabels = labels.length;
    final int showLabels = 10;
    final List<int> displayIndices = totalLabels <= showLabels ? List.generate(totalLabels, (i) => i) : List.generate(showLabels, (i) => i == (showLabels - 1) ? totalLabels - 1 : (i * ((totalLabels - 1) / (showLabels - 1))).round());

    // Buscamos los índices de valor mínimo y máximo
    int maxIndex = 0;
    int minIndex = 0;
    for (int i = 0; i < values.length; i++) {
      if (values[i] == maxVal) {
        maxIndex = i;
      }
      if (values[i] == minVal) {
        minIndex = i;
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        height: 275,
        color: AppColors.cardBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null && title!.isNotEmpty)
              Text(
                title!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            if (title != null && title!.isNotEmpty) const SizedBox(height: 20),
            Expanded(
              child: LineChart(
                LineChartData(
                  backgroundColor: AppColors.background,
                  minY: computedMinY,
                  maxY: computedMaxY,
                  minX: 0,
                  maxX: (labels.length - 1).toDouble(),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          if (index == maxIndex) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.amber,
                              strokeWidth: 0,
                            );
                          } else if (index == minIndex) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: Colors.redAccent,
                              strokeWidth: 0,
                            );
                          }
                          return FlDotCirclePainter(
                            radius: 0,
                            color: Colors.transparent,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      color: Colors.blue,
                      barWidth: 2,
                    ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= labels.length || !displayIndices.contains(index)) {
                            return const SizedBox();
                          }
                          final dateString = labels[index];
                          String formattedDuration;
                          try {
                            final dateTime = DateTime.parse(dateString);
                            final now = DateTime.now();
                            final duration = now.difference(dateTime);

                            if (duration.inDays >= 365) {
                              int years = duration.inDays ~/ 365;
                              int remainingDays = duration.inDays % 365;
                              int months = remainingDays ~/ 30;
                              formattedDuration = '$years y $months m';
                            } else if (duration.inDays >= 30) {
                              int months = duration.inDays ~/ 30;
                              int remainingDays = duration.inDays % 30;
                              formattedDuration = '$months m $remainingDays d';
                            } else if (duration.inDays >= 1 && duration.inDays < 3) {
                              formattedDuration = '${duration.inDays} d ${duration.inHours % 24} h';
                            } else if (duration.inDays >= 1) {
                              formattedDuration = '${duration.inDays} d';
                            } else if (duration.inHours < 1) {
                              formattedDuration = '${duration.inMinutes} m';
                            } else {
                              formattedDuration = '${duration.inHours} h ${duration.inMinutes % 60} m';
                            }
                          } catch (e) {
                            // Si no es una fecha, simplemente muestra el texto original
                            formattedDuration = dateString;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Transform.rotate(
                              angle: -math.pi / 2,
                              child: SizedBox(
                                width: 50,
                                child: Text(
                                  formattedDuration,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        // Aquí establecemos nuestro intervalo calculado
                        interval: computedInterval,
                        getTitlesWidget: (value, meta) {
                          // Muestra todas las marcas en el eje Y
                          return Text(
                            value.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: maxVal,
                        color: Colors.grey,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                      HorizontalLine(
                        y: minVal,
                        color: Colors.grey,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
