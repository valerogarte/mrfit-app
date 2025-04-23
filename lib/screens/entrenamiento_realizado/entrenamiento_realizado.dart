import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/widgets/entrenamiento/entrenamiento_resumen_series.dart';
import 'package:mrfit/widgets/entrenamiento/entrenamiento_resumen_pastilla.dart';
import 'package:mrfit/main.dart';

class EntrenamientoRealizadoPage extends StatelessWidget {
  final dynamic idHealthConnect;
  const EntrenamientoRealizadoPage({super.key, required this.idHealthConnect});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Entrenamiento?>(
      future: Entrenamiento.loadByUuid(idHealthConnect),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cargando entrenamiento...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.mutedRed, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar el entrenamiento',
                    style: TextStyle(fontSize: 18, color: AppColors.mutedAdvertencia),
                  ),
                  Text('${snapshot.error}', style: const TextStyle(color: AppColors.mutedRed)),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('No encontrado')),
            body: const Center(child: Text('Entrenamiento no encontrado')),
          );
        }
        final entrenamiento = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(entrenamiento.titulo),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'Borrar') {
                    await entrenamiento.delete();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MyHomePage()),
                      (route) => false,
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'Borrar',
                    child: Text('Borrar'),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entrenamiento.formatTimeAgo(), style: const TextStyle(fontSize: 18)),
                ResumenPastilla(entrenamiento: entrenamiento),
                const SizedBox(height: 20),
                // Sensación del entrenamiento
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.mutedAdvertencia, width: 1),
                  ),
                  child: Text(
                    ModeloDatos.getSensacionText(entrenamiento.sensacion.toDouble()),
                    style: const TextStyle(color: AppColors.mutedAdvertencia, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center, // Center align the text
                  ),
                ),
                const SizedBox(height: 20),
                // Resumen de ejercicios
                ...entrenamiento.ejercicios.map((ejercicio) {
                  if (ejercicio.countSeriesRealizadas() == 0) return const SizedBox.shrink();
                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ejercicio.ejercicio.nombre,
                          style: const TextStyle(color: AppColors.whiteText, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ejercicio.series.asMap().entries.map((entry) {
                        final index = entry.key;
                        final serie = entry.value;
                        return ResumenSerie(index: index, serie: serie, pesoUsuario: entrenamiento.pesoUsuario);
                      }).toList(),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
