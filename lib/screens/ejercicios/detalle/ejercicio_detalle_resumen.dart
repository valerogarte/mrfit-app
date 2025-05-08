import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/chart/pills_dificultad.dart';
import 'package:mrfit/widgets/animated_image.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/widgets/grafico_ejercicios_musculosinvolucrados.dart'; // Import nuevo widget
import 'package:mrfit/widgets/ejercicio/ejercicio_tiempo_recomendado_por_repeticion.dart';

class EjercicioResumen extends StatelessWidget {
  final Ejercicio ejercicio;

  const EjercicioResumen({Key? key, required this.ejercicio}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: AnimatedImage(
                      ejercicio: ejercicio,
                      width: MediaQuery.of(context).size.width,
                    ),
                  ),
                ],
              ),
            ),
            // Sección 1: Resto de información
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Container(
                width: double.infinity, // Ocupa 100% del ancho
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  // color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ejercicio.categoria.titulo,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          buildDificultadPills(int.parse(ejercicio.dificultad.titulo), 10, 20),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ejercicio.realizarPorExtremidad == true ? 'Por extremidad' : '',
                            style: TextStyle(color: AppColors.accentColor, fontSize: 12.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sección 2: Equipamiento, Tipo Fuerza e Influencia Peso
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          margin: const EdgeInsets.only(right: 4.0),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Center(
                            child: Text(ejercicio.equipamiento.titulo.toUpperCase()),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Center(
                            child: Text(ejercicio.tipoFuerza.titulo.toUpperCase()),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(4.0),
                          margin: const EdgeInsets.only(left: 4.0),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "${ejercicio.influenciaPesoCorporal}",
                                style: const TextStyle(
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.mutedAdvertencia,
                                ),
                              ),
                              const Text(
                                "Influencia peso corporal",
                                style: TextStyle(fontSize: 8.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            GraficoCircularMusculosInvolucrados(ejercicio: ejercicio),
            SizedBox(height: 16.0),
            // Sección de listado de errores comunes
            if (ejercicio.erroresComunes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Errores Comunes:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ejercicio.erroresComunes
                          .map((error) => Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8.0),
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: AppColors.mutedRed,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Text(
                                  error.texto,
                                  style: TextStyle(color: AppColors.textNormal),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            // Título de la sección
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Tiempo recomendado por repetición",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            EjercicioTiempoRecomendadoPorRepeticion(ejercicio: ejercicio),
          ],
        ),
      ),
    );
  }
}
