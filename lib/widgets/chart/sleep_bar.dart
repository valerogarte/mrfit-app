// sleep_bar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/utils/colors.dart';

const int kRoutineBedHour = 23;
const int kRoutineBedMinute = 30;
const int kRoutineWakeHour = 8;
const int kRoutineWakeMinute = 15;

const Color kRoutineColor = AppColors.background; // zona de rutina
const Color kSuenoRealColor = AppColors.accentColor; // barra sueño real

const double kBarHeight = 28.0;
const double kActualFactor = .60;
const double kLabelH = 16.0;

class SleepBar extends StatelessWidget {
  const SleepBar({
    Key? key,
    required this.realStart,
    required this.realEnd,
  }) : super(key: key);

  final DateTime realStart;
  final DateTime realEnd;

  @override
  Widget build(BuildContext context) {
    final double fullWidth = MediaQuery.of(context).size.width;

    // límites de rutina
    final DateTime today = DateTime(realEnd.year, realEnd.month, realEnd.day);
    final DateTime routineStart = today.subtract(const Duration(days: 1)).add(const Duration(hours: kRoutineBedHour, minutes: kRoutineBedMinute));
    final DateTime routineEnd = today.add(const Duration(
      hours: kRoutineWakeHour,
      minutes: kRoutineWakeMinute,
    ));

    // inicio/fin del gráfico (sin redondeos)
    final DateTime graphStart = realStart.isBefore(routineStart) ? realStart : routineStart;
    final DateTime graphEnd = realEnd.isAfter(routineEnd) ? realEnd : routineEnd;

    final int totalMin = graphEnd.difference(graphStart).inMinutes;
    if (totalMin <= 0) return const SizedBox.shrink();

    int _left(DateTime t) => t.difference(graphStart).inMinutes;
    int _width(DateTime a, DateTime b) => b.difference(a).inMinutes;

    final int routineLeft = _left(routineStart);
    final int routineWidth = _width(routineStart, routineEnd);
    final int realLeft = _left(realStart);
    final int realWidth = _width(realStart, realEnd);

    return Container(
      width: fullWidth,
      height: kBarHeight + kLabelH * 2,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double pxPerMin = constraints.maxWidth / totalMin;
          final double rStartX = routineLeft * pxPerMin; // debería ser 0
          final double rWidthPx = routineWidth * pxPerMin;
          final double sStartX = realLeft * pxPerMin;
          final double sWidthPx = realWidth * pxPerMin;
          final double graphWidth = constraints.maxWidth;
          final double realEndRight = graphWidth - (sStartX + sWidthPx); // debería ser 0

          return Stack(
            children: [
              // etiqueta inicio rutina
              Positioned(
                top: 0,
                left: rStartX,
                child: Text(
                  DateFormat.Hm().format(routineStart),
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedGreen),
                ),
              ),
              // etiqueta fin rutina
              Positioned(
                top: 0,
                right: graphWidth - (rStartX + rWidthPx),
                child: Text(
                  DateFormat.Hm().format(routineEnd),
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedGreen),
                ),
              ),
              // zona rutina
              Positioned(
                top: kLabelH,
                left: rStartX,
                width: rWidthPx,
                height: kBarHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: kRoutineColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              // barra sueño real
              Positioned(
                top: kLabelH + (kBarHeight * (1 - kActualFactor)) / 2,
                left: sStartX,
                width: sWidthPx,
                height: kBarHeight * kActualFactor,
                child: Container(
                  decoration: BoxDecoration(
                    color: kSuenoRealColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // etiqueta inicio sueño real
              Positioned(
                bottom: 0,
                left: sStartX,
                child: Text(
                  DateFormat.Hm().format(realStart),
                  style: const TextStyle(fontSize: 12, color: AppColors.accentColor),
                ),
              ),
              // etiqueta fin sueño real (10:00)
              Positioned(
                bottom: 0,
                right: realEndRight,
                child: Text(
                  DateFormat.Hm().format(realEnd),
                  style: const TextStyle(fontSize: 12, color: AppColors.accentColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
