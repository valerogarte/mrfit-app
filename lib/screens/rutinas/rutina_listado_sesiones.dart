import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'package:mrfit/models/rutina/sesion.dart';
import 'package:mrfit/screens/sesion/sesion_page.dart';
import 'package:mrfit/widgets/not_found/not_found.dart';
import 'package:mrfit/screens/entrenamiento/entrenadora.dart';
import 'package:mrfit/widgets/chart/pills_dificultad.dart';

class RutinaListadoSesionesPage extends StatefulWidget {
  final Rutina rutina;
  const RutinaListadoSesionesPage({Key? key, required this.rutina}) : super(key: key);

  @override
  _RutinaListadoSesionesPageState createState() => _RutinaListadoSesionesPageState();
}

class _RutinaListadoSesionesPageState extends State<RutinaListadoSesionesPage> {
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
          title: const Text('Nuevo Día de Entrenamiento', style: TextStyle(color: AppColors.textNormal)),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Título de la sesión',
              labelStyle: TextStyle(color: AppColors.textNormal),
            ),
            style: const TextStyle(color: AppColors.textNormal),
            onChanged: (value) => nuevoTitulo = value,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal))),
            ElevatedButton(
              onPressed: () async {
                if (nuevoTitulo.isNotEmpty) {
                  Navigator.pop(context);
                  final nuevaSesion = await widget.rutina.insertarSesion(nuevoTitulo);
                  setState(() => _listadoSesiones.add(nuevaSesion));
                }
              },
              child: const Text('Crear'),
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
      body: _listadoSesiones.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: NotFoundData(
                title: 'Sin días de entrenamiento',
                textNoResults: 'Crea tu primer día de entrenamiento usando el botón "+".',
              ),
            )
          : Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              // Se elimina el color de fondo, será transparente por defecto
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SingleChildScrollView(
                  child: ReorderableListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _listadoSesiones.removeAt(oldIndex);
                        _listadoSesiones.insert(newIndex, item);
                      });
                      _actualizarOrdenDiasEntrenamiento();
                    },
                    proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, child: child),
                    children: [
                      ..._listadoSesiones.asMap().entries.map((entry) {
                        final sesion = entry.value;
                        return Container(
                          key: ValueKey(sesion.id),
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: AppColors.cardBackground,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                                      await sesion.getEjercicios();
                                      Navigator.pop(context);
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => SesionPage(sesion: sesion)),
                                      );
                                      // Si se editó o eliminó, recargar la lista
                                      if (result == true) {
                                        final sesionesActualizadas = await widget.rutina.getSesiones();
                                        setState(() {
                                          _listadoSesiones = sesionesActualizadas;
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        sesion.titulo,
                                                        style: const TextStyle(
                                                          color: AppColors.textNormal,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Dificultad pills
                                                    buildDificultadPills(sesion.dificultad, 6, 12),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.fitness_center, color: AppColors.textNormal, size: 20),
                                                    const SizedBox(width: 5),
                                                    FutureBuilder<int>(
                                                      future: sesion.getEjerciciosCount(),
                                                      builder: (context, snap) {
                                                        // Cambiado: mostrar "0 ejercicios" mientras carga
                                                        if (snap.connectionState == ConnectionState.waiting) {
                                                          return const Text("0 ejercicios", style: TextStyle(color: AppColors.textNormal));
                                                        }
                                                        return Text("${snap.data ?? 0} ejercicios", style: const TextStyle(color: AppColors.textNormal));
                                                      },
                                                    ),
                                                    const SizedBox(width: 16),
                                                    const Icon(Icons.timer, color: AppColors.textNormal, size: 20),
                                                    const SizedBox(width: 5),
                                                    FutureBuilder<String>(
                                                      future: sesion.calcularTiempoEntrenamiento(),
                                                      builder: (context, snap) {
                                                        // Cambiado: mostrar "00:00" mientras carga
                                                        if (snap.connectionState == ConnectionState.waiting) {
                                                          return const Text("00:00", style: TextStyle(color: AppColors.textNormal));
                                                        }
                                                        return Text(snap.data ?? '00:00', style: const TextStyle(color: AppColors.textNormal));
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  FutureBuilder<int?>(
                                    future: sesion.isEntrenandoAhora(),
                                    builder: (context, snap) {
                                      if (snap.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                                      return (snap.data ?? 0) > 0 ? AnimatedContainer(duration: const Duration(seconds: 1), height: 4, color: Colors.orangeAccent) : const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(key: ValueKey('padding'), height: 100),
                    ],
                  ),
                ),
              ),
            ),
      floatingActionButton: SafeArea(
        child: FloatingActionButton(
          onPressed: _mostrarDialogoNuevaSesion,
          backgroundColor: AppColors.accentColor,
          child: const Icon(Icons.add, color: AppColors.background),
        ),
      ),
    );
  }
}
