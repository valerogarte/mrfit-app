import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/channel/channel_inactividad.dart';
import 'package:mrfit/widgets/chart/sleep_bar.dart';
import 'package:mrfit/widgets/common/cached_future_builder.dart';

Widget _bedtimeIcon() {
  return CircleAvatar(
    radius: 16,
    backgroundColor: AppColors.background,
    child: Icon(Icons.bedtime, color: AppColors.accentColor, size: 18),
  );
}

Widget dailySleepWidget({
  required DateTime day,
  required Usuario usuario,
  int refreshKey = 0,
}) {
  int horaLevantarse = usuario.horaFinSueno?.hour ?? 0;
  if (day.hour < horaLevantarse && day.day == DateTime.now().day) {
    return _sleepPlaceholder(usuario, day);
  }
  return CachedFutureBuilder<List<SleepSlot>>(
    key: const ValueKey('sleep_session'),
    futureBuilder: () => usuario.getSleepSessionByDate(day),
    keys: [day, usuario.id, refreshKey],
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return _sleepPlaceholder(usuario, day);
      }
      if (snapshot.data != null && snapshot.data!.isNotEmpty) {
        final firstSlot = snapshot.data!.first;
        final totalMinutes = usuario.calculateTotalMinutes(snapshot.data!);
        return CachedFutureBuilder<List<SleepSlot>>(
          key: const ValueKey('sleep_type'),
          futureBuilder: () =>
              usuario.getTypeSleepByDate(firstSlot.start, firstSlot.end),
          keys: [firstSlot.start, firstSlot.end, usuario.id, refreshKey],
          builder: (ctx2, typeSnap) {
            if (typeSnap.connectionState != ConnectionState.done) {
              return _sleepStats(totalMinutes, firstSlot, "HealthConnect", usuario: usuario, day: day);
            }
            final typeSlots = typeSnap.data ?? [];
            return _sleepStats(
              totalMinutes,
              firstSlot,
              "HealthConnect",
              allSlots: snapshot.data,
              typeSlots: typeSlots,
              usuario: usuario, // Pass usuario here
              day: day,
            );
          },
        );
      }
      // rama original de UsageStats
      return CachedFutureBuilder<List<SleepSlot>>(
        key: const ValueKey('sleep_slots'),
        futureBuilder: () => usuario.getSleepSlotsForDay(day),
        keys: [day, usuario.id, refreshKey],
        builder: (context, slotSnapshot) {
          if (slotSnapshot.connectionState != ConnectionState.done) {
            return _sleepPlaceholder(usuario, day);
          }
          if (slotSnapshot.data == null || slotSnapshot.data!.isEmpty) {
            return _sleepPermission(context);
          }

          final slots = usuario.filterAndMergeSlotsInactivity(slotSnapshot.data!, day);
          final totalMinutes = usuario.calculateTotalMinutes(slots);

          // Si el tiempo total supera 24h, mostrar sin registros
          if (totalMinutes > 1440) {
            return _sleepPlaceholder(usuario, day);
          }

          if (slots.isNotEmpty && usuario.isHealthConnectAvailable) {
            final mainSleepSlot = slots.first;
            usuario.writeSleepData(
              timeInicio: mainSleepSlot.start,
              timeFin: mainSleepSlot.end,
              sleepType: HealthDataType.SLEEP_SESSION,
            );
          }
          final firstSlot = slots.isNotEmpty ? slots.first : null;
          return _sleepStats(
            totalMinutes,
            firstSlot,
            "UsageStats",
            allSlots: slots,
            usuario: usuario,
            day: day,
          );
        },
      );
    },
  );
}

Widget _sleepPlaceholder(Usuario usuario, DateTime day) {
  return _sleepBase(
    mainText: '0h 0m',
    slots: [],
    usuario: usuario,
    day: day,
  );
}

