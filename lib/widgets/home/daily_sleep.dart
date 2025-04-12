import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/usuario/usuario.dart';
import '../../utils/colors.dart';
import '../../utils/usage_stats_helper.dart'; // Contendrá los métodos hasUsageStatsPermission(), openUsageStatsSettings() y getInactivitySlots()

/// Representa un slot de inactividad
class SleepSlot {
  DateTime start; // Removed 'final' to make it mutable
  DateTime end;
  int duration;

  SleepSlot({
    required this.start,
    required this.end,
    required this.duration,
  });

  factory SleepSlot.fromMap(Map<dynamic, dynamic> map) {
    final DateTime s = DateTime.fromMillisecondsSinceEpoch(map['start'] ?? 0);
    final DateTime e = DateTime.fromMillisecondsSinceEpoch(map['end'] ?? 0);
    final int dur = e.difference(s).inMinutes;
    return SleepSlot(start: s, end: e, duration: dur);
  }

  @override
  String toString() {
    return 'SleepSlot(start: $start, end: $end, duration: $duration)';
  }
}

/// Agrupa la información de sueño/inactividad
class Sleep {
  List<SleepSlot> slots;
  final DateTime selectedDate;
  List<SleepSlot>? sleepSlot;
  Sleep({
    required this.slots,
    required this.selectedDate,
    this.sleepSlot,
  });

  List<SleepSlot> getSleepSlot() {
    if (sleepSlot != null) {
      return sleepSlot!;
    }
    final DateTime horaInicioDormirHabitual = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 0, 0, 0);
    final DateTime horaFinDormirHabitual = horaInicioDormirHabitual.add(const Duration(hours: 11));

    // Filtro aquellos que estén se inicien entre horaInicioDormirHabitual y horaFinDormirHabitual
    List<SleepSlot> sleepTodaySlot = slots.where((slot) => slot.start.isAfter(horaInicioDormirHabitual) || slot.start.isAtSameMomentAs(horaInicioDormirHabitual)).where((slot) => slot.start.isBefore(horaFinDormirHabitual)).toList();
    sleepTodaySlot.sort((a, b) => b.duration.compareTo(a.duration));
    if (sleepTodaySlot.isNotEmpty) {
      sleepTodaySlot = [sleepTodaySlot.first];
    }

    if (sleepTodaySlot.first.start == horaInicioDormirHabitual) {
      final sleepYesterdaySlot = slots.where((slot) => slot.start.isAfter(horaInicioDormirHabitual.subtract(const Duration(days: 1))) && slot.start.isBefore(horaInicioDormirHabitual)).toList();
      if (sleepYesterdaySlot.isNotEmpty) {
        sleepTodaySlot.first.start = sleepYesterdaySlot.last.start;
        sleepTodaySlot.first.duration = sleepTodaySlot.first.duration + sleepYesterdaySlot.last.duration;
      }
    }

    // Ordenar los slots de sueño por hora de inicio
    if (sleepTodaySlot.isNotEmpty) {
      sleepTodaySlot.sort((a, b) => a.start.compareTo(b.start));
      sleepSlot = sleepTodaySlot;
    }
    return sleepTodaySlot;
  }

  // getTotalSleepMinutes
  int getTotalSleepMinutes() {
    var sleepSlots = getSleepSlot();
    final totalSleepHours = sleepSlots.fold(0, (sum, slot) => sum + slot.duration);
    return totalSleepHours;
  }
}

/// Función para cargar la información de sueño para un día
Future<Sleep> _loadSleepData(Usuario usuario, DateTime day) async {
  final String formattedDay = day.toIso8601String().split('T').first;

  // Obtenemos los slots de inactividad
  List<dynamic> slotsData = await UsageStatsHelper.getInactivitySlots(formattedDay);
  List<SleepSlot> inactivitySlots = slotsData.map((s) => SleepSlot.fromMap(s)).toList();

  return Sleep(slots: inactivitySlots, selectedDate: day);
}

/// Widget principal de estadísticas de sueño
Widget sleepStatsWidget({required DateTime day, required Usuario usuario}) {
  return FutureBuilder<bool>(
    key: ValueKey(day),
    future: UsageStatsHelper.hasUsageStatsPermission(),
    builder: (context, permissionSnapshot) {
      if (!permissionSnapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!permissionSnapshot.data!) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.appBarBackground.withAlpha(75),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.background,
                    child: const Icon(Icons.bedtime, color: AppColors.mutedAdvertencia, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sueño',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: const Text(
                  'Estimamos tus horas de sueño basándonos en el uso del dispositivo.',
                  style: TextStyle(color: AppColors.textColor),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: ElevatedButton.icon(
                  onPressed: () {
                    UsageStatsHelper.openUsageStatsSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                  ),
                  icon: const Icon(Icons.settings, color: AppColors.advertencia),
                  label: const Text(
                    'Conceder permisos',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.appBarBackground.withAlpha(75),
            borderRadius: BorderRadius.circular(30),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: FutureBuilder<Sleep>(
              future: _loadSleepData(usuario, day),
              builder: (context, snapshot) {
                Widget content;
                if (snapshot.connectionState != ConnectionState.done) {
                  content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.background,
                            child: const Icon(Icons.bedtime, color: AppColors.mutedAdvertencia, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "0h 0m",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  content = const SizedBox(key: ValueKey('error'));
                } else {
                  final sleepData = snapshot.data!;
                  final sleepSlot = sleepData.getSleepSlot();
                  content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.background,
                            child: const Icon(Icons.bedtime, color: AppColors.mutedAdvertencia, size: 18),
                          ),
                          const SizedBox(width: 12),
                          // Se anima desde 0 hasta la suma de las duraciones de todos los slots
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: sleepData.getTotalSleepMinutes().toDouble(),
                            ),
                            duration: const Duration(seconds: 1),
                            builder: (context, totalValue, child) {
                              final int total = totalValue.round();
                              final int hours = total ~/ 60;
                              final int minutes = total % 60;

                              if (sleepSlot.isEmpty) {
                                return Text(
                                  '${hours}h ${minutes}m',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                );
                              }

                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: (sleepSlot.first.start.hour * 60 + sleepSlot.first.start.minute).toDouble(),
                                ),
                                duration: const Duration(seconds: 1),
                                builder: (context, startValue, child) {
                                  final int sHour = (startValue ~/ 60).toInt();
                                  final int sMin = (startValue % 60).toInt();

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(
                                      begin: 0,
                                      end: (sleepSlot.first.end.hour * 60 + sleepSlot.first.end.minute).toDouble(),
                                    ),
                                    duration: const Duration(seconds: 1),
                                    builder: (context, endValue, child) {
                                      final int eHour = (endValue ~/ 60).toInt();
                                      final int eMin = (endValue % 60).toInt();

                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${hours}h ${minutes}m',
                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$sHour:${sMin.toString().padLeft(2, '0')} - $eHour:${eMin.toString().padLeft(2, '0')}',
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return content;
              },
            ),
          ),
        );
      }
    },
  );
}
