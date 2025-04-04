import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../../models/entrenamiento/entrenamiento.dart';

class ResumenPastilla extends StatelessWidget {
  final Entrenamiento entrenamiento;

  const ResumenPastilla({Key? key, required this.entrenamiento}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Constantes para estilo y espaciado
    const double iconSize = 28;
    const double textSize = 16;
    const double sectionSpacing = 20;
    const double itemSpacing = 12;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInfoItem(
                icon: Icons.timer,
                value: '${entrenamiento.duracion} min',
                iconSize: iconSize,
                textSize: textSize,
              ),
              _buildInfoItem(
                icon: Icons.emoji_emotions,
                value: 'Ligero',
                iconSize: iconSize,
                textSize: textSize,
              ),
              _buildInfoItem(
                icon: Icons.local_fire_department,
                value: entrenamiento.calcularKcal().toString(),
                iconSize: iconSize,
                textSize: textSize,
              ),
            ],
          ),
          Divider(
            height: sectionSpacing,
            thickness: 1,
            color: AppColors.advertencia,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                label: 'ejercicios',
                value: '${entrenamiento.countEjerciciosWithUnlessOneSerieRealizada()}',
                textSize: textSize,
              ),
              _buildStatItem(
                label: 'series',
                value: '${entrenamiento.countSeriesRealizadas()}',
                textSize: textSize,
              ),
              _buildStatItem(
                label: 'repeticiones',
                value: '${entrenamiento.countRepeticionesRealizadas()}',
                textSize: textSize,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required double iconSize,
    required double textSize,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: AppColors.advertencia,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required double textSize,
  }) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.advertencia,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: textSize,
              fontWeight: FontWeight.w600,
              color: AppColors.cardBackground,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: textSize - 3,
            // fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
