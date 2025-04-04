import 'package:flutter/material.dart';
import 'ejercicio_detalle_resumen.dart';
import 'ejercicio_detalle_marcas.dart';
import 'ejercicio_detalle_historia.dart';
import 'ejercicio_detalle_indicaciones.dart';
import '../../../models/ejercicio/ejercicio.dart';
import '../../../utils/colors.dart'; // Import colors

class EjercicioDetallePage extends StatelessWidget {
  final Ejercicio ejercicio;

  const EjercicioDetallePage({Key? key, required this.ejercicio}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Updated from 3 to 4
      child: Scaffold(
        backgroundColor: AppColors.background, // Set scroll/background color
        appBar: AppBar(
          title: Text(ejercicio.nombre), // Add title to AppBar
          bottom: TabBar(
            indicatorColor: AppColors.advertencia, // Indicator in advertencia
            labelColor: AppColors.advertencia,
            unselectedLabelColor: AppColors.background,
            tabs: const [
              Tab(text: 'Resumen'),
              Tab(text: 'Marcas'),
              Tab(text: 'Historia'),
              Tab(text: 'Indicaciones'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            EjercicioResumen(ejercicio: ejercicio),
            EjercicioMarcas(ejercicio: ejercicio),
            EjercicioHistoria(ejercicio: ejercicio),
            EjercicioIndicaciones(ejercicio: ejercicio),
          ],
        ),
      ),
    );
  }
}
