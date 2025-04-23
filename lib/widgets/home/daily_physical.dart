import 'package:flutter/material.dart';
import 'package:mrfit/screens/estado_fisico/recuperacion/recuperacion_page.dart';
import 'package:mrfit/screens/estado_fisico/peso/medidas_page.dart';
import 'package:mrfit/utils/colors.dart';

Widget dailyPhysicalWidget() {
  return Builder(
    builder: (context) => Container(
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
                child: const Icon(Icons.accessibility_new, color: AppColors.accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                "Condición física",
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RecuperacionPage(), // Navigate to RecuperacionPage
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.local_hospital, color: AppColors.textColor, size: 18), // Pharmacy cross icon
                  label: const Text(
                    "Recuperación",
                    style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MedidasPage(), // Navigate to MedidasPage
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.straighten, color: AppColors.textColor, size: 18), // Measurement icon
                  label: const Text(
                    "Medidas",
                    style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
