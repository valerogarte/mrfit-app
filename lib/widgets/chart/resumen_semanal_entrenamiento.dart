import 'package:flutter/material.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';

class ResumenSemanalEntrenamientosWidget extends StatelessWidget {
  final Usuario usuario;
  final int daysTrainedLast30Days;
  final int daysTrainedLast7Days;

  const ResumenSemanalEntrenamientosWidget({
    Key? key,
    required this.usuario,
    required this.daysTrainedLast30Days,
    required this.daysTrainedLast7Days,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obtiene el objetivo semanal del usuario
    final int objetivoSemanal = usuario.objetivoEntrenamientoSemanal ?? 0;

    // Calcula el objetivo mensual basado en el objetivo semanal
    final int objetivoMensual = ((objetivoSemanal * 30) / 7).floor();

    // Determina el color para los entrenamientos semanales
    final Color colorSemanal = daysTrainedLast7Days >= objetivoSemanal ? AppColors.accentColor : Colors.red;

    // Determina el color para los entrenamientos mensuales
    final Color colorMensual = daysTrainedLast30Days >= objetivoMensual ? AppColors.accentColor : Colors.red;

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: AppColors.mutedAdvertencia,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Encabezado y botón cerrar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Resumen entrenamientos',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textMedium,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMedium),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Primera fila: datos y icono
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$daysTrainedLast7Days',
                            style: TextStyle(
                              fontSize: 40,
                              color: colorSemanal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '/7',
                            style: const TextStyle(
                              fontSize: 25,
                              color: AppColors.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.fitness_center,
                    color: AppColors.mutedAdvertencia,
                    size: 36,
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$daysTrainedLast30Days',
                            style: TextStyle(
                              fontSize: 40,
                              color: colorMensual,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: '/30',
                            style: const TextStyle(
                              fontSize: 25,
                              color: AppColors.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Segunda fila: descripciones debajo de cada estadística
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'días entrenados',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 36 + 16), // icon width + padding
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: const Text(
                      'días entrenados',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Mensaje si no se ha conseguido el objetivo semanal
            // Unifica el mensaje de advertencia para mostrar solo uno, priorizando el objetivo semanal
            if (daysTrainedLast7Days < objetivoSemanal)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.mutedAdvertencia,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Debes entrenar ${objetivoSemanal - daysTrainedLast7Days} día(s) más para conseguir tu objetivo semanal.',
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (daysTrainedLast30Days < objetivoMensual)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.mutedAdvertencia,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Debes entrenar ${objetivoMensual - daysTrainedLast30Days} día(s) más para conseguir tu objetivo de 30 días.',
                  style: const TextStyle(
                    color: AppColors.background,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              // Mensaje de felicitación si se cumplen ambos objetivos
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.mutedAdvertencia,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      '¡Felicidades!',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cumples con tus objetivos de entrenamiento.',
                      style: TextStyle(
                        color: AppColors.background,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
