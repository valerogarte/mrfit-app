import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/utils/usage_stats_helper.dart';

/// Representa un slot de inactividad
class SleepSlot {
  final int start; // en minutos, relativo al inicio de la ventana (p.ej. desde las 22:00)
  final int end; // en minutos, relativo a la ventana
  final int duration; // duración en minutos

  SleepSlot({
    required this.start,
    required this.end,
    required this.duration,
  });

  factory SleepSlot.fromMap(Map<dynamic, dynamic> map) {
    return SleepSlot(
      start: map['start'] ?? 0,
      end: map['end'] ?? 0,
      duration: map['duration'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'SleepSlot(start: $start, end: $end, duration: $duration)';
  }
}

/// Agrupa la información de sueño/inactividad
class Sleep {
  final int totalSleepMinutes; // Suma de los datos de Health y de inactividad
  final List<SleepSlot> slots;
  Sleep({
    required this.totalSleepMinutes,
    required this.slots,
  });
}

/// Función para cargar la información de sueño para un día
Future<Sleep> _loadSleepData(Usuario usuario, DateTime day) async {
  // Formateamos la fecha al estilo "yyyy-MM-dd"
  final String formattedDay = day.toIso8601String().split('T').first;
  final parsedDate = DateTime.parse(formattedDay);

  // Obtenemos los minutos de sueño registrados vía Health/HealthConnect
  final Map<DateTime, int> sleepMap = await usuario.getSleepByDate(formattedDay);
  final int healthSleepMinutes = sleepMap[parsedDate] ?? 0;

  // Obtenemos los slots de inactividad (períodos de uso reducido)
  final List<dynamic> slotsData = await UsageStatsHelper.getInactivitySlots(formattedDay);
  final List<SleepSlot> inactivitySlots = slotsData.map((s) => SleepSlot.fromMap(s)).toList();

  // Sumamos los minutos de inactividad
  final int inactivityMinutes = inactivitySlots.fold(0, (sum, slot) => sum + slot.duration);
  final int totalSleep = healthSleepMinutes + inactivityMinutes;
  return Sleep(totalSleepMinutes: totalSleep, slots: inactivitySlots);
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
        // No tiene permisos: mostramos mensaje y CTA
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
                    backgroundColor: AppColors.background, // Cambiado a background
                    child: const Icon(Icons.bedtime, color: AppColors.mutedAdvertencia, size: 18), // Cambiado a mutedAdvertencia
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Sueño',
                    style: TextStyle(
                      color: AppColors.textNormal,
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
                  style: TextStyle(color: AppColors.textMedium),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Llama al método que redirige a los ajustes de UsageStats
                    UsageStatsHelper.openUsageStatsSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background, // Fondo cambiado a background
                  ),
                  icon: const Icon(Icons.settings, color: AppColors.mutedAdvertencia), // Icono cambiado a advertencia
                  label: const Text(
                    'Conceder permisos',
                    style: TextStyle(color: AppColors.textNormal),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Tiene permisos: cargamos la data de sueño/inactividad
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
                            backgroundColor: AppColors.background, // Cambiado a background
                            child: const Icon(Icons.bedtime, color: AppColors.mutedAdvertencia, size: 18), // Cambiado a mutedAdvertencia
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "0 min",
                            style: TextStyle(color: AppColors.textNormal, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildSleepBar([]),
                    ],
                  );
                } else if (snapshot.hasError) {
                  content = const SizedBox(key: ValueKey('error'));
                } else {
                  final sleepData = snapshot.data!;
                  content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.background, // Cambiado a background
                            child: const Icon(Icons.bedtime, color: AppColors.mutedAdvertencia, size: 18), // Cambiado a mutedAdvertencia
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${sleepData.totalSleepMinutes} min',
                            style: const TextStyle(color: AppColors.textNormal, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildSleepBar(sleepData.slots),
                      const SizedBox(height: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: sleepData.slots.map((slot) {
                          final startHour = (slot.start ~/ 60).toString().padLeft(2, '0');
                          final startMinute = (slot.start % 60).toString().padLeft(2, '0');
                          final endHour = (slot.end ~/ 60).toString().padLeft(2, '0');
                          final endMinute = (slot.end % 60).toString().padLeft(2, '0');
                          return Text(
                            'De $startHour:$startMinute a $endHour:$endMinute',
                            style: const TextStyle(color: AppColors.textNormal, fontSize: 14),
                          );
                        }).toList(),
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

/// Esta función construye la barra horizontal en la que se pintan los slots de inactividad
/// [slots]: lista de periodos de inactividad (en minutos relativos a la ventana).
Widget _buildSleepBar(List<SleepSlot> slots) {
  // Calcula la ventana en minutos (24 horas = 1440 minutos)
  const int windowMinutes = 24 * 60;

  // Cojo el slot más largo de inactividad entre las 00:00 y las 12:00
  final int maxStart = slots.where((slot) => slot.start >= 0 && slot.end <= 12 * 60).map((slot) => slot.start).reduce((a, b) => a > b ? a : b);

  return LayoutBuilder(
    builder: (context, constraints) {
      final double totalWidth = constraints.maxWidth;
      return SizedBox(
        width: totalWidth,
        height: 20,
        child: Stack(
          children: slots.where((slot) => slot.end <= windowMinutes).map((slot) {
            // Calcular posición y ancho en píxeles basados en el contenedor real
            final double left = totalWidth * (slot.start / windowMinutes);
            final double width = totalWidth * ((slot.end - slot.start) / windowMinutes);
            return Positioned(
              left: left,
              child: Container(
                width: width,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.mutedAdvertencia,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }).toList(),
        ),
      );
    },
  );
}
