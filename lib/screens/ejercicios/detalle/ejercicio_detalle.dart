import 'package:flutter/material.dart';
import 'ejercicio_detalle_resumen.dart';
import 'ejercicio_detalle_marcas.dart';
import 'ejercicio_detalle_historia.dart';
import 'ejercicio_detalle_indicaciones.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/utils/colors.dart'; // Import colors

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
          elevation: 0,
          backgroundColor: AppColors.background,
          title: Text(ejercicio.nombre),
          bottom: TabBar(
            dividerColor: Colors.transparent,
            indicatorWeight: 0,
            indicator: BoxDecoration(),
            indicatorColor: Colors.transparent,
            labelColor: AppColors.mutedAdvertencia,
            unselectedLabelColor: AppColors.accentColor,
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
