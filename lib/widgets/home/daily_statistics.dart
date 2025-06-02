import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/screens/estadisticas/medals_page.dart';

class StatisticsWidget extends StatefulWidget {
  final Usuario usuario;
  final int lookbackDays;

  const StatisticsWidget({
    super.key,
    required this.usuario,
    this.lookbackDays = 30,
  });

  @override
  State<StatisticsWidget> createState() => _StatisticsWidgetState();
}

class _StatisticsWidgetState extends State<StatisticsWidget> {
  static const double _outerRadius = 20;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_outerRadius),
      child: Container(
        width: double.infinity,
        color: AppColors.cardBackground,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono dentro de un círculo para consistencia visual
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.transparent,
                  child: const Icon(Icons.bar_chart, color: AppColors.mutedAdvertencia, size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Estadísticas",
                  style: TextStyle(
                    color: AppColors.textMedium,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MedalsPage(
                          usuario: widget.usuario, // Pass the required 'usuario' parameter
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.emoji_events, color: AppColors.textMedium, size: 18), // Trophy icon
                  label: const Text(
                    "Medallas",
                    style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
