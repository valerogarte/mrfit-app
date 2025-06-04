// lib/widgets/chart/sleep_bar.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';

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
  'SLEEP_ASLEEP': 3,
  'SLEEP_IN_BED': 3,
  'SLEEP_AWAKE_IN_BED': 1,
  'SLEEP_AWAKE': 1,
  'SLEEP_OUT_OF_BED': 2,
  'SLEEP_UNKNOWN': 0,
};

// Mapa de etiquetas legibles para cada tipo de sueño
const Map<String, String> _kTypeLabel = {
  'SLEEP_DEEP': 'Profundo',
  'SLEEP_REM': 'REM',
  'SLEEP_LIGHT': 'Ligero',
  'SLEEP_ASLEEP': 'Dormido',
  'SLEEP_IN_BED': 'En cama',
  'SLEEP_AWAKE_IN_BED': 'Despierto en cama',
  'SLEEP_AWAKE': 'Despierto',
  'SLEEP_OUT_OF_BED': 'Fuera de cama',
  'SLEEP_UNKNOWN': 'Desconocido',
};

class SleepBar extends StatelessWidget {
  const SleepBar({
    super.key,
    required this.realStart,
    required this.realEnd,
    required this.horaInicioRutina,
    required this.horaFinRutina,
    this.typeSlots = const [],
    this.showSessionLabels = true,
  });

  final DateTime realStart;
  final DateTime realEnd;
  final TimeOfDay horaInicioRutina;
  final TimeOfDay horaFinRutina;
  final List<SleepSlot> typeSlots;
  final bool showSessionLabels;

  // Método auxiliar para obtener el tipo de sueño según el minuto (x)
  String _getSleepTypeByMinute(double minute, List<SleepSlot> slots, DateTime graphStart) {
    for (final slot in slots) {
      final startMin = slot.start.difference(graphStart).inMinutes.toDouble();
      final endMin = slot.end.difference(graphStart).inMinutes.toDouble();
      if (minute >= startMin && minute < endMin) {
        return slot.type;
      }
    }
    return 'SLEEP_UNKNOWN';
  }

  // Devuelve la etiqueta legible para el tipo de sueño
  String _getSleepTypeLabel(String type) {
    return _kTypeLabel[type] ?? type;
  }

  /// Genera los puntos para un gráfico tipo "step" (escalera) solo dentro del rango de sueño real.
  List<FlSpot> _generateStepSpots(
    List<SleepSlot> slots,
    DateTime graphStart,
    DateTime graphEnd,
    DateTime realStart,
    DateTime realEnd,
  ) {
    const double epsilon = 0.0001; // pequeño desplazamiento para evitar x duplicados
    final List<FlSpot> stepSpots = [];
    if (slots.isEmpty) return stepSpots;

    // Ordenar los slots por inicio
    final sortedSlots = List<SleepSlot>.from(slots)..sort((a, b) => a.start.compareTo(b.start));

    final realStartX = realStart.difference(graphStart).inMinutes.toDouble();
    final realEndX = realEnd.difference(graphStart).inMinutes.toDouble();

    for (var i = 0; i < sortedSlots.length; i++) {
      final slot = sortedSlots[i];
      final slotStartX = slot.start.difference(graphStart).inMinutes.toDouble();
      final slotEndX = slot.end.difference(graphStart).inMinutes.toDouble();
      final y = (_kTypeValue[slot.type] ?? 0).toDouble();

      // Calcular el inicio y fin del slot recortado al rango real
      final startX = slotStartX.clamp(realStartX, realEndX);
      final endX = slotEndX.clamp(realStartX, realEndX);

      // Si el slot está completamente fuera del rango real, omitir
      if (endX <= realStartX || startX >= realEndX) continue;

      // Si es el primer punto y no coincide con realStartX, agregar punto inicial horizontal
      if (stepSpots.isEmpty && startX > realStartX) {
        stepSpots.add(FlSpot(realStartX, y));
      }

      // Si el slot no empieza donde terminó el anterior, agregar transición vertical
      if (stepSpots.isNotEmpty && stepSpots.last.x != startX) {
        stepSpots.add(FlSpot(startX, stepSpots.last.y));
        // pequeño desplazamiento para el punto vertical
        stepSpots.add(FlSpot(startX + epsilon, y));
      } else {
        stepSpots.add(FlSpot(startX, y));
      }

      stepSpots.add(FlSpot(endX, y));
    }

    // Si el último punto no llega hasta realEndX, bajar a 0
    if (stepSpots.isNotEmpty && stepSpots.last.x < realEndX) {
      stepSpots.add(FlSpot(realEndX, stepSpots.last.y));
      stepSpots.add(FlSpot(realEndX, 0));
    }

    return stepSpots;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final accentHeight = _kBarHeight * _kActualFactor;

    final today = DateTime(realEnd.year, realEnd.month, realEnd.day);
    final routineStart = horaInicioRutina.hour > horaFinRutina.hour
        ? today.subtract(const Duration(days: 1)).add(
              Duration(hours: horaInicioRutina.hour, minutes: horaInicioRutina.minute),
            )
        : today.add(Duration(hours: horaInicioRutina.hour, minutes: horaInicioRutina.minute));
    final routineEnd = today.add(
      Duration(hours: horaFinRutina.hour, minutes: horaFinRutina.minute),
    );

    final graphStart = realStart.isBefore(routineStart) ? realStart : routineStart;
    final graphEnd = realEnd.isAfter(routineEnd) ? realEnd : routineEnd;
    final totalMinutes = graphEnd.difference(graphStart).inMinutes;
    if (totalMinutes <= 0) return const SizedBox.shrink();

    // Generar los puntos tipo "step" solo dentro del rango de sueño real
    final stepSpots = _generateStepSpots(
      typeSlots,
      graphStart,
      graphEnd,
      realStart,
      realEnd,
    );

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
            _buildRoutineLabels(
                routineStart, routineEnd, routineLeft, routineWidthPx, cons.maxWidth),
            _buildRoutineZone(routineLeft, routineWidthPx),
            if (realWidthPx > 0)
              _buildSessionBar(realLeft, realWidthPx, accentHeight),
            if (showSessionLabels)
              _buildSessionLabels(realStart, realEnd, realLeft, realRightOffset),
            if (stepSpots.isNotEmpty)
              _buildSleepLine(stepSpots, totalMinutes, accentHeight, graphStart),
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

  Widget _buildSleepLine(List<FlSpot> spots, int maxX, double height, DateTime graphStart) {
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
              barWidth: 1,
              dotData: FlDotData(
                show: false, // No mostrar puntos normalmente
                checkToShowDot: (spot, barData) => false,
              ),
              showingIndicators: [],
            )
          ],
          // Personalización del tooltip y del círculo de selección
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                // Añade la hora al final de la etiqueta del tipo de sueño
                return touchedSpots.map((touchedSpot) {
                  final sleepType = _getSleepTypeByMinute(
                    touchedSpot.x,
                    typeSlots,
                    graphStart,
                  );
                  final label = _getSleepTypeLabel(sleepType);
                  // Calcula la hora correspondiente al punto seleccionado
                  final pointTime = graphStart.add(Duration(minutes: touchedSpot.x.round()));
                  final formattedTime = DateFormat.Hm().format(pointTime);
                  return LineTooltipItem(
                    '$label $formattedTime',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              // Personaliza el círculo de selección
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: Colors.transparent),
                  FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      return FlDotCirclePainter(
                        radius: 2, // Radio del círculo de selección
                        color: AppColors.background, // Color del círculo
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
