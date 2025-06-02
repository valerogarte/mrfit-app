import 'package:flutter/material.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/screens/ejercicios/buscar/ejercicios_buscar.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/animated_image.dart';

class EditarEntrenamientoPage extends StatefulWidget {
  final Entrenamiento entrenamiento;

  const EditarEntrenamientoPage({super.key, required this.entrenamiento});

  @override
  EditarEntrenamientoPageState createState() => EditarEntrenamientoPageState();
}

class EditarEntrenamientoPageState extends State<EditarEntrenamientoPage> {
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
      body: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20.0),
        ),
        clipBehavior: Clip.hardEdge,
        child: ReorderableListView(
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) newIndex -= 1;
              final item = widget.entrenamiento.ejercicios.removeAt(oldIndex);
              widget.entrenamiento.ejercicios.insert(newIndex, item);
              for (var i = 0; i < widget.entrenamiento.ejercicios.length; i++) {
                widget.entrenamiento.ejercicios[i].setPesoOrden(i);
              }
            });
          },
          children: [
            for (int index = 0; index < widget.entrenamiento.ejercicios.length; index++)
              Card(
                key: ValueKey(widget.entrenamiento.ejercicios[index].id),
                color: AppColors.cardBackground,
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Navegar a detalles del ejercicio (opcional)
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
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
                        padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
                        child: Text(
                          widget.entrenamiento.ejercicios[index].ejercicio.nombre,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textNormal,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppColors.mutedRed,
                      onPressed: () {
                        final ejercicioARemover = widget.entrenamiento.ejercicios[index];
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.cardBackground,
                            title: const Text(
                              '¿Estás seguro?',
                              style: TextStyle(color: AppColors.textNormal),
                            ),
                            content: const Text(
                              'Vas a eliminar este ejercicio.',
                              style: TextStyle(color: AppColors.textMedium),
                            ),
                            actions: [
                              TextButton(
                                child: const Text(
                                  'Cancelar',
                                  style: TextStyle(color: AppColors.mutedSilver),
                                ),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                              TextButton(
                                child: const Text(
                                  'Confirmar',
                                  style: TextStyle(color: AppColors.mutedRed, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  await ejercicioARemover.delete();
                                  setState(() {
                                    widget.entrenamiento.ejercicios.remove(ejercicioARemover);
                                  });
                                  // ignore: use_build_context_synchronously
                                  Navigator.of(ctx).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EjerciciosBuscarPage(
                    entrenamiento: widget.entrenamiento,
                  ),
                ),
              );
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.mutedAdvertencia,
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
