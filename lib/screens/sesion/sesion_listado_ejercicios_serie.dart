import 'package:flutter/material.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/models/rutina/ejercicio_personalizado.dart';
import 'package:mrfit/screens/sesion/sesion_listado_ejercicios_serie_detalle.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/utils/mr_functions.dart';

class SesionGestionSeriesPage extends StatefulWidget {
  final EjercicioPersonalizado ejercicioPersonalizado;
  final VoidCallback? onSeriesChanged;

  const SesionGestionSeriesPage({
    super.key,
    required this.ejercicioPersonalizado,
    this.onSeriesChanged,
  });

  @override
  State<SesionGestionSeriesPage> createState() => _SesionGestionSeriesPageState();
}

class _SesionGestionSeriesPageState extends State<SesionGestionSeriesPage> {
  int? expandedSetIndex;

  Future<void> _agregarSerieAlEjercicioEnRutina(EjercicioPersonalizado ejercicioPersonalizado) async {
    await ejercicioPersonalizado.insertSeriePersonalizada();
    await ejercicioPersonalizado.getSeriesPersonalizadas();
  }

  Widget _buildPromedioSeries(EjercicioPersonalizado ejercicioPersonalizado) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ejercicioPersonalizado.ejercicio.getNumeroSeriesPromedioRealizadasPorEntrenamiento(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Error al cargar promedio', style: TextStyle(color: AppColors.textNormal)),
          );
        } else {
          final data = snapshot.data!;
          double promedio = data['promedioSeries'] ?? 0.0;
          List detalles = data['detallesSeries'] ?? [];

          if (promedio == 0.0 && detalles.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Realiza este ejercicio para ver tu promedio'),
            );
          }

          final seriesText = (promedio % 1 == 0) ? '${promedio.toInt()} series' : '${promedio.toStringAsFixed(1)} series';
          final bool mostrarPorcentaje = (promedio % 1 != 0 || (detalles.length >= promedio + 1)) && detalles.isNotEmpty;
          final porcentaje = mostrarPorcentaje ? ((promedio - promedio.toInt()) * 100).toStringAsFixed(0) : '';
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sueles ir a $seriesText',
                  style: const TextStyle(fontSize: 16, color: AppColors.textMedium),
                ),
                if (detalles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(detalles.length, (index) {
                      final detalle = detalles[index];
                      String detailText = '${detalle['repeticiones']} reps, ${detalle['peso']}kg y ${detalle['descanso']}s';
                      final dificultad = detalle["rer"] > 0 ? ModeloDatos.getDifficultyOptions(value: detalle["rer"]) : [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.textMedium.withAlpha(150),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '${index + 1}. ',
                                style: const TextStyle(fontSize: 14, color: AppColors.background, fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  detailText,
                                  style: const TextStyle(fontSize: 14, color: AppColors.background),
                                ),
                              ),
                              if (detalle["rer"] > 0) ...[
                                Text(
                                  (dificultad["label"] as String),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: dificultad["iconColor"] as Color,
                                    shadows: detalle["rer"] < 6
                                        ? [
                                            Shadow(
                                              blurRadius: 5.0,
                                              color: AppColors.background,
                                              offset: const Offset(0, 0),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.emoji_emotions,
                                  color: dificultad["iconColor"],
                                  size: 20,
                                  shadows: detalle["rer"] < 6
                                      ? [
                                          Shadow(
                                            blurRadius: 5.0,
                                            color: AppColors.background,
                                            offset: const Offset(0, 0),
                                          ),
                                        ]
                                      : null,
                                )
                              ]
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  if (mostrarPorcentaje)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Center(
                        child: Text(
                          detalles.length >= promedio + 1 ? 'En ocasiones haces ${(detalles.length - promedio).toInt()} más.' : 'Solo realizas la ${detalles.length}ª serie el $porcentaje% de los entrenamientos*',
                          style: const TextStyle(fontSize: 14, color: AppColors.mutedAdvertencia),
                        ),
                      ),
                    ),
                ]
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildSeriesControls(EjercicioPersonalizado ejercicioPersonalizado, void Function(void Function()) localSetState, {VoidCallback? onSeriesChanged, BuildContext? context}) {
    return Column(
      children: [
        Divider(color: AppColors.textMedium),
        Padding(
          padding: const EdgeInsets.only(top: 25.0, bottom: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  if (context != null) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.background,
                        title: const Text(
                          'Eliminar Ejercicio',
                          style: TextStyle(color: AppColors.textNormal),
                        ),
                        content: const Text(
                          '¿Estás seguro de que deseas eliminar este ejercicio?',
                          style: TextStyle(color: AppColors.textNormal),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: AppColors.mutedRed),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await ejercicioPersonalizado.delete();
                              if (onSeriesChanged != null) onSeriesChanged();
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context, true);
                              }
                            },
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.delete, color: AppColors.textNormal),
                label: const Text('Eliminar Ejercicio', style: TextStyle(color: AppColors.textNormal)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mutedRed,
                ),
              ),
              const SizedBox(width: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  await _agregarSerieAlEjercicioEnRutina(ejercicioPersonalizado);
                  localSetState(() {});
                  if (onSeriesChanged != null) onSeriesChanged();
                },
                icon: const Icon(Icons.add, color: AppColors.textMedium, size: 18),
                label: const Text('Añadir Serie', style: TextStyle(color: AppColors.textMedium)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.textMedium, width: 1.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ejercicioPersonalizado = widget.ejercicioPersonalizado;
    return Scaffold(
      appBar: AppBar(
        title: Text(ejercicioPersonalizado.ejercicio.nombre, style: TextStyle(color: AppColors.textNormal)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textNormal),
        elevation: 0,
        actions: [
          // Botón de menú con 3 puntitos
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textNormal),
            onSelected: (value) {
              if (value == 'eliminar') {
                // Mostrar el mismo diálogo de eliminación
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.background,
                    title: const Text(
                      'Eliminar Ejercicio',
                      style: TextStyle(color: AppColors.textNormal),
                    ),
                    content: const Text(
                      '¿Estás seguro de que deseas eliminar este ejercicio?',
                      style: TextStyle(color: AppColors.textNormal),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppColors.mutedRed),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Cierra el diálogo
                          await ejercicioPersonalizado.delete();
                          if (widget.onSeriesChanged != null) widget.onSeriesChanged!();
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context, true); // Cierra la pantalla de series
                          }
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'eliminar',
                child: Text('Eliminar'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Series',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textNormal,
                    ),
                  ),
                  FutureBuilder<List<dynamic>>(
                    future: Future.wait([ejercicioPersonalizado.calcularTiempo(), ejercicioPersonalizado.calcularVolumen()]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                        return const SizedBox();
                      } else {
                        final int tiempo = snapshot.data![0] as int;
                        final double volumen = snapshot.data![1] as double;
                        final String tiempoFormateado = (MrFunctions.formatDuration(Duration(seconds: tiempo)));
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer, color: AppColors.mutedAdvertencia, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              tiempoFormateado,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textNormal,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.fitness_center, color: AppColors.mutedAdvertencia, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$volumen kg',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textNormal,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ejercicioPersonalizado.countSeriesPersonalizadas(),
              itemBuilder: (context, setIndex) {
                final serieP = ejercicioPersonalizado.seriesPersonalizadas?[setIndex];
                if (serieP != null) {
                  return SesionGestionSerieDetalle(
                    key: ValueKey(serieP.id),
                    setIndex: setIndex,
                    serieP: serieP,
                    ejercicioP: ejercicioPersonalizado,
                    isExpanded: (expandedSetIndex == setIndex),
                    onToggleExpand: () {
                      setState(() {
                        expandedSetIndex = expandedSetIndex == setIndex ? null : setIndex;
                      });
                    },
                    onDelete: () async {
                      setState(() => ejercicioPersonalizado.seriesPersonalizadas?.removeAt(setIndex));
                      if (widget.onSeriesChanged != null) widget.onSeriesChanged!();
                    },
                    onSave: () async {
                      await ejercicioPersonalizado.getSeriesPersonalizadas();
                      setState(() {});
                      if (widget.onSeriesChanged != null) widget.onSeriesChanged!();
                    },
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
            _buildSeriesControls(
              ejercicioPersonalizado,
              (fn) => setState(fn),
              onSeriesChanged: widget.onSeriesChanged,
              context: context,
            ),
            _buildPromedioSeries(ejercicioPersonalizado),
          ],
        ),
      ),
    );
  }
}
