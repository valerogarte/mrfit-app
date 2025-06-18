import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/screens/ejercicios/detalle/ejercicio_detalle.dart';
import 'package:mrfit/utils/mr_functions.dart';

class DetalleMusculoGasto extends ConsumerWidget {
  final String musculo;
  final List<Entrenamiento> entrenamientos;
  final Function(double) onPercentageCalculated;

  const DetalleMusculoGasto({
    super.key,
    required this.musculo,
    required this.entrenamientos,
    required this.onPercentageCalculated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double currentPercentage = 100.0;
    List<Widget> cards = [];
    final usuario = ref.read(usuarioProvider);

    for (final entrenamiento in entrenamientos) {
      final diasMaxRec = entrenamiento.getDiasMaximoParaRecuperacionMuscular();
      final finTime = entrenamiento.fin ?? DateTime.now();
      if (DateTime.now().difference(finTime).inDays > diasMaxRec) continue;

      entrenamiento.calcularRecuperacion(usuario);
      final entrenamientoVolumen = entrenamiento.entrenamientoVolumen;
      final factorRec = entrenamiento.factorRec;
      final fechaStr = MrFunctions.formatTimeAgo(entrenamiento.inicio);

      // Pasa context a _buildExerciseList
      final exerciseListResult = _buildExerciseList(
        context,
        entrenamiento,
        musculo,
        factorRec,
        currentPercentage,
      );
      if (exerciseListResult == null) continue;

      final trainingImpact = currentPercentage - exerciseListResult.updatedPercentage;
      currentPercentage = exerciseListResult.updatedPercentage;

      cards.add(
        Column(
          children: [
            _buildTrainingCard(fechaStr, entrenamientoVolumen, factorRec, trainingImpact, exerciseListResult.widget, context),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    // Si el músculo está al 100%, mostramos el mensaje creativo
    if (currentPercentage == 100.0) {
      cards.insert(0, _buildMensajeMusculoListo());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onPercentageCalculated(currentPercentage);
    });

    // Contenedor con bordes redondeados y scroll interno, usando SafeArea
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards,
          ),
        ),
      ),
    );
  }

