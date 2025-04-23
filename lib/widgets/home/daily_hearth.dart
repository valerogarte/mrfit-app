import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

Widget dailyHearthWidget({required int heartRate}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
              child: const Icon(Icons.favorite, color: AppColors.mutedAdvertencia, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              "Frecuencia cardíaca",
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "$heartRate bpm",
              style: const TextStyle(
                color: AppColors.mutedAdvertencia,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
