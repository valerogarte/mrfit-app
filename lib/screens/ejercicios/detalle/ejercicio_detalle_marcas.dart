import 'package:flutter/material.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/widgets/ejercicio/ejercicio_tabla_mejor_marca.dart';
import 'package:mrfit/widgets/ejercicio/ejercicio_grafica_progresion_marca.dart';

class EjercicioMarcas extends StatelessWidget {
  final Ejercicio ejercicio;

  const EjercicioMarcas({Key? key, required this.ejercicio}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ejercicio.getRecord(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: EjercicioTablaMejorMarca(data: data),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: EjercicioGraficaProgresionMarca(ejercicio: ejercicio),
              ),
            ],
          ),
        );
      },
    );
  }
}
