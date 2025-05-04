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
  // Si la hora es anterior a las 6 de la mañana, no se muestra nada
  if (day.hour < 6 && day.day == DateTime.now().day) {
    return _sleepPlaceholder();
  }
  return FutureBuilder<List<SleepSlot>>(
    future: usuario.getSleepSessionByDate(day),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return _sleepPlaceholder();
      }
      if (snapshot.data != null && snapshot.data!.isNotEmpty) {
        final firstSlot = snapshot.data!.first;
        final totalMinutes = usuario.calculateTotalMinutes(snapshot.data!);
        // NUEVO: llamamos a getTypeSleepByDate para obtener los slots tipados
        return FutureBuilder<List<SleepSlot>>(
          future: usuario.getTypeSleepByDate(firstSlot.start, firstSlot.end),
          builder: (ctx2, typeSnap) {
            if (typeSnap.connectionState != ConnectionState.done) {
              return _sleepStats(totalMinutes, firstSlot, "HealthConnect");
            }
            final typeSlots = typeSnap.data ?? [];
            return _sleepStats(
              totalMinutes,
              firstSlot,
              "HealthConnect",
              allSlots: snapshot.data,
              typeSlots: typeSlots,
            );
          },
        );
      }
      // rama original de UsageStats
      return FutureBuilder<List<SleepSlot>>(
        future: usuario.getSleepSlotsForDay(day),
        builder: (context, slotSnapshot) {
          if (slotSnapshot.connectionState != ConnectionState.done) {
            return _sleepPlaceholder();
          }
          if (slotSnapshot.data == null || slotSnapshot.data!.isEmpty) {
            return _sleepPermission();
          }

          final slots = usuario.filterAndMergeSlotsInactivity(slotSnapshot.data!, day);
          final totalMinutes = usuario.calculateTotalMinutes(slots);

          if (slots.isNotEmpty) {
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
          );
        },
      );
    },
  );
}

Widget _sleepPlaceholder() {
  return _sleepBase(
    mainText: '0h 0m',
    slots: [],
  );
}

Widget _sleepPermission() {
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
            onPressed: UsageStats.openUsageStatsSettings,
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
}) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return _sleepBase(
    mainText: '${hours}h ${minutes}m',
    fromWhere: fromWhere,
    slots: allSlots ?? [],
    typeSlots: typeSlots ?? [], // lo pasamos al base
  );
}

Widget _sleepBase({
  required String mainText,
  String fromWhere = '',
  required List<SleepSlot> slots,
  List<SleepSlot>? typeSlots, // NUEVO
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
              ),
      ],
    ),
  );
}
