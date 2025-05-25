import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/widgets/chart/heart_grafica.dart';
import 'package:health/health.dart';

Widget dailyHearthWidget({
  required DateTime day,
  required Usuario usuario,
}) {
  return FutureBuilder<List<HealthDataPoint>>(
    future: usuario.getReadHeartRate(day),
    builder: (context, snapshot) {
      final List<HealthDataPoint> heartRatePoints = snapshot.data ?? [];
      Widget content;

      if (heartRatePoints.isNotEmpty) {
        content = HeartGrafica(
          dataPoints: heartRatePoints,
          granularity: "hour",
        );
      } else if (snapshot.connectionState == ConnectionState.waiting) {
        content = const Center(child: CircularProgressIndicator());
      } else {
        content = const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Sin registros durante el día.",
            style: TextStyle(color: AppColors.textMedium, fontSize: 16),
          ),
        );
      }

      return Container(
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.background,
                  child: const Icon(Icons.favorite, color: AppColors.mutedRed, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Frecuencia cardíaca",
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            content,
          ],
        ),
      );
    },
  );
}
