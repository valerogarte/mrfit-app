import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class EjercicioTablaMejorMarca extends StatelessWidget {
  final Map<String, dynamic> data;

  const EjercicioTablaMejorMarca({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Table(
      children: [
        TableRow(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mutedAdvertencia),
                  ),
                  child: const Icon(Icons.fitness_center, color: AppColors.accentColor),
                ),
                const SizedBox(width: 8),
                const Text('1 RM'),
              ],
            ),
            Text(data['rm'].toStringAsFixed(1) + " kg"),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(height: 16),
            SizedBox.shrink(),
          ],
        ),
        TableRow(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mutedAdvertencia),
                  ),
                  child: const Icon(Icons.line_weight, color: AppColors.accentColor),
                ),
                const SizedBox(width: 8),
                const Text('Máx Peso'),
              ],
            ),
            Text(data['pesoMaximo'].toStringAsFixed(1) + " kg"),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(height: 16),
            SizedBox.shrink(),
          ],
        ),
        TableRow(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mutedAdvertencia),
                  ),
                  child: const Icon(Icons.repeat, color: AppColors.accentColor),
                ),
                const SizedBox(width: 8),
                const Text('Máx Repes'),
              ],
            ),
            Text("${data['maxReps']['repeticiones']} repes con " + data['maxReps']['peso'].toStringAsFixed(1) + " kg"),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(height: 16),
            SizedBox.shrink(),
          ],
        ),
        TableRow(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mutedAdvertencia),
                  ),
                  child: const Icon(Icons.bar_chart, color: AppColors.accentColor),
                ),
                const SizedBox(width: 8),
                const Text('Máx Volumen'),
              ],
            ),
            Text(data['volumenMaximo'].toStringAsFixed(1) + " kg"),
          ],
        ),
        TableRow(
          children: [
            const SizedBox(height: 16),
            SizedBox.shrink(),
          ],
        ),
        TableRow(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.mutedAdvertencia),
                  ),
                  child: const Icon(Icons.format_list_numbered, color: AppColors.accentColor),
                ),
                const SizedBox(width: 8),
                const Text('Series Completadas'),
              ],
            ),
            Text(data['seriesRealizadas'].toString()),
          ],
        ),
      ],
    );
  }
}
