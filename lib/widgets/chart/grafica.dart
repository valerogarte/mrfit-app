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
    super.key,
    this.title,
    required this.labels,
    required this.values,
    this.textNoResults = '',
  });

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

    // Ajuste dinámico del rango Y para mejorar visualización si los datos varían poco
    double computedMaxY;
    double computedMinY;
    final double diff = maxVal - minVal;
    if (diff <= 10) {
      // Si la diferencia es pequeña, ajusta el rango para que la gráfica sea más detallada
      computedMaxY = maxVal + (diff == 0 ? 5 : diff * 0.5);
      computedMinY = minVal - (diff == 0 ? 5 : diff * 0.5);
      // Evita que el mínimo sea negativo
      if (computedMinY > 0 && computedMinY < minVal) {
        computedMinY = computedMinY;
      } else {
        computedMinY = minVal > 0 ? minVal * 0.8 : minVal;
      }
    } else {
      computedMaxY = (maxVal * 1.2).ceilToDouble();
      computedMinY = minVal > 0 ? (minVal * 0.8).floorToDouble() : minVal;
    }

    // Eje Y: 5 divisiones
    const int divisions = 5;
    final double range = computedMaxY - computedMinY;
    final double computedInterval = divisions > 1 ? range / (divisions - 1) : 1;

    // Etiquetas del eje X (máx 10)
    final int totalLabels = labels.length;
    final int showLabels = 10;
    final List<int> displayIndices = totalLabels <= showLabels
        ? List.generate(totalLabels, (i) => i)
        : List.generate(
            showLabels,
            (i) => i == (showLabels - 1) ? totalLabels - 1 : (i * ((totalLabels - 1) / (showLabels - 1))).round(),
          );

    // Índices de valor máximo y mínimo
    int maxIndex = 0;
    int minIndex = 0;
    for (int i = 0; i < values.length; i++) {
      if (values[i] == maxVal) maxIndex = i;
    }
    // El índice del valor mínimo debe ser el más antiguo (primer valor mínimo encontrado)
    for (int i = 0; i < values.length; i++) {
      if (values[i] == minVal) {
        minIndex = i;
        break;
      }
    }

    // Cálculo dinámico del ancho reservado para los valores del eje Y
    final double reservedYAxisWidth = (() {
      final yValues = [computedMinY, computedMaxY, minVal, maxVal, ...values];
      final longest = yValues.map((v) => v.toStringAsFixed(1)).reduce((a, b) => a.length > b.length ? a : b);
      final tp = TextPainter(
        text: TextSpan(
          text: longest,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final width = tp.width + 8;
      return (width > 40 ? 40 : width).toDouble();
    })();

    // Maquetación tipo HeartGrafica: Stack, sin bordes ni paddings extra
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: reservedYAxisWidth, bottom: 16.0),
            child: Text(
              title!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        SizedBox(
          height: 200,
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    LineChart(
                      LineChartData(
                        backgroundColor: Colors.transparent,
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
                                // Destaca el máximo y mínimo con un círculo pequeño y borde accentColor
                                if (index == maxIndex) {
                                  return FlDotCirclePainter(
                                    radius: 3,
                                    color: AppColors.mutedAdvertencia,
                                    strokeWidth: 2,
                                    strokeColor: AppColors.accentColor,
                                  );
                                } else if (index == minIndex) {
                                  return FlDotCirclePainter(
                                    radius: 3,
                                    color: AppColors.cardBackground,
                                    strokeWidth: 2,
                                    strokeColor: AppColors.accentColor,
                                  );
                                }
                                return FlDotCirclePainter(
                                  radius: 0,
                                  color: Colors.transparent,
                                  strokeWidth: 0,
                                );
                              },
                            ),
                            color: AppColors.accentColor,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.accentColor.withAlpha(77),
                                  AppColors.accentColor.withAlpha(0),
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
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
                                    int months = (duration.inDays % 365) ~/ 30;
                                    formattedDuration = '$years y $months m';
                                  } else if (duration.inDays >= 30) {
                                    int months = duration.inDays ~/ 30;
                                    int days = duration.inDays % 30;
                                    formattedDuration = '$months m $days d';
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
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
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
                              reservedSize: reservedYAxisWidth,
                              interval: computedInterval,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: false,
                          drawVerticalLine: false,
                          drawHorizontalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        extraLinesData: ExtraLinesData(
                          horizontalLines: [
                            // Línea discontinua superior (máximo del gráfico)
                            HorizontalLine(
                              y: computedMaxY,
                              color: AppColors.textMedium.withAlpha(50),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                            // Línea discontinua inferior (mínimo del gráfico)
                            HorizontalLine(
                              y: computedMinY,
                              color: AppColors.textMedium.withAlpha(50),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                            // Línea de máximo real en mutedAdvertencia
                            HorizontalLine(
                              y: maxVal,
                              color: AppColors.mutedAdvertencia.withAlpha(100),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                            // Línea de mínimo real en mutedRed
                            HorizontalLine(
                              y: minVal,
                              color: AppColors.mutedRed.withAlpha(100),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                          ],
                          verticalLines: [
                            // Bordes izquierdo y derecho
                            VerticalLine(
                              x: 0,
                              color: AppColors.textMedium.withAlpha(50),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                            VerticalLine(
                              x: (labels.length - 1).toDouble(),
                              color: AppColors.textMedium.withAlpha(50),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                            ),
                            // Líneas verticales equidistantes según las etiquetas del eje X
                            ...(() {
                              // Calcula los mismos índices que displayIndices pero omite los bordes
                              final indices = displayIndices.where((i) => i != 0 && i != labels.length - 1).toList();
                              return indices.map((i) => VerticalLine(
                                    x: i.toDouble(),
                                    color: AppColors.textMedium.withAlpha(30),
                                    strokeWidth: 1,
                                    dashArray: [5, 5],
                                  ));
                            })(),
                          ],
                        ),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              // Solo muestra el valor de Y en el tooltip
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  spot.y.toStringAsFixed(1),
                                  const TextStyle(
                                    color: AppColors.accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                          getTouchedSpotIndicator: (barData, spotIndexes) {
                            return spotIndexes.map((index) {
                              return TouchedSpotIndicatorData(
                                FlLine(
                                  color: AppColors.accentColor,
                                  strokeWidth: 1,
                                  dashArray: [4, 4],
                                ),
                                FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) {
                                    return FlDotCirclePainter(
                                      radius: 3,
                                      color: AppColors.accentColor,
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
                    // Puedes agregar aquí otros overlays como etiquetas, si lo requieres
                  ],
                ),
              ),
              const SizedBox(width: 4), // Espacio a la derecha del gráfico aumentado a 5
            ],
          ),
        ),
      ],
    );
  }
}
