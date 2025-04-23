part of 'ejercicios_listado.dart';

extension EjerciciosListadoSerie on _EjerciciosListadoPageState {
  Future<void> _agregarSerieAlEjercicioEnRutina(EjercicioPersonalizado ejercicioPersonalizado) async {
    // Esperamos la inserción para que se agregue la serie.
    await ejercicioPersonalizado.insertSeriePersonalizada();
    // Obtenemos las series actualizadas.
    await ejercicioPersonalizado.getSeriesPersonalizadas();
  }

  // Se actualiza _buildPromedioSeries para carga asíncrona con datos extendidos
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

          // Si no hay promedio ni detalles, mostramos un mensaje
          if (promedio == 0.0 && detalles.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Realiza este ejercicio para ver tu promedio'),
            );
          }

          // Seleccionar formato según si promedio es entero.
          final seriesText = (promedio % 1 == 0) ? '${promedio.toInt()} series' : '${promedio.toStringAsFixed(1)} series';
          // Calcular porcentaje si promedio es no entero.
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
                  // Muestra cada serie en una nueva fila con el número de serie a la izquierda y descanso
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
                                    shadows: detalle["rer"] < 6 // Por tema de visibilidad
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
                                  shadows: detalle["rer"] < 6 // Por tema de visibilidad
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

  Widget _buildSeriesControls(EjercicioPersonalizado ejercicioPersonalizado, void Function(void Function()) localSetState) {
    return Column(
      children: [
        Divider(color: AppColors.textMedium), // Visual separator added
        Padding(
          padding: const EdgeInsets.only(top: 25.0, bottom: 15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _confirmDeleteExercise(ejercicioPersonalizado),
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
                  setState(() {}); // Actualiza la vista en ejercicios_listado.dart
                  localSetState(() {}); // Actualiza la vista del bottom sheet
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

  void _confirmDeleteExercise(EjercicioPersonalizado ejercicioPersonalizado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
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
            onPressed: () {
              Navigator.pop(context);
              ejercicioPersonalizado.delete();
              setState(() {
                final index = _ejercicios.indexWhere((e) => e.id == ejercicioPersonalizado.id);
                if (index != -1) {
                  _ejercicios.removeAt(index);
                }
              });
              // Cierra el bottom sheet
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      String hours = twoDigits(duration.inHours);
      return "$hours:$minutes:$seconds";
    } else {
      return "$minutes:$seconds";
    }
  }
}
