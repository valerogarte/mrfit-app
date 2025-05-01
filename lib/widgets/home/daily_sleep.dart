import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:health/health.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/utils/usage_stats_helper.dart';

Widget dailySleepWidget({required DateTime day, required Usuario usuario}) {
  return FutureBuilder<Map<String, int>>(
    future: usuario.getSleepByDate(DateFormat('yyyy-MM-dd').format(day)),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return _sleepPlaceholder();
      }
      if (snapshot.data != null && snapshot.data!.isNotEmpty) {
        final firstEntry = snapshot.data!.entries.first;
        if (firstEntry.value > 0) {
          final totalMinutes = snapshot.data!.values.first;
          return _sleepStats(totalMinutes, null);
        }
      }
      return FutureBuilder<List<SleepSlot>>(
        future: usuario.getSleepSlotsForDay(day),
        builder: (context, slotSnapshot) {
          if (slotSnapshot.connectionState != ConnectionState.done) {
            return _sleepPlaceholder();
          }
          if (slotSnapshot.data == null || slotSnapshot.data!.isEmpty) {
            return _sleepPermission();
          }

          final slots = usuario.filterAndMergeSlots(slotSnapshot.data!, day);
          final totalMinutes = usuario.calculateTotalMinutes(slots);

          // If we have valid slots, write the sleep data to the health store
          if (slots.isNotEmpty) {
            final mainSleepSlot = slots.first;

            // Write the sleep data with SLEEP_SESSION type
            usuario.writeSleepData(
              timeInicio: mainSleepSlot.start,
              timeFin: mainSleepSlot.end,
              sleepType: HealthDataType.SLEEP_SESSION,
            );
          }

          final firstSlot = slots.isNotEmpty ? slots.first : null;
          return _sleepStats(totalMinutes, firstSlot);
        },
      );
    },
  );
}

Widget _sleepPlaceholder() {
  return _sleepBase(
    mainText: '0h 0m',
    subText: '00:00 - 00:00',
  );
}

Widget _sleepPermission() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.appBarBackground.withAlpha(75),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Column(
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
            onPressed: UsageStatsHelper.openUsageStatsSettings,
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

Widget _sleepStats(int totalMinutes, SleepSlot? slot) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  final startTime = slot != null ? DateFormat.Hm().format(slot.start) : '00:00';
  final endTime = slot != null ? DateFormat.Hm().format(slot.end) : '00:00';
  return _sleepBase(
    mainText: '${hours}h ${minutes}m',
    subText: '$startTime - $endTime',
  );
}

Widget _sleepBase({required String mainText, required String subText}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.appBarBackground.withAlpha(75),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.background,
          child: const Icon(Icons.bedtime, color: AppColors.mutedAdvertencia, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mainText,
              style: const TextStyle(color: AppColors.textNormal, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subText,
              style: const TextStyle(color: AppColors.textNormal, fontSize: 14),
            ),
          ],
        ),
      ],
    ),
  );
}
