import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

// Se modificó la función para aceptar day y usuario y definir valores demo.
Widget dailyVitalsWidget({required DateTime day, required dynamic usuario}) {
  // Valores demo
  int spo2 = 98;
  int stress = 20;
  double vo2Max = 35.5;
  int stairsClimbed = 12;

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.appBarBackground.withAlpha(75),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nueva cabecera con ícono similar a dailyHearthWidget
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.background,
              child: const Icon(Icons.monitor_heart, color: AppColors.textColor, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              "Vital Signs",
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // SpO2
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("SpO2:", style: TextStyle(fontSize: 16, color: AppColors.textColor)),
            Text("$spo2%", style: const TextStyle(fontSize: 16, color: AppColors.advertencia, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        // Estrés
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Estrés:", style: TextStyle(fontSize: 16, color: AppColors.textColor)),
            Text("$stress%", style: const TextStyle(fontSize: 16, color: AppColors.advertencia, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        // VO2 máx
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("VO2 máx:", style: TextStyle(fontSize: 16, color: AppColors.textColor)),
            Text("$vo2Max ml/kg/min", style: const TextStyle(fontSize: 16, color: AppColors.advertencia, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        // Escaleras subidas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Escaleras subidas:", style: TextStyle(fontSize: 16, color: AppColors.textColor)),
            Text("$stairsClimbed", style: const TextStyle(fontSize: 16, color: AppColors.advertencia, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}
