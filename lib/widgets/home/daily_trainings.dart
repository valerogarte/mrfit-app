import 'package:flutter/material.dart';
import 'package:mrfit/screens/rutinas/rutinas_page.dart';
import 'package:mrfit/screens/rutinas/rutina_detalle.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/utils/constants.dart';
import 'package:mrfit/screens/entrenamiento_realizado/entrenamiento_realizado.dart';

class DailyTrainingsWidget extends StatefulWidget {
  final DateTime day;
  final Usuario usuario;

  const DailyTrainingsWidget({Key? key, required this.day, required this.usuario}) : super(key: key);

  @override
  _DailyTrainingsWidgetState createState() => _DailyTrainingsWidgetState();
}

class _DailyTrainingsWidgetState extends State<DailyTrainingsWidget> {
  // Se elimina el Padding interno y se retorna directamente el Row
  Future<Widget> _buildActivityRow({
    required String uuid,
    int? id,
    required String title,
    required DateTime start,
    required DateTime end,
    required IconData icon,
    required Color iconColor,
    required Color iconBackgroundColor,
    required String timeInfo,
    String? sourceName,
  }) async {
    if (sourceName != null && sourceName == AppConstants.domainNameApp) {
      final entrenamiento = await Entrenamiento.loadByUuid(uuid);
      if (entrenamiento != null) {
        title = entrenamiento.titulo;
      }
    } else if (id != null && id > 0) {
      final entrenamiento = await Entrenamiento.loadById(id);
      if (entrenamiento != null) {
        title = entrenamiento.titulo;
      }
    }
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EntrenamientoRealizadoPage(
                      idHealthConnect: uuid,
                      id: id ?? 0,
                      title: title,
                      icon: icon,
                      start: start,
                      end: end,
                    )));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: iconBackgroundColor,
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: AppColors.textNormal, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            timeInfo,
            style: const TextStyle(color: AppColors.textMedium),
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
          dynamicContent = _buildPlaceholder("Cargando actividad", Icons.blur_on_sharp);
        } else if (snapshot.hasError) {
          dynamicContent = _buildPlaceholder("Error al cargar", Icons.error);
        } else {
          final activities = snapshot.data ?? [];
          if (activities.isEmpty) {
            dynamicContent = _buildPlaceholder("Sin actividad", Icons.blur_on_sharp);
          } else {
            dynamicContent = Column(
              children: activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value;
                if (activity['type'] == 'steps') {
                  return FutureBuilder<Widget>(
                    future: _buildActivityRow(
                      uuid: "automatic",
                      title: "Caminar (automático)",
                      start: activity['start'],
                      end: activity['end'],
                      icon: Icons.directions_walk,
                      iconColor: AppColors.mutedAdvertencia,
                      iconBackgroundColor: AppColors.appBarBackground,
                      timeInfo: "${activity['start'].toLocal().toIso8601String().split('T').last.split('.').first.substring(0, 5)} (${activity['durationMin']} min)",
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        final rowWidget = snapshot.data!;
                        return index == activities.length - 1 ? rowWidget : Padding(padding: const EdgeInsets.only(bottom: 10), child: rowWidget);
                      }
                      return const SizedBox(height: 50);
                    },
                  );
                } else if (activity['type'] == 'workout') {
                  final info = ModeloDatos().getActivityTypeDetails(activity['activityType']);
                  final duration = (activity['end'] as DateTime).difference(activity['start'] as DateTime).inMinutes;
                  return FutureBuilder<Widget>(
                    future: _buildActivityRow(
                      uuid: activity['uuid'] ?? "",
                      id: activity['id'] ?? 0,
                      title: info["nombre"],
                      start: activity['start'],
                      end: activity['end'],
                      icon: info["icon"],
                      iconColor: AppColors.mutedAdvertencia,
                      iconBackgroundColor: AppColors.appBarBackground,
                      timeInfo: "${activity['start'].toLocal().toIso8601String().split('T').last.split('.').first.substring(0, 5)} ($duration min)",
                      sourceName: activity['sourceName'],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        final rowWidget = snapshot.data!;
                        return index == activities.length - 1 ? rowWidget : Padding(padding: const EdgeInsets.only(bottom: 10), child: rowWidget);
                      }
                      return const SizedBox(height: 50);
                    },
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
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(20),
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
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RutinasPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.list_alt, color: AppColors.textNormal, size: 18),
                  label: const Text("Rutinas", style: TextStyle(color: AppColors.textNormal, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: hasRutina
                    ? ElevatedButton.icon(
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RutinaPage(rutina: snapshot.data)),
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
                      )
                    : Container(),
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
          child: Icon(icon, size: 18, color: AppColors.mutedAdvertencia),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(color: AppColors.textMedium, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
