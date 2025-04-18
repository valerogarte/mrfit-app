import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../../screens/planes/planes.dart';
import '../../models/usuario/usuario.dart';
import '../../utils/colors.dart';
import '../chart/triple_ring_loader.dart';
import '../../models/modelo_datos.dart';

Widget dailyTrainingsWidget({required DateTime day, required Usuario usuario}) {
  String selectedDay = day.toIso8601String().split('T').first;
  return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
    future: usuario.getDailyTrainingsByDate(selectedDay),
    builder: (context, snapshot) {
      Widget content;
      if (snapshot.connectionState != ConnectionState.done) {
        content = _buildStatsContainer(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.mutedAdvertencia,
                  child: const Icon(Icons.fitness_center, color: AppColors.background, size: 18),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: const Text(
                    "Cargando entrenamientos",
                    style: TextStyle(color: AppColors.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Add logic for "Entrenar" button
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Entrenar", style: TextStyle(color: AppColors.mutedAdvertencia)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Add logic for "Rutinas" button
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Rutinas", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
          loader: Container(),
          key: const ValueKey('loading_tr'),
        );
      } else if (snapshot.hasError) {
        content = const SizedBox(key: ValueKey('error_tr'));
      } else {
        final trainingsMap = snapshot.data!;
        final trainings = trainingsMap[selectedDay] ?? [];
        if (trainings.isEmpty) {
          content = _buildStatsContainer(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.mutedAdvertencia,
                    child: const Icon(Icons.fitness_center, color: AppColors.background, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: const Text(
                      "Sin entrenamientos",
                      style: TextStyle(color: AppColors.textColor, fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Add logic for "Entrenar" button
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Entrenar", style: TextStyle(color: AppColors.mutedAdvertencia)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Add logic for "Rutinas" button
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Rutinas", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
            loader: Container(),
            key: const ValueKey('no_exercises'),
          );
        } else {
          final typesActivitys = ModeloDatos().getActivityTypeDetails;
          content = _buildStatsContainer(
            children: [
              Column(
                children: [
                  Column(
                    children: trainings.map<Widget>((exercise) {
                      final activityDetails = typesActivitys(exercise['activityType'].toString());
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.mutedAdvertencia,
                                  child: Icon(activityDetails["icon"], color: AppColors.background, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  activityDetails["nombre"],
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            Text(
                              "${exercise['duration']} min",
                              style: const TextStyle(color: Colors.white70, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Add logic for "Entrenar" button
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text("Entrenar", style: TextStyle(color: AppColors.mutedAdvertencia)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Add logic for "Rutinas" button
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.background,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text("Rutinas", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            loader: Container(),
            key: const ValueKey('all_exercises'),
          );
        }
      }
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: content,
      );
    },
  );
}

Widget _buildStatsContainer({
  required List<Widget> children,
  required Widget loader,
  required Key key,
}) {
  return Container(
    key: key,
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.appBarBackground.withAlpha(75),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.max, // Use maximum width
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space elements evenly
      children: [
        Expanded(
          // Use Expanded instead of Flexible to fill available space
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        const SizedBox(width: 20),
        loader,
      ],
    ),
  );
}
