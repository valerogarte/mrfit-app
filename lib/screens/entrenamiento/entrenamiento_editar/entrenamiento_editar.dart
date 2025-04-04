import 'package:flutter/material.dart';
import '../../../models/entrenamiento/entrenamiento.dart';
import '../../../models/rutina/sesion.dart';
import '../../sesion/sesion_page.dart'; // Asegúrate de la ruta correcta
import '../../../utils/colors.dart';
import '../entrenamiento_page.dart'; // Added import

class EditarEntrenamientoPage extends StatelessWidget {
  final Entrenamiento entrenamiento;

  const EditarEntrenamientoPage({Key? key, required this.entrenamiento}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Entrenamiento'),
        backgroundColor: AppColors.accentColor,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('En construcción', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            // Button Row: Salir and Guardar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final sesionLoaded = await Sesion.loadById(entrenamiento.sesion);
                    if (sesionLoaded != null) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SesionPage(sesion: sesionLoaded),
                        ),
                        (route) => false, // Clear all previous routes
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentColor),
                  child: const Text('Salir'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    final updatedEntrenamiento = await Entrenamiento.loadById(entrenamiento.id);
                    if (updatedEntrenamiento != null) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EntrenamientoPage(entrenamiento: updatedEntrenamiento),
                        ),
                        (route) => false, // Clear all previous routes
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentColor),
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
