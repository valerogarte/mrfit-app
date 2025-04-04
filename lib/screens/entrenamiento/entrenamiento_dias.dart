import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/colors.dart';
import '../../models/rutina/rutina.dart';
import 'entrenadora.dart';
import '../../models/rutina/sesion.dart';
import '../sesion/sesion_page.dart';
import '../../widgets/blink_bar.dart';
import '../../widgets/not_found/not_found.dart';

class EntrenamientoDiasPage extends StatefulWidget {
  final Rutina rutina;

  const EntrenamientoDiasPage({
    Key? key,
    required this.rutina,
  }) : super(key: key);

  @override
  _EntrenamientoDiasPageState createState() => _EntrenamientoDiasPageState();
}

class _EntrenamientoDiasPageState extends State<EntrenamientoDiasPage> {
  List<Sesion> _listadoSesiones = [];

  @override
  void initState() {
    super.initState();
    widget.rutina.getSesiones().then((sesiones) {
      setState(() {
        _listadoSesiones = sesiones;
      });
    });
  }

  @override
  void dispose() {
    Entrenadora().detener();
    super.dispose();
  }

  Future<void> _mostrarDialogoNuevaSesion() async {
    String nuevoTitulo = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Nuevo Día de Entrenamiento', style: TextStyle(color: AppColors.whiteText)),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Título de la sesión',
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
                  final nuevaSesion = await widget.rutina.insertarSesion(nuevoTitulo);
                  setState(() {
                    _listadoSesiones.add(nuevaSesion);
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

  Future<void> _mostrarDialogoEditarSesion(Sesion sesion) async {
    String nuevoTitulo = sesion.titulo;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Editar Día de Entrenamiento', style: TextStyle(color: AppColors.whiteText)),
          content: TextField(
            decoration: const InputDecoration(labelText: 'Título de la sesión', labelStyle: TextStyle(color: AppColors.whiteText)),
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
                      title: const Text('Eliminar Día de Entrenamiento', style: TextStyle(color: AppColors.whiteText)),
                      content: const Text('¿Estás seguro de que deseas eliminar este día?', style: TextStyle(color: AppColors.whiteText)),
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
                  await sesion.delete();

                  setState(() {
                    _listadoSesiones.removeWhere((s) => s.id == sesion.id);
                  });
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
                  try {
                    await sesion.rename(nuevoTitulo);
                    setState(() {
                      sesion.titulo = nuevoTitulo;
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al actualizar el día de entrenamiento.')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _actualizarOrdenDiasEntrenamiento() async {
    for (var entry in _listadoSesiones.asMap().entries) {
      await entry.value.updateOrden(entry.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.rutina.titulo),
      ),
      body: _listadoSesiones.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: NotFoundData(
                title: 'Sin días de entrenamiento',
                textNoResults: 'Crea tu primer día de entrenamiento usando el botón "+".',
              ),
            )
          : ReorderableListView(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _listadoSesiones.removeAt(oldIndex);
                  _listadoSesiones.insert(newIndex, item);
                });
                _actualizarOrdenDiasEntrenamiento();
              },
              children: _listadoSesiones.asMap().entries.map((entry) {
                int index = entry.key;
                final sesion = entry.value;
                final titulo = sesion.titulo;

                return Card(
                  key: ValueKey(sesion.id),
                  color: AppColors.cardBackground,
                  margin: index == 0 ? const EdgeInsets.fromLTRB(16, 16, 16, 8) : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );
                            await sesion.getEjercicios();
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SesionPage(sesion: sesion),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        titulo,
                                        style: const TextStyle(
                                          color: AppColors.whiteText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.fitness_center, color: Colors.white54, size: 20),
                                          const SizedBox(width: 5),
                                          FutureBuilder<int>(
                                            future: sesion.getEjerciciosCount(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const BlinkingBar(width: 80, height: 16);
                                              } else if (snapshot.hasData) {
                                                return Text(
                                                  "${snapshot.data} ejercicios",
                                                  style: const TextStyle(color: AppColors.whiteText),
                                                );
                                              } else {
                                                return const Text("0 ejercicios", style: TextStyle(color: AppColors.whiteText));
                                              }
                                            },
                                          ),
                                          const SizedBox(width: 16),
                                          const Icon(Icons.timer, color: Colors.white54, size: 20),
                                          const SizedBox(width: 5),
                                          FutureBuilder<String>(
                                            future: sesion.calcularTiempoEntrenamiento(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const BlinkingBar(width: 80, height: 16);
                                              } else if (snapshot.hasError) {
                                                return const Text(
                                                  'Error',
                                                  style: TextStyle(color: AppColors.whiteText),
                                                );
                                              } else {
                                                return Text(
                                                  snapshot.data ?? '',
                                                  style: const TextStyle(color: AppColors.whiteText),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Replace PopupMenuButton with IconButton (lápiz)
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.whiteText),
                                  onPressed: () => _mostrarDialogoEditarSesion(sesion),
                                ),
                              ],
                            ),
                          ),
                        ),
                        FutureBuilder<int?>(
                          future: sesion.isEntrenandoAhora(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                            if (snapshot.hasData && snapshot.data != null && snapshot.data! > 0) {
                              return AnimatedContainer(
                                duration: const Duration(seconds: 1),
                                height: 4,
                                color: AppColors.advertencia,
                                curve: Curves.easeInOut,
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoNuevaSesion,
        backgroundColor: _listadoSesiones.isEmpty ? AppColors.advertencia : AppColors.accentColor,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }
}
