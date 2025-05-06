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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
  }
}
