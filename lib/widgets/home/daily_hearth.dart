import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mrfit/widgets/chart/heart_grafica.dart';
import 'package:mrfit/models/health/health.dart';
import 'package:health/health.dart'; // Importa las clases necesarias para HealthDataPoint y NumericHealthValue

Widget dailyHearthWidget({
  required DateTime day,
  required Usuario usuario,
}) {
  return FutureBuilder<List<HealthDataPoint>>(
    future: usuario.getReadHeartRate(day),
    builder: (context, snapshot) {
      // Convierte la lista de HealthDataPoint a un Map<DateTime, double> para graficar
      final List<HealthDataPoint> heartRatePoints = snapshot.data ?? [];
      // Ordena los puntos por fecha antes de crear el Map
      heartRatePoints.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
      final Map<DateTime, double> heartRateData = {for (var dp in heartRatePoints) dp.dateFrom.toLocal(): dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toDouble() : 0.0};

      // Genera los puntos para la gráfica en orden cronológico
      final spots = heartRateData.entries.map((entry) {
        final time = entry.key.hour + entry.key.minute / 60.0;
        return FlSpot(time, entry.value);
      }).toList();

      // Cálculo dinámico de rangos para la gráfica
      Widget content;
      if (spots.isNotEmpty) {
        final highest = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
        final lowest = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);

        double maxY = (highest + 20).ceilToDouble();
        maxY = (maxY % 10 == 0) ? maxY : (maxY + (10 - maxY % 10));

        double minY = (lowest - 20).floorToDouble();
        minY = (minY % 10 == 0) ? minY : (minY - (minY % 10));
        minY = minY < 0 ? 0 : minY;

        // Calcula el promedio usando el Map<DateTime, double>
        final mean = HealthUtils.getAvgByGranularity(heartRatePoints, granularity: "hour").toDouble();

        content = HeartGrafica(
          spots: spots,
          minY: minY,
          maxY: maxY,
          mean: mean,
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
