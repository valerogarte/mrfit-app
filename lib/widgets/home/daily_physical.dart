import 'package:flutter/material.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/screens/estado_fisico/recuperacion/recuperacion_page.dart';
import 'package:mrfit/screens/estado_fisico/peso/medidas_page.dart';
import 'package:mrfit/utils/colors.dart';

Widget dailyPhysicalWidget({required Usuario usuario}) {
  return Builder(
    builder: (context) => Container(
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
                child: const Icon(Icons.accessibility_new, color: AppColors.accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                "Condición física",
                style: TextStyle(
                  color: AppColors.textMedium,
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
              // Botón para acceder a la página de recuperación física (siempre visible)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecuperacionPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.local_hospital, color: AppColors.textMedium, size: 18),
                  label: const Text(
                    "Recuperación",
                    style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (usuario.isHealthConnectAvailable == true) ...[
                const SizedBox(width: 10),
                // Botón para acceder a la página de medidas físicas (solo si isHealthAvaliable)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MedidasPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.straighten, color: AppColors.textMedium, size: 18),
                    label: const Text(
                      "Medidas",
                      style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