Widget _sleepPermission(BuildContext context) {
  // Maneja la apertura de ajustes de permisos con control de errores
  Future<void> handleOpenUsageStatsSettings() async {
    try {
      await UsageStats.openUsageStatsSettings();
    } catch (e) {
      // Informa al usuario si ocurre un error al abrir los ajustes
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir los ajustes de permisos.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _bedtimeIcon(),
            const SizedBox(width: 12),
            const Text(
              'Sueño',
              style: TextStyle(color: AppColors.textNormal, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Activa permisos para estimar tu sueño.'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 0),
          child: ElevatedButton.icon(
            onPressed: handleOpenUsageStatsSettings,
            icon: const Icon(Icons.settings, color: AppColors.background),
            label: const Text(
              'Permisos',
              style: TextStyle(color: AppColors.background),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedAdvertencia,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _sleepStats(
  int totalMinutes,
  SleepSlot? slot,
  String fromWhere, {
  List<SleepSlot>? allSlots,
  List<SleepSlot>? typeSlots, // NUEVO parámetro
  required Usuario usuario, // Add usuario parameter
  required DateTime day,
}) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  // Calcular calidad del sueño usando typeSlots si están disponibles
  double? quality;
  if ((typeSlots ?? []).isNotEmpty) {
    quality = usuario.getQualitySleep(typeSlots!);
    if (quality == 0) {
      quality = null;
    }
  }

  return _sleepBase(
    mainText: '${hours}h ${minutes}m',
    fromWhere: fromWhere,
    slots: allSlots ?? [],
    typeSlots: typeSlots ?? [],
    usuario: usuario,
    quality: quality,
    day: day,
  );
}

Widget _sleepBase({
  required String mainText,
  String fromWhere = '',
  required List<SleepSlot> slots,
  List<SleepSlot>? typeSlots,
  required Usuario usuario,
  double? quality,
  DateTime? day,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _bedtimeIcon(),
            const SizedBox(width: 12),
            Text(
              mainText,
              style: const TextStyle(color: AppColors.textNormal, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // Espacio flexible para empujar la calidad a la derecha
            Expanded(child: Container()),
            // if (quality != null)
            // AnimatedOpacity(
            //   opacity: 1.0,
            //   duration: const Duration(milliseconds: 600),
            //   curve: Curves.easeIn,
            //   child: Row(
            //     children: [
            //       Icon(Icons.verified, color: AppColors.mutedAdvertencia, size: 18),
            //       const SizedBox(width: 4),
            //       Text(
            //         '${quality.toStringAsFixed(1)}%',
            //         style: const TextStyle(
            //           color: AppColors.mutedAdvertencia,
            //           fontSize: 15,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 12),
        SleepBar(
          realStart: slots.isNotEmpty
              ? slots.first.start
              : DateTime(
                  (day ?? DateTime.now()).year,
                  (day ?? DateTime.now()).month,
                  (day ?? DateTime.now()).day,
                  (usuario.horaInicioSueno ?? const TimeOfDay(hour: 0, minute: 0)).hour,
                  (usuario.horaInicioSueno ?? const TimeOfDay(hour: 0, minute: 0)).minute,
                ),
          realEnd: slots.isNotEmpty
              ? slots.first.end
              : DateTime(
                  (day ?? DateTime.now()).year,
                  (day ?? DateTime.now()).month,
                  (day ?? DateTime.now()).day,
                  (usuario.horaInicioSueno ?? const TimeOfDay(hour: 0, minute: 0)).hour,
                  (usuario.horaInicioSueno ?? const TimeOfDay(hour: 0, minute: 0)).minute,
                ),
          typeSlots: typeSlots ?? [],
          horaInicioRutina: usuario.horaInicioSueno ?? const TimeOfDay(hour: 0, minute: 0),
          horaFinRutina: usuario.horaFinSueno ?? const TimeOfDay(hour: 0, minute: 0),
          showSessionLabels: slots.isNotEmpty,
        ),
      ],
    ),
  );
}
