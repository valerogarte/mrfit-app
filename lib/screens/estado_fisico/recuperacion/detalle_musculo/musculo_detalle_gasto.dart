import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/screens/ejercicios/detalle/ejercicio_detalle.dart';

class DetalleMusculoGasto extends ConsumerWidget {
  final String musculo;
  final List<Entrenamiento> entrenamientos;
  final Function(double) onPercentageCalculated;

  const DetalleMusculoGasto({
    Key? key,
    required this.musculo,
    required this.entrenamientos,
    required this.onPercentageCalculated,
  }) : super(key: key);

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
      final fechaStr = entrenamiento.formatTimeAgo();

      final exerciseListResult = _buildExerciseList(entrenamiento, musculo, factorRec, currentPercentage);
      if (exerciseListResult == null) continue;

      final trainingImpact = currentPercentage - exerciseListResult.updatedPercentage;
      currentPercentage = exerciseListResult.updatedPercentage;

      cards.add(
        _buildTrainingCard(fechaStr, entrenamientoVolumen, factorRec, trainingImpact, exerciseListResult.widget),
      );
    }

    // Si el músculo está al 100%, mostramos el mensaje creativo
    if (currentPercentage == 100.0) {
      cards.insert(0, _buildMensajeMusculoListo());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onPercentageCalculated(currentPercentage);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cards,
      ),
    );
  }

  Widget _buildMensajeMusculoListo() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: AppColors.advertencia,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.background, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Músculo listo para entrenar!',
                  style: TextStyle(
                    color: AppColors.background,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingCard(String fechaStr, double volumen, double factorRec, double trainingImpact, Widget exerciseListWidget) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera del entrenamiento
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.appBarBackground,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fechaStr,
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColor, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.fitness_center, color: AppColors.accentColor, size: 24),
                          const SizedBox(width: 5),
                          Text('${volumen.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} kg', style: TextStyle(color: AppColors.textColor, fontSize: 16)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.restore, color: AppColors.accentColor, size: 24),
                          const SizedBox(width: 5),
                          Text('x${factorRec.toStringAsFixed(2)}', style: TextStyle(color: AppColors.textColor, fontSize: 16)),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.flash_on, color: AppColors.advertencia, size: 24),
                          const SizedBox(width: 5),
                          Text('${trainingImpact.toStringAsFixed(2)}%', style: TextStyle(color: AppColors.advertencia, fontSize: 16)),
                        ],
                      )
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.accentColor, size: 24),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(color: AppColors.textColor, fontSize: 16)),
      ],
    );
  }

  _ExerciseListResult? _buildExerciseList(Entrenamiento entrenamiento, String musculo, double factorRec, double startingPercentage) {
    double currentPercentage = startingPercentage;
    List<Widget> exercises = [];

    // Get all difficulty options once
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
            borderRadius: BorderRadius.circular(8),
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
                          borderRadius: BorderRadius.circular(8),
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
                    style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text('implicación', style: TextStyle(color: AppColors.textColor, fontSize: 12)),
                  Text('(${tipoMusculo.toLowerCase()})', style: TextStyle(color: AppColors.textColor, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 10),
              // Detalles del ejercicio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.flash_on, color: AppColors.accentColor),
                        Text('${gastoActual.toStringAsFixed(1)}%', style: TextStyle(color: AppColors.textColor)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Wrap(
                            spacing: 2,
                            children: seriesRealizadas.map((serie) {
                              final matchingOption = difficultyOptions.where((option) => option['value'] == serie.rer).toList();
                              final Color iconColor = matchingOption.isNotEmpty ? matchingOption.first['iconColor'] : AppColors.textColor;

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
                        Icon(Icons.fitness_center, color: AppColors.accentColor),
                        const SizedBox(width: 5),
                        Text('${volumenMusculo.toStringAsFixed(1)}kg en $musculo', style: TextStyle(color: AppColors.textColor)),
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
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(color: AppColors.textColor, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ExerciseListResult {
  final Widget widget;
  final double updatedPercentage;

  _ExerciseListResult({required this.widget, required this.updatedPercentage});
}
