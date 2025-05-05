import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/widgets/chart/medal_card.dart';
import 'package:mrfit/screens/estadisticas/medals_page.dart';

class StatisticsWidget extends StatefulWidget {
  final Usuario usuario;
  final int lookbackDays;

  const StatisticsWidget({
    Key? key,
    required this.usuario,
    this.lookbackDays = 30,
  }) : super(key: key);

  @override
  State<StatisticsWidget> createState() => _StatisticsWidgetState();
}

class _StatisticsWidgetState extends State<StatisticsWidget> {
  static const double _outerRadius = 20;
  static const double _aspectRatio = 0.75;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_outerRadius),
      child: Container(
        width: double.infinity,
        color: AppColors.appBarBackground.withAlpha(75),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.bar_chart, color: AppColors.mutedAdvertencia),
                SizedBox(width: 8),
                Text(
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
          ],
        ),
      ),
    );
  }
}
