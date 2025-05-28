// daily_sleep.dart

import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:logger/logger.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/channel/channel_inactividad.dart';
import 'package:mrfit/widgets/chart/sleep_bar.dart';

Widget _bedtimeIcon() {
  return CircleAvatar(
    radius: 16,
    backgroundColor: AppColors.background,
    child: Icon(Icons.bedtime, color: AppColors.accentColor, size: 18),
  );
}

Widget dailySleepWidget({required DateTime day, required Usuario usuario}) {
  int horaLevantarse = usuario.horaFinSueno?.hour ?? 0;
  if (day.hour < horaLevantarse && day.day == DateTime.now().day) {
    return _sleepPlaceholder(usuario);
  }
  return FutureBuilder<List<SleepSlot>>(
    future: usuario.getSleepSessionByDate(day),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return _sleepPlaceholder(usuario);
      }
      if (snapshot.data != null && snapshot.data!.isNotEmpty) {
        final firstSlot = snapshot.data!.first;
        final totalMinutes = usuario.calculateTotalMinutes(snapshot.data!);
        return FutureBuilder<List<SleepSlot>>(
          future: usuario.getTypeSleepByDate(firstSlot.start, firstSlot.end),
          builder: (ctx2, typeSnap) {
            if (typeSnap.connectionState != ConnectionState.done) {
              return _sleepStats(totalMinutes, firstSlot, "HealthConnect", usuario: usuario);
            }
            final typeSlots = typeSnap.data ?? [];
            return _sleepStats(
              totalMinutes,
              firstSlot,
              "HealthConnect",
              allSlots: snapshot.data,
              typeSlots: typeSlots,
              usuario: usuario, // Pass usuario here
            );
          },
        );
      }
      // rama original de UsageStats
      return FutureBuilder<List<SleepSlot>>(
        future: usuario.getSleepSlotsForDay(day),
        builder: (context, slotSnapshot) {
          if (slotSnapshot.connectionState != ConnectionState.done) {
            return _sleepPlaceholder(usuario);
          }
          if (slotSnapshot.data == null || slotSnapshot.data!.isEmpty) {
            return _sleepPermission(context); // <-- pasa context aquí
          }

          final slots = usuario.filterAndMergeSlotsInactivity(slotSnapshot.data!, day);
          final totalMinutes = usuario.calculateTotalMinutes(slots);

          if (slots.isNotEmpty && usuario.isHealthConnectAvailable) {
            final mainSleepSlot = slots.first;
            Logger().w("Insertando sueño en HealthConnect");
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
            usuario: usuario, // Pass usuario here
          );
        },
      );
    },
  );
}

Widget _sleepPlaceholder(Usuario usuario) {
  return _sleepBase(
    mainText: '0h 0m',
    slots: [],
    usuario: usuario,
  );
}

Widget _sleepPermission(BuildContext context) {
  // Maneja la apertura de ajustes de permisos con control de errores
  Future<void> _handleOpenUsageStatsSettings() async {
    try {
      await UsageStats.openUsageStatsSettings();
    } catch (e) {
      // Informa al usuario si ocurre un error al abrir los ajustes
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
      color: AppColors.appBarBackground.withAlpha(75),
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
            onPressed: _handleOpenUsageStatsSettings,
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
  );
}

Widget _sleepBase({
  required String mainText,
  String fromWhere = '',
  required List<SleepSlot> slots,
  List<SleepSlot>? typeSlots,
  required Usuario usuario,
  double? quality, // Nuevo parámetro para calidad
}) {
  return Container(
    width: double.infinity,
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
            _bedtimeIcon(),
            const SizedBox(width: 12),
            Text(
              mainText,
              style: const TextStyle(color: AppColors.textNormal, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // Espacio flexible para empujar la calidad a la derecha
            Expanded(child: Container()),
            if (quality != null)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeIn,
                child: Row(
                  children: [
                    Icon(Icons.verified, color: AppColors.mutedAdvertencia, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${quality.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: AppColors.mutedAdvertencia,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        slots.isEmpty
            ? Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Sin sueño registrado',
                  style: TextStyle(color: AppColors.accentColor, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              )
            : SleepBar(
                realStart: slots.first.start,
                realEnd: slots.first.end,
                typeSlots: typeSlots ?? [],
                horaInicioRutina: usuario.horaInicioSueno ?? const TimeOfDay(hour: 0, minute: 0),
                horaFinRutina: usuario.horaFinSueno ?? const TimeOfDay(hour: 0, minute: 0),
              ),
      ],
    ),
  );
}
