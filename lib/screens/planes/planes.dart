// rutinas.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entrenamiento/entrenamiento_dias.dart';
import '../../utils/colors.dart';
import '../../models/usuario/usuario.dart';
import '../../models/rutina/rutina.dart';
import '../../providers/usuario_provider.dart';
import '../../widgets/not_found/not_found.dart';

class PlanesPage extends ConsumerStatefulWidget {
  const PlanesPage({super.key});

  @override
  ConsumerState<PlanesPage> createState() => _PlanesPageState();
}

class _PlanesPageState extends ConsumerState<PlanesPage> {
  List<Rutina> rutinas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlanes();
  }

  Future<void> fetchPlanes() async {
    setState(() {
      isLoading = true;
    });
    final usuario = ref.read(usuarioProvider);
    final fetchedPlanes = await usuario.getRutinas();
    if (fetchedPlanes != null) {
      setState(() {
        rutinas = fetchedPlanes;
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cargar los datos.'),
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _mostrarDialogoNuevoPlan() async {
    String nuevoTitulo = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Nuevo Plan', style: TextStyle(color: AppColors.whiteText)),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Título del rutina',
              labelStyle: TextStyle(color: AppColors.whiteText),
            ),
            style: const TextStyle(color: AppColors.whiteText),
            onChanged: (value) {
              nuevoTitulo = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.whiteText)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nuevoTitulo.isNotEmpty) {
                  Navigator.pop(context);
                  final usuario = ref.read(usuarioProvider);
                  final nuevoPlan = await usuario.crearRutina(titulo: nuevoTitulo);
                  setState(() {
                    rutinas.add(nuevoPlan);
                  });
                }
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _eliminarRutina(String rutinaId) async {
    final rutina = rutinas.firstWhere((rutina) => rutina.id.toString() == rutinaId);
    final bool success = await rutina.delete();
    if (success) {
      setState(() {
        rutinas.removeWhere((rutina) => rutina.id.toString() == rutinaId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar el rutina.')),
      );
    }
  }

  Future<void> _mostrarDialogoEditarPlan(Rutina rutina) async {
    String nuevoTitulo = rutina.titulo;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Editar Plan', style: TextStyle(color: AppColors.whiteText)),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Título del rutina',
              labelStyle: TextStyle(color: AppColors.whiteText),
            ),
            style: const TextStyle(color: AppColors.whiteText),
            controller: TextEditingController(text: nuevoTitulo),
            onChanged: (value) {
              nuevoTitulo = value;
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.background),
              onPressed: () async {
                Navigator.pop(context);
                final confirmar = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: AppColors.cardBackground,
                      title: const Text('Eliminar Plan', style: TextStyle(color: AppColors.whiteText)),
                      content: const Text('¿Estás seguro de que deseas eliminar este rutina?', style: TextStyle(color: AppColors.whiteText)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancelar', style: TextStyle(color: AppColors.whiteText)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmar == true) {
                  await _eliminarRutina(rutina.id.toString());
                }
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.whiteText)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nuevoTitulo.isNotEmpty) {
                  Navigator.pop(context);
                  await rutina.rename(nuevoTitulo);
                  setState(() {
                    final index = rutinas.indexWhere((p) => p.id == rutina.id);
                    if (index != -1) {
                      rutinas[index] = Rutina(
                        id: rutina.id,
                        titulo: nuevoTitulo,
                        imagen: rutina.imagen,
                      );
                    }
                  });
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : rutinas.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: NotFoundData(
                      title: 'Sin rutinas',
                      textNoResults: 'Puedes crear la primera clicando en el botón del "+".',
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: rutinas.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final rutina = rutinas[index];
                    return Card(
                      color: AppColors.cardBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () async {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EntrenamientoDiasPage(
                                rutina: rutina,
                              ),
                            ),
                          );
                        },
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                rutina.titulo,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.whiteText,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white),
                                onPressed: () {
                                  _mostrarDialogoEditarPlan(rutina);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevoPlan,
        backgroundColor: rutinas.isEmpty ? AppColors.advertencia : AppColors.secondaryColor,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }
}
