import 'package:flutter/material.dart';
import '../../../models/ejercicio/ejercicio.dart';
import 'package:mrfit/utils/colors.dart';

class EjercicioIndicaciones extends StatelessWidget {
  final Ejercicio ejercicio;

  const EjercicioIndicaciones({Key? key, required this.ejercicio}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...ejercicio.instrucciones
              .asMap()
              .entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0), // mayor margen vertical
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.transparent,
                                border: Border.all(color: AppColors.accentColor),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(fontSize: 20, color: AppColors.accentColor),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            entry.value.texto,
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.justify, // Texto justificado
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }
}
