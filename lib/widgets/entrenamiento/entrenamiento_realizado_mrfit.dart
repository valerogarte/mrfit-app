import 'package:flutter/material.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/entrenamiento/entrenamiento_resumen_series.dart';

class EntrenamientoMrFitWidget extends StatelessWidget {
  final Entrenamiento entrenamiento;

  const EntrenamientoMrFitWidget({super.key, required this.entrenamiento});

  @override
  Widget build(BuildContext context) {
    // Filtramos ejercicios realizados para mostrar mensaje si no hay
    final ejerciciosRealizados = entrenamiento.ejercicios.where((ejercicio) => ejercicio.countSeriesRealizadas() > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.mutedAdvertencia, width: 2),
          ),
          child: Text(
            ModeloDatos.getSensacionText(entrenamiento.sensacion.toDouble()),
            style: const TextStyle(
              color: AppColors.mutedAdvertencia,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        if (ejerciciosRealizados.isEmpty)
          // Mensaje claro si no hay ejercicios realizados
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 50),
            decoration: BoxDecoration(
              color: AppColors.mutedAdvertencia,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'Sin ejercicios realizados',
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          )
        else
          ...ejerciciosRealizados.map((ejercicio) {
            return ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ejercicio.ejercicio.nombre,
                    style: const TextStyle(
                      color: AppColors.textNormal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: ejercicio.series.asMap().entries.map((entry) {
                  final index = entry.key;
                  final serie = entry.value;
                  return ResumenSerie(
                    index: index,
                    serie: serie,
                    pesoUsuario: entrenamiento.pesoUsuario,
                  );
                }).toList(),
              ),
            );
          }).toList(),
      ],
    );
  }
}
