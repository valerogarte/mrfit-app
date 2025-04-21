import 'package:flutter/material.dart';
import 'package:health/health.dart'; // Add this import for HealthDataPoint and WorkoutHealthValue
import '../../screens/planes/planes.dart';
import '../../screens/entrenamiento/entrenamiento_dias.dart';
import '../../models/usuario/usuario.dart';
import '../../models/modelo_datos.dart';
import '../../utils/colors.dart';

class DailyTrainingsWidget extends StatefulWidget {
  final DateTime day;
  final Usuario usuario;

  const DailyTrainingsWidget({Key? key, required this.day, required this.usuario}) : super(key: key);

  @override
  _DailyTrainingsWidgetState createState() => _DailyTrainingsWidgetState();
}

class _DailyTrainingsWidgetState extends State<DailyTrainingsWidget> {
  Widget _buildActivityRow({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String timeInfo,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: iconBackgroundColor,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            timeInfo,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDay = widget.day.toIso8601String().split('T').first;
    final isToday = selectedDay == DateTime.now().toIso8601String().split('T').first;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.usuario.getActivity(selectedDay),
      builder: (context, snapshot) {
        Widget dynamicContent;

        if (snapshot.connectionState != ConnectionState.done) {
          dynamicContent = _buildPlaceholder("Cargando actividad", Icons.fitness_center);
        } else if (snapshot.hasError) {
          dynamicContent = _buildPlaceholder("Error al cargar", Icons.error);
        } else {
          final activities = snapshot.data ?? [];
          if (activities.isEmpty) {
            dynamicContent = _buildPlaceholder("Sin actividad", Icons.fitness_center);
          } else {
            dynamicContent = Column(
              children: activities.map((activity) {
                if (activity['type'] == 'steps') {
                  return _buildActivityRow(
                    title: "Caminar (automático)",
                    icon: Icons.directions_walk,
                    iconColor: AppColors.advertencia,
                    iconBackgroundColor: AppColors.appBarBackground,
                    timeInfo: "${activity['start'].toLocal().toIso8601String().split('T').last.split('.').first} (${activity['durationMin']} min)",
                  );
                } else if (activity['type'] == 'workout') {
                  final info = ModeloDatos().getActivityTypeDetails(activity['activityType']);
                  final duration = (activity['end'] as DateTime).difference(activity['start'] as DateTime).inMinutes;
                  return _buildActivityRow(
                    title: info["nombre"],
                    icon: info["icon"],
                    iconColor: AppColors.advertencia,
                    iconBackgroundColor: AppColors.appBarBackground,
                    timeInfo: "${activity['start'].toLocal().toIso8601String().split('T').last.split('.').first} (${duration} min)",
                  );
                }
                return const SizedBox.shrink();
              }).toList(),
            );
          }
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.appBarBackground.withAlpha(75),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: dynamicContent,
              ),
              if (isToday) const SizedBox(height: 10),
              if (isToday) _buildButtonsRow(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButtonsRow() {
    return FutureBuilder<dynamic>(
      future: widget.usuario.getCurrentRutina(),
      builder: (context, snapshot) {
        final hasRutina = snapshot.connectionState == ConnectionState.done && !snapshot.hasError && snapshot.hasData;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!mounted) return;
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlanesPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.list_alt, color: Colors.white, size: 18),
                  label: const Text("Rutinas", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              if (hasRutina) const SizedBox(width: 10),
              if (hasRutina)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EntrenamientoDiasPage(rutina: snapshot.data)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mutedAdvertencia,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.fitness_center, color: AppColors.background, size: 18),
                    label: Text(
                      snapshot.data.titulo,
                      style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(String text, IconData icon) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.appBarBackground,
          child: Icon(icon, size: 18, color: AppColors.advertencia),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(color: AppColors.textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
