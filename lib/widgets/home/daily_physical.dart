import 'package:flutter/material.dart';
import '../../screens/estado_fisico/estado_fisico_page.dart';
import '../../utils/colors.dart';

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
                child: const Icon(Icons.accessibility_new, color: AppColors.mutedAdvertencia, size: 18),
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
                        builder: (context) => const EstadoFisicoPage(),
                      ),
                    ).then((_) {
                      DefaultTabController.of(context)?.animateTo(0); // Open "Recuperación" tab
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.local_hospital, color: AppColors.textColor, size: 18), // Pharmacy cross icon
                  label: const Text("Recuperación", style: TextStyle(color: AppColors.textColor)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DefaultTabController(
                          length: 3,
                          initialIndex: 2, // Set initial index to "Medidas" tab
                          child: const EstadoFisicoPage(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.straighten, color: AppColors.textColor, size: 18), // Measurement icon
                  label: const Text("Medidas", style: TextStyle(color: AppColors.textColor)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
