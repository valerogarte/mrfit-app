import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class ResumenSemanalEntrenamientosWidget extends StatelessWidget {
  final int daysTrainedLast30Days;
  final int daysTrainedLast7Days;

  const ResumenSemanalEntrenamientosWidget({
    Key? key,
    required this.daysTrainedLast30Days,
    required this.daysTrainedLast7Days,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.appBarBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado y botón cerrar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Resumen semanal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textMedium,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMedium),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Primera fila: datos y icono
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$daysTrainedLast7Days/7',
                      style: const TextStyle(
                        fontSize: 40,
                        color: AppColors.accentColor,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.fitness_center,
                    color: AppColors.mutedAdvertencia,
                    size: 36,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$daysTrainedLast30Days/30',
                      style: const TextStyle(
                        fontSize: 40,
                        color: AppColors.accentColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Segunda fila: descripciones debajo de cada estadística
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Días entrenados en 7 días',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 36 + 16), // icon width + padding
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: const Text(
                      'Días entrenados en 30 días',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
