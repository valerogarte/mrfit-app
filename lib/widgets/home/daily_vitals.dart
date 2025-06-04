import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/widgets/common/cached_future_builder.dart';

Widget dailyVitalsWidget({
  required DateTime day,
  required Usuario usuario,
  int refreshKey = 0,
}) {
  return CachedFutureBuilder<List<dynamic>>(
    key: const ValueKey('daily_vitals'),
    futureBuilder: () => Future.wait([
      usuario.getDailySpo2(day),
      usuario.getDailyStress(day),
      usuario.getDailyStairsClimbed(day),
    ]),
    keys: [day, usuario.id, refreshKey],
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      final spo2 = snap.data![0] as int;
      // final stress = snap.data![1] as int;
      final stairs = snap.data![2] as int;

      return Container(
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.appBarBackground,
                  child: const Icon(
                    Icons.monitor_heart,
                    color: AppColors.mutedGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Constantes Vitales",
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildRow("SpO₂:", "$spo2%"),
            // const SizedBox(height: 8),
            // _buildRow("Estrés:", "$stress%"),
            const SizedBox(height: 8),
            _buildRow("Escaleras subidas:", "$stairs"),
          ],
        ),
      );
    },
  );
}

Widget _buildRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 16, color: AppColors.textMedium)),
      Text(value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.mutedGreen,
            fontWeight: FontWeight.bold,
          )),
    ],
  );
}
