import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:fl_chart/fl_chart.dart';

Widget dailyHearthWidget({
  required DateTime day,
  required Usuario usuario,
}) {
  return FutureBuilder<Map<DateTime, double>>(
    future: usuario.getReadHeartRateByDate(day),
    builder: (context, snapshot) {
      final heartRateData = snapshot.data ?? {};
      final spots = heartRateData.entries.map((entry) {
        final time = entry.key.hour + entry.key.minute / 60.0;
        return FlSpot(time, entry.value);
      }).toList();

      // Cálculo dinámico de rangos
      Widget content;
      if (spots.isNotEmpty) {
        final highest = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
        final lowest = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);

        double maxY = (highest + 20).ceilToDouble();
        maxY = (maxY % 10 == 0) ? maxY : (maxY + (10 - maxY % 10));

        double minY = (lowest - 20).floorToDouble();
        minY = (minY % 10 == 0) ? minY : (minY - (minY % 10));
        minY = minY < 0 ? 0 : minY;

        final mean = spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;

        content = SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 6,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}h', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 50,
                    getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                  belowBarData: BarAreaData(show: false),
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
                ],
              ),
            ),
          ),
        );
      } else if (snapshot.connectionState == ConnectionState.waiting) {
        content = const Center(child: CircularProgressIndicator());
      } else {
        content = const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Sin registros durante el día.",
            style: TextStyle(color: AppColors.textMedium, fontSize: 16),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.appBarBackground.withAlpha(75),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.background,
                  child: const Icon(Icons.favorite, color: AppColors.mutedRed, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Frecuencia cardíaca",
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            content,
          ],
        ),
      );
    },
  );
}
