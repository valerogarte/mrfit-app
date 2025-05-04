// lib/widgets/chart/sleep_bar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';

const int _kRoutineBedHour = 23;
const int _kRoutineBedMinute = 30;
const int _kRoutineWakeHour = 8;
const int _kRoutineWakeMinute = 15;

const Color _kRoutineColor = AppColors.background;
const Color _kSuenoRealColor = AppColors.accentColor;

const double _kBarHeight = 28.0; // altura total de la zona de barras
const double _kActualFactor = .60; // proporción de la 'barrita' real
const double _kLabelH = 16.0; // espacio para etiquetas arriba/abajo

// valores 0–5 para cada tipo de sueño
const Map<String, int> _kTypeValue = {
  'SLEEP_DEEP': 5,
  'SLEEP_REM': 4,
  'SLEEP_LIGHT': 3,
  'SLEEP_ASLEEP': 2,
  'SLEEP_IN_BED': 2,
  'SLEEP_AWAKE_IN_BED': 1,
  'SLEEP_AWAKE': 1,
  'SLEEP_OUT_OF_BED': 0,
  'SLEEP_UNKNOWN': 0,
};

class SleepBar extends StatelessWidget {
  const SleepBar({
    Key? key,
    required this.realStart,
    required this.realEnd,
    this.typeSlots = const [],
  }) : super(key: key);

  final DateTime realStart;
  final DateTime realEnd;
  final List<SleepSlot> typeSlots;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final accentHeight = _kBarHeight * _kActualFactor;

    final today = DateTime(realEnd.year, realEnd.month, realEnd.day);
    final routineStart = today.subtract(const Duration(days: 1)).add(const Duration(hours: _kRoutineBedHour, minutes: _kRoutineBedMinute));
    final routineEnd = today.add(
      const Duration(hours: _kRoutineWakeHour, minutes: _kRoutineWakeMinute),
    );

    final graphStart = realStart.isBefore(routineStart) ? realStart : routineStart;
    final graphEnd = realEnd.isAfter(routineEnd) ? realEnd : routineEnd;
    final totalMinutes = graphEnd.difference(graphStart).inMinutes;
    if (totalMinutes <= 0) return const SizedBox.shrink();

    final spots = typeSlots.where((s) => _kTypeValue.containsKey(s.type)).map((s) {
      final x = s.start.difference(graphStart).inMinutes.toDouble();
      final y = (_kTypeValue[s.type] ?? 0).toDouble();
      return FlSpot(x, y);
    }).toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return SizedBox(
      width: width,
      height: _kBarHeight + _kLabelH * 2,
      child: LayoutBuilder(
        builder: (ctx, cons) {
          final pxPerMin = cons.maxWidth / totalMinutes;

          final realLeft = realStart.difference(graphStart).inMinutes * pxPerMin;
          final realWidthPx = realEnd.difference(realStart).inMinutes * pxPerMin;
          final routineLeft = routineStart.difference(graphStart).inMinutes * pxPerMin;
          final routineWidthPx = routineEnd.difference(routineStart).inMinutes * pxPerMin;
          final realRightOffset = cons.maxWidth - (realLeft + realWidthPx);

          return Stack(children: [
            _buildRoutineLabels(routineStart, routineEnd, routineLeft, routineWidthPx, cons.maxWidth),
            _buildRoutineZone(routineLeft, routineWidthPx),
            _buildSessionBar(realLeft, realWidthPx, accentHeight),
            _buildSessionLabels(realStart, realEnd, realLeft, realRightOffset),
            _buildSleepLine(spots, totalMinutes, accentHeight),
          ]);
        },
      ),
    );
  }

  Widget _buildRoutineLabels(DateTime start, DateTime end, double left, double width, double maxWidth) {
    return Stack(children: [
      Positioned(
        top: 0,
        left: left,
        child: Text(
          DateFormat.Hm().format(start),
          style: const TextStyle(fontSize: 12, color: AppColors.mutedGreen),
        ),
      ),
      Positioned(
        top: 0,
        right: maxWidth - (left + width),
        child: Text(
          DateFormat.Hm().format(end),
          style: const TextStyle(fontSize: 12, color: AppColors.mutedGreen),
        ),
      ),
    ]);
  }

  Widget _buildRoutineZone(double left, double width) {
    return Positioned(
      top: _kLabelH,
      left: left,
      width: width,
      height: _kBarHeight,
      child: Container(
        decoration: BoxDecoration(
          color: _kRoutineColor,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildSessionBar(double left, double width, double height) {
    return Positioned(
      top: _kLabelH + (_kBarHeight - height) / 2,
      left: left,
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: _kSuenoRealColor,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildSessionLabels(DateTime start, DateTime end, double left, double rightOffset) {
    return Stack(children: [
      Positioned(
        bottom: 0,
        left: left,
        child: Text(
          DateFormat.Hm().format(start),
          style: const TextStyle(fontSize: 12, color: AppColors.accentColor),
        ),
      ),
      Positioned(
        bottom: 0,
        right: rightOffset,
        child: Text(
          DateFormat.Hm().format(end),
          style: const TextStyle(fontSize: 12, color: AppColors.accentColor),
        ),
      ),
    ]);
  }

  Widget _buildSleepLine(List<FlSpot> spots, int maxX, double height) {
    // Lo último para quedar encima de la barrita, usa left+right para ocupar todo el ancho
    return Positioned(
      top: _kLabelH + (_kBarHeight - height) / 2 + 2,
      left: 0,
      right: 0,
      height: height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX.toDouble(),
          minY: 0,
          maxY: 5,
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppColors.mutedAdvertencia,
              isStrokeCapRound: true,
              barWidth: 2,
              dotData: FlDotData(show: false),
              shadow: const Shadow(
                color: AppColors.background,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            )
          ],
        ),
      ),
    );
  }
}
