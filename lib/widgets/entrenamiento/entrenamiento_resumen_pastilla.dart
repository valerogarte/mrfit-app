import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:intl/intl.dart'; // Para formatear números con separador de miles

class ResumenPastilla extends StatelessWidget {
  final Entrenamiento? entrenamiento;
  final int? steps;
  final int? distance; // metros
  final int? heartRateAvg;

  const ResumenPastilla({
    Key? key,
    this.entrenamiento,
    this.steps,
    this.distance,
    this.heartRateAvg,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Constantes para estilo y espaciado
    const double iconSize = 28;
    const double textSize = 16;
    const double sectionSpacing = 20;
    const double itemSpacing = 12;

    // Obtiene el promedio solo si hay entrenamiento
    final avgEntrenamiento = entrenamiento?.getRerAvg();

    final bool showFirstRow = entrenamiento != null;
    final bool showSecondRow = entrenamiento != null;
    // Solo mostrar la fila extra si alguno de los valores es mayor a 0
    final bool showExtraRow = (steps != null && steps! > 0) || (distance != null && distance! > 0) || (heartRateAvg != null && heartRateAvg! > 0);

    final NumberFormat milesFormat = NumberFormat('#,##0', 'es_ES');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
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
          // Primera fila (datos de entrenamiento)
          if (showFirstRow)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: _buildInfoItem(
                    icon: Icons.timer,
                    value: '${entrenamiento!.duracion}',
                    unit: 'min',
                    iconSize: iconSize,
                    textSize: textSize,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _buildInfoItem(
                    icon: Icons.emoji_emotions,
                    value: avgEntrenamiento?['label'] ?? '',
                    unit: 'sensación',
                    iconColor: avgEntrenamiento?['iconColor'],
                    iconSize: iconSize,
                    textSize: textSize,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _buildInfoItem(
                    icon: Icons.local_fire_department,
                    value: entrenamiento!.kcalConsumidas.toString(),
                    unit: 'kcal',
                    iconSize: iconSize,
                    textSize: textSize,
                  ),
                ),
              ],
            ),
          // Espaciador y divisor entre primera y extra row si ambas existen
          if (showFirstRow && showExtraRow) ...[
            const SizedBox(height: 4),
            const _ResumenDivider(),
            const SizedBox(height: 4),
          ],
          // Fila extra (steps, distance, heartRateAvg)
          if (showExtraRow)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: steps != null
                      ? _buildInfoItem(
                          icon: Icons.directions_walk,
                          value: milesFormat.format(steps),
                          unit: 'pasos',
                          iconSize: iconSize,
                          textSize: textSize,
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  flex: 1,
                  child: heartRateAvg != null
                      ? _buildInfoItem(
                          icon: Icons.favorite,
                          value: '$heartRateAvg',
                          unit: 'ppm',
                          iconSize: iconSize,
                          textSize: textSize,
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  flex: 1,
                  child: distance != null
                      ? _buildInfoItem(
                          icon: Icons.flag,
                          value: milesFormat.format(distance),
                          unit: 'metros',
                          iconSize: iconSize,
                          textSize: textSize,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          // Espaciador y divisor entre extra row y segunda row si ambas existen
          if (showExtraRow && showSecondRow) ...[
            const SizedBox(height: 4),
            const _ResumenDivider(),
            const SizedBox(height: 4),
          ],
          // Si no hay extra row pero hay ambas filas, divisor entre primera y segunda fila
          if (!showExtraRow && showFirstRow && showSecondRow) ...[
            const SizedBox(height: 4),
            const _ResumenDivider(),
            const SizedBox(height: 4),
          ],
          // Segunda fila (estadísticas de entrenamiento)
          if (showSecondRow)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  flex: 1,
                  child: _buildStatItem(
                    label: 'ejercicios',
                    value: milesFormat.format(entrenamiento!.countEjerciciosWithUnlessOneSerieRealizada()),
                    textSize: textSize,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _buildStatItem(
                    label: 'series',
                    value: milesFormat.format(entrenamiento!.countSeriesRealizadas()),
                    textSize: textSize,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: _buildStatItem(
                    label: 'repeticiones',
                    value: milesFormat.format(entrenamiento!.countRepeticionesRealizadas()),
                    textSize: textSize,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Construye un ítem de información con icono, valor y unidad opcional.
  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required double iconSize,
    required double textSize,
    String? unit,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: iconColor ?? AppColors.mutedAdvertencia,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (unit != null)
          Text(
            unit,
            style: TextStyle(
              fontSize: textSize - 4,
              color: AppColors.textMedium.withAlpha(150),
            ),
          ),
      ],
    );
  }

  /// Construye un ítem de estadística con etiqueta y valor destacado.
  Widget _buildStatItem({
    required String label,
    required String value,
    required double textSize,
  }) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.mutedAdvertencia,
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
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: textSize - 3,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

/// Widget reutilizable para la línea divisoria con extremos transparentes y gradiente.
class _ResumenDivider extends StatelessWidget {
  const _ResumenDivider();

  @override
  Widget build(BuildContext context) {
    // Usa el mismo espaciado que el widget principal
    const double sectionSpacing = 20;
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(vertical: sectionSpacing / 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.mutedAdvertencia,
            AppColors.mutedAdvertencia,
            AppColors.mutedAdvertencia,
            AppColors.mutedAdvertencia,
            AppColors.mutedAdvertencia,
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}
