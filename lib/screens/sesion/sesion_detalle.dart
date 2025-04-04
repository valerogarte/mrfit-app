import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/colors.dart';
import '../../models/rutina/sesion.dart';
import '../../widgets/chart/grafica.dart'; // Asegúrate de importar el ChartWidget

class SesionDetallePage extends ConsumerStatefulWidget {
  final Sesion sesion;

  const SesionDetallePage({
    Key? key,
    required this.sesion,
  }) : super(key: key);

  @override
  ConsumerState<SesionDetallePage> createState() => _SesionDetallePageState();
}

class _SesionDetallePageState extends ConsumerState<SesionDetallePage> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<Map<String, dynamic>>>(
              future: widget.sesion.getInfo(),
              builder: (context, snapshot) {
                // Debug: imprime el contenido de snapshot
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  debugPrint("Datos getInfo: ${snapshot.data}");
                } else {
                  debugPrint("Cargando getInfo...");
                }

                final bool loading = snapshot.connectionState != ConnectionState.done;
                final String numeroSesiones = !loading && snapshot.hasData ? snapshot.data![0]['numero_sesiones'] : '';
                final String tiempoTotal = !loading && snapshot.hasData ? snapshot.data![1]['tiempo_total'] : '';
                final String duracionMedia = !loading && snapshot.hasData ? snapshot.data![2]['duración_media'] : '';
                final String setsCompletados = !loading && snapshot.hasData ? snapshot.data![3]['sets_completados'] : '';

                // Debug: imprime cada valor
                debugPrint("numeroSesiones: $numeroSesiones");
                debugPrint("tiempoTotal: $tiempoTotal");
                debugPrint("duracionMedia: $duracionMedia");
                debugPrint("setsCompletados: $setsCompletados");

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final pillWidth = (constraints.maxWidth - 8) / 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPill(
                          'Sesiones realizadas',
                          loading
                              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.background)))
                              : Text(numeroSesiones, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.background)),
                          pillWidth,
                        ),
                        _buildPill(
                          'Tiempo total (horas)',
                          loading
                              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.background)))
                              : Text(tiempoTotal, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.background)),
                          pillWidth,
                        ),
                        _buildPill(
                          'Duración media',
                          loading
                              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.background)))
                              : Text(duracionMedia, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.background)),
                          pillWidth,
                        ),
                        _buildPill(
                          'Sets completados',
                          loading
                              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.background)))
                              : Text(setsCompletados, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.background)),
                          pillWidth,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            FutureBuilder<Map<String, dynamic>>(
              future: widget.sesion.getVolumenEntrenamiento(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || (snapshot.data!['labels'] as List).isEmpty) {
                  return const ChartWidget(
                    title: "Progreso de Volumen",
                    labels: [],
                    values: [],
                    textNoResults: "No hay resultados de volumen.",
                  );
                }
                final labels = List<String>.from(snapshot.data!['labels']);
                final values = List<double>.from(snapshot.data!['values']);
                return ChartWidget(
                  title: "Progreso de Volumen",
                  labels: labels,
                  values: values,
                  textNoResults: "No hay resultados de volumen.",
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String title, Widget valueWidget, double width) {
    return Container(
      width: width,
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.advertencia,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.background,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          valueWidget,
        ],
      ),
    );
  }
}
