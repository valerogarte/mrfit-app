import 'package:flutter/material.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/animated_image.dart';

class EditarEntrenamientoPage extends StatefulWidget {
  final Entrenamiento entrenamiento;

  const EditarEntrenamientoPage({Key? key, required this.entrenamiento}) : super(key: key);

  @override
  _EditarEntrenamientoPageState createState() => _EditarEntrenamientoPageState();
}

class _EditarEntrenamientoPageState extends State<EditarEntrenamientoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Editar Entrenamiento',
          style: TextStyle(color: AppColors.background),
        ),
        backgroundColor: AppColors.mutedAdvertencia,
        iconTheme: const IconThemeData(color: AppColors.background),
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = widget.entrenamiento.ejercicios.removeAt(oldIndex);
            widget.entrenamiento.ejercicios.insert(newIndex, item);
            // Actualizar el peso de cada ejercicio según su posición
            for (var i = 0; i < widget.entrenamiento.ejercicios.length; i++) {
              widget.entrenamiento.ejercicios[i].setPesoOrden(i);
            }
          });
        },
        children: [
          for (int index = 0; index < widget.entrenamiento.ejercicios.length; index++)
            Card(
              key: ValueKey(widget.entrenamiento.ejercicios[index].id),
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
                        ejercicio: widget.entrenamiento.ejercicios[index].ejercicio,
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
                        '${widget.entrenamiento.ejercicios[index].ejercicio.nombre} - ${widget.entrenamiento.ejercicios[index].pesoOrden}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textNormal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () async {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.mutedAdvertencia, // Updated to advertencia
            ),
            child: const Text(
              'Añadir Ejercicio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.background),
            ),
          ),
        ),
      ),
    );
  }
}