  /// Muestra un mensaje centrado cuando el músculo está completamente recuperado.
  Widget _buildMensajeMusculoListo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Card(
        color: AppColors.mutedAdvertencia,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.background, size: 32),
                const SizedBox(width: 10),
                Text(
                  '¡Músculo listo para entrenar!',
                  style: TextStyle(
                    color: AppColors.background,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingCard(String fechaStr, double volumen, double factorRec, double trainingImpact, Widget exerciseListWidget, BuildContext context) {
    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero, // Ocupa el 100% del ancho, sin margen
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del entrenamiento
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.appBarBackground,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fecha centrada visualmente
                Center(
                  child: Text(
                    fechaStr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMedium,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icono gym con modal
                    GestureDetector(
                      onTap: () => _showInfoDialog(
                        context,
                        title: 'Volumen total',
                        description: 'El volumen total (kg) representa la suma de todos los kilogramos movidos en el entrenamiento.',
                        icon: Icons.fitness_center,
                        iconColor: AppColors.accentColor,
                        formula: [
                          'VT = suma de todos los pesos',
                          'VT = ${volumen.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} kg',
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center, color: AppColors.accentColor, size: 24),
                          const SizedBox(width: 5),
                          Text('${volumen.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} kg', style: TextStyle(color: AppColors.textMedium, fontSize: 16)),
                        ],
                      ),
                    ),
                    // Icono restaurar (factorRec) con modal
                    GestureDetector(
                      onTap: () => _showInfoDialog(
                        context,
                        title: 'Factor de recuperación',
                        description:
                            'El factor de recuperación es un multiplicador que ajusta el impacto del entrenamiento. Utiliza una función exponencial para modelar la recuperación y limita el valor según el tiempo máximo y mínimo de recuperación muscular.',
                        icon: Icons.restore,
                        iconColor: AppColors.accentColor,
                        formula: [
                          'FR = tiempoDesdeFinEntrenamiento x factorDecaida',
                          'FR = ${factorRec.toStringAsFixed(2)}',
                        ],
                        imageAsset: 'assets/images/app/factor_recuperacion.png',
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.restore, color: AppColors.accentColor, size: 24),
                          const SizedBox(width: 5),
                          Text('x${factorRec.toStringAsFixed(2)}', style: TextStyle(color: AppColors.textMedium, fontSize: 16)),
                        ],
                      ),
                    ),
                    // Icono rayo con modal
                    GestureDetector(
                      onTap: () => _showInfoDialog(
                        context,
                        title: 'Gasto muscular en este entrenamiento',
                        description: 'El impacto del entrenamiento en el músculo seleccionado. Representa la suma del porcentaje de fatiga generado por todos los ejercicios realizados.',
                        icon: Icons.flash_on,
                        iconColor: AppColors.mutedAdvertencia,
                        formula: [
                          'I = suma del % actual de todos los ejercicios con el factor de recuperación aplicado',
                          'I = ej1(%) + ej2(%) + ...',
                          'I = ${trainingImpact.toStringAsFixed(2)}%',
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.flash_on, color: AppColors.mutedAdvertencia, size: 24),
                          const SizedBox(width: 5),
                          Text('${trainingImpact.toStringAsFixed(2)}%', style: TextStyle(color: AppColors.mutedAdvertencia, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          // Ejercicios realizados
          Padding(
            padding: const EdgeInsets.all(8),
            child: exerciseListWidget,
          ),
          // El espaciador se elimina de aquí
        ],
      ),
    );
  }

  _ExerciseListResult? _buildExerciseList(
    BuildContext context,
    Entrenamiento entrenamiento,
    String musculo,
    double factorRec,
    double startingPercentage,
  ) {
    double currentPercentage = startingPercentage;
    List<Widget> exercises = [];

    final List<Map<String, dynamic>> difficultyOptions = ModeloDatos.getDifficultyOptions();

    for (final ejercicioRealizado in entrenamiento.ejercicios) {
      final ejercicio = ejercicioRealizado.ejercicio;
      final musculosInvolucrados = ejercicio.musculosInvolucrados;
      if (!musculosInvolucrados.any((m) => m.musculo.titulo.toLowerCase() == musculo.toLowerCase())) continue;

      final indexMusculo = musculosInvolucrados.indexWhere((m) => m.musculo.titulo.toLowerCase() == musculo.toLowerCase());
      if (indexMusculo == -1) continue;

      final musculosValores = ejercicioRealizado.volumenPorMusculo;
      if (!musculosValores.containsKey(musculo.toLowerCase())) continue;

      final musculoValores = musculosValores[musculo.toLowerCase()];
      final musculoSeleccionado = musculosInvolucrados[indexMusculo];
      final String nombre = ejercicio.nombre;
      final int porcentajeImplicacion = musculoSeleccionado.porcentajeImplicacion;
      final String tipoMusculo = musculoSeleccionado.tipoString;
      final double volumenMusculo = musculoValores['volumenMusculoEnEjercicio'] ?? 0.0;
      final gastoActual = double.tryParse((musculoValores['gastoDelMusculoPorcentajeActual'] ?? '0.0').toString()) ?? 0.0;
      if (gastoActual == 0.0) continue;

      final seriesRealizadas = ejercicioRealizado.series.where((s) => !s.deleted && s.realizada).toList();
      final anterior = currentPercentage;
      currentPercentage -= gastoActual;

      exercises.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen y porcentaje de implicación
              Column(
                children: [
                  Builder(
                    builder: (context) {
                      return GestureDetector(
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EjercicioDetallePage(
                                ejercicio: ejercicio,
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            ejercicio.imagenUno,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$porcentajeImplicacion%',
                    style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('implicación', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                  Text('(${tipoMusculo.toLowerCase()})', style: TextStyle(color: AppColors.textMedium, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 10),
              // Detalles del ejercicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Icono rayo con modal
                        GestureDetector(
                          onTap: () => _showInfoDialog(
                            context,
                            title: 'Gasto muscular',
                            description: 'Porcentaje de fatiga generado en este músculo por el ejercicio.',
                            icon: Icons.flash_on,
                            iconColor: AppColors.accentColor,
                            formula: [
                              'GM = Fatiga inicial - Fatiga final',
                              'GM = ${anterior.toStringAsFixed(1)}% - ${(anterior - gastoActual).toStringAsFixed(1)}%',
                              "GM = ${gastoActual.toStringAsFixed(1)}%",
                            ],
                          ),
                          child: Icon(Icons.flash_on, color: AppColors.accentColor),
                        ),
                        Text('${gastoActual.toStringAsFixed(1)}%', style: TextStyle(color: AppColors.textMedium)),
                        const SizedBox(width: 5),
                        // Caritas con modal
                        GestureDetector(
                          onTap: () => _showInfoDialog(
                            context,
                            title: 'Dificultad percibida',
                            description: 'Cada cara representa una serie realizada y su color la dificultad percibida (RIR).',
                            icon: Icons.emoji_emotions,
                            iconColor: AppColors.accentColor,
                            difficultyLegend: ModeloDatos.getDifficultyOptions(),
                          ),
                          child: Wrap(
                            spacing: 2,
                            children: seriesRealizadas.map((serie) {
                              final matchingOption = difficultyOptions.where((option) => option['value'] == serie.rer).toList();
                              final Color iconColor = matchingOption.isNotEmpty ? matchingOption.first['iconColor'] : AppColors.textMedium;

                              return Icon(
                                Icons.emoji_emotions,
                                color: iconColor,
                                size: 20,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        // Icono gym con modal
                        GestureDetector(
                          onTap: () => _showInfoDialog(
                            context,
                            title: 'Volumen en ejercicio',
                            description: 'Cantidad de peso total movido por este músculo en el ejercicio.',
                            icon: Icons.fitness_center,
                            iconColor: AppColors.accentColor,
                            formula: [
                              'V = (peso x reps x series) x %uso',
                              'V = ${ejercicioRealizado.volumenTotal} x ${porcentajeImplicacion / 100}',
                              'V = ${volumenMusculo.toStringAsFixed(1)}kg',
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.fitness_center, color: AppColors.accentColor),
                              const SizedBox(width: 5),
                              Text('${volumenMusculo.toStringAsFixed(1)}kg en $musculo', style: TextStyle(color: AppColors.textMedium)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showInfoDialog(
                            context,
                            title: 'Uso del peso corporal',
                            description: 'Indica el porcentaje del ejercicio en el que el peso corporal actúa como peso adicional. Un valor elevado significa que el propio cuerpo es clave en la ejecución del movimiento.',
                            icon: Icons.monitor_weight,
                            iconColor: AppColors.accentColor,
                            formula: [],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.monitor_weight, color: AppColors.accentColor),
                              const SizedBox(width: 5),
                              ejercicioRealizado.ejercicio.influenciaPesoCorporal == 0
                                  ? Text(
                                      'Sin uso del peso corporal',
                                      style: TextStyle(color: AppColors.textMedium),
                                    )
                                  : Text(
                                      '${(ejercicioRealizado.ejercicio.influenciaPesoCorporal * 100).round()}% uso peso corporal',
                                      style: TextStyle(color: AppColors.textMedium),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progresión de porcentaje
                    Row(
                      children: [
                        _buildPercentageBox(anterior.toStringAsFixed(1)),
                        const Icon(Icons.double_arrow_outlined, color: AppColors.accentColor, size: 24),
                        _buildPercentageBox(currentPercentage.toStringAsFixed(1)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (exercises.isEmpty) return null;
    return _ExerciseListResult(
      widget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: exercises,
      ),
      updatedPercentage: currentPercentage,
    );
  }

  Widget _buildPercentageBox(String percentage) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(color: AppColors.textMedium, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Muestra un modal explicativo para los iconos informativos usando la paleta de AppColors
  void _showInfoDialog(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    List<Map<String, dynamic>>? difficultyLegend,
    List<String>? formula,
    String? imageAsset,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.textNormal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(color: AppColors.textMedium),
            ),
            if (formula != null && formula.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Se calcula:',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              ...formula.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: AppColors.textNormal,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  )),
            ],
            if (imageAsset != null) ...[
              const SizedBox(height: 14),
              Center(
                child: Image.asset(
                  imageAsset,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ],
            if (difficultyLegend != null) ...[
              const SizedBox(height: 16),
              Text(
                'Leyenda de dificultad:',
                style: TextStyle(
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              ...difficultyLegend.map(
                (option) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.emoji_emotions, color: option['iconColor'], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            option['label'],
                            style: TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 25, top: 2),
                        child: Text(
                          option['description'],
                          style: TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accentColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseListResult {
  final Widget widget;
  final double updatedPercentage;

  _ExerciseListResult({required this.widget, required this.updatedPercentage});
}
