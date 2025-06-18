import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import necesario para SystemUiOverlayStyle
import 'ejercicio_detalle_historia.dart';
import 'ejercicio_detalle_indicaciones.dart';
import 'ejercicio_detalle_marcas.dart';
import 'ejercicio_detalle_resumen.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/utils/colors.dart';

class EjercicioDetallePage extends StatelessWidget {
  final Ejercicio ejercicio;

  const EjercicioDetallePage({super.key, required this.ejercicio});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // Esto asegura que la status bar tenga el mismo color que el AppBar
        value: SystemUiOverlayStyle(
          statusBarColor: AppColors.background, // Color igual al AppBar
          statusBarIconBrightness: Brightness.dark, // Ajusta según contraste
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
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
          body: SafeArea(
            // SafeArea solo en el body para proteger el contenido inferior y superior
            child: TabBarView(
              children: [
                EjercicioResumen(ejercicio: ejercicio),
                EjercicioMarcas(ejercicio: ejercicio),
                EjercicioHistoria(ejercicio: ejercicio),
                EjercicioIndicaciones(ejercicio: ejercicio),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
