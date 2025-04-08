import 'package:flutter/material.dart';
import '../../../models/entrenamiento/entrenamiento.dart';
import '../../../models/rutina/sesion.dart';
import '../../sesion/sesion_page.dart'; // Asegúrate de la ruta correcta
import '../../../utils/colors.dart';
import '../entrenamiento_page.dart';
import '../../../widgets/animated_image.dart'; // Agregado para mostrar imagen

class EditarEntrenamientoPage extends StatelessWidget {
  final Entrenamiento entrenamiento;

  const EditarEntrenamientoPage({Key? key, required this.entrenamiento}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Entrenamiento',
          style: TextStyle(color: AppColors.background),
        ),
        backgroundColor: AppColors.advertencia,
        iconTheme: const IconThemeData(color: AppColors.background),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: entrenamiento.ejercicios.length,
        itemBuilder: (context, index) {
          final ej = entrenamiento.ejercicios[index];
          return Card(
            color: AppColors.cardBackground, // Se establece el color del encabezado
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navegar a detalles del ejercicio (opcional)
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedImage(
                      ejercicio: ej.ejercicio,
                      width: 105,
                      height: 70,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      ej.ejercicio.nombre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.whiteText, // Estilo de texto igual que en ejercicios_listado.dart
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () async {
              final updatedEntrenamiento = await Entrenamiento.loadById(entrenamiento.id);
              if (updatedEntrenamiento != null) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EntrenamientoPage(entrenamiento: updatedEntrenamiento),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.advertencia, // Updated to advertencia
            ),
            child: const Text(
              'Actualizar entrenamiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.background),
            ),
          ),
        ),
      ),
    );
  }
}
