import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'package:mrfit/models/rutina/sesion.dart';
import 'package:mrfit/screens/sesion/sesion_page.dart';
import 'package:mrfit/widgets/not_found/not_found.dart';
import 'package:mrfit/screens/entrenamiento/entrenadora.dart';
import 'package:mrfit/widgets/chart/pills_dificultad.dart';
import 'package:mrfit/utils/mr_functions.dart';

class RutinaListadoSesionesPage extends StatefulWidget {
  final Rutina rutina;
  const RutinaListadoSesionesPage({Key? key, required this.rutina}) : super(key: key);

  @override
  _RutinaListadoSesionesPageState createState() => _RutinaListadoSesionesPageState();
}

class _RutinaListadoSesionesPageState extends State<RutinaListadoSesionesPage> with RouteAware {
  List<Sesion> _listadoSesiones = [];
  final RouteObserver<PageRoute> _routeObserver = RouteObserver<PageRoute>();

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    Entrenadora().detener();
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _refrescarSesiones();
  }

  Future<void> _refrescarSesiones() async {
    final sesionesActualizadas = await widget.rutina.getSesiones();
    setState(() {
      _listadoSesiones = sesionesActualizadas;
    });
  }

  Future<void> _mostrarDialogoNuevaSesion() async {
    final Sesion? nuevaSesion = await showDialog<Sesion?>(
      context: context,
      builder: (context) {
        String nuevoTitulo = '';
        int dificultad = 1;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text('Nuevo Día de Entrenamiento', style: TextStyle(color: AppColors.textNormal)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Título de la sesión',
                      labelStyle: TextStyle(color: AppColors.textNormal),
                    ),
                    style: const TextStyle(color: AppColors.textNormal),
                    onChanged: (value) => nuevoTitulo = value,
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: AppColors.textNormal),
                            onPressed: dificultad > 1 ? () => setDialogState(() => dificultad--) : null,
                            splashRadius: 18,
                          ),
                          Row(
                            children: List.generate(
                                5,
                                (i) => GestureDetector(
                                      onTap: () => setDialogState(() => dificultad = i + 1),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1.0),
                                        width: 30,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: i < dificultad ? AppColors.accentColor : AppColors.appBarBackground,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    )),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: AppColors.textNormal),
                            onPressed: dificultad < 5 ? () => setDialogState(() => dificultad++) : null,
                            splashRadius: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nuevoTitulo.isNotEmpty) {
                      final Sesion sesionCreada = await widget.rutina.insertarSesion(nuevoTitulo, dificultad);
                      Navigator.pop(context, sesionCreada);
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (nuevaSesion != null) {
      setState(() {
        _listadoSesiones.add(nuevaSesion);
      });
    }
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
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                    onTap: () async {
                                      await sesion.getEjercicios();
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => SesionPage(sesion: sesion)),
                                      );
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
                                                    buildDificultadPills(sesion.dificultad, 6, 12),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                // Cambia Row por Wrap para evitar overflow en pantallas pequeñas
                                                Wrap(
                                                  spacing: 16,
                                                  runSpacing: 8,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.fitness_center, color: AppColors.textNormal, size: 20),
                                                        const SizedBox(width: 5),
                                                        FutureBuilder<int>(
                                                          future: sesion.getEjerciciosCount(),
                                                          builder: (context, snap) {
                                                            if (snap.connectionState == ConnectionState.waiting) {
                                                              return const Text("0 ejercicios", style: TextStyle(color: AppColors.textNormal));
                                                            }
                                                            return Text("${snap.data ?? 0} ejercicios", style: const TextStyle(color: AppColors.textNormal));
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.timer, color: AppColors.textNormal, size: 20),
                                                        const SizedBox(width: 5),
                                                        FutureBuilder<String>(
                                                          future: sesion.calcularTiempoEntrenamiento(),
                                                          builder: (context, snap) {
                                                            if (snap.connectionState == ConnectionState.waiting) {
                                                              return const Text("00:00", style: TextStyle(color: AppColors.textNormal));
                                                            }
                                                            return Text(snap.data ?? '00:00', style: const TextStyle(color: AppColors.textNormal));
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.calendar_today, color: AppColors.textNormal, size: 20),
                                                        const SizedBox(width: 5),
                                                        FutureBuilder<DateTime?>(
                                                          future: sesion.getTimeUltimoEntrenamiento(),
                                                          builder: (context, snap) {
                                                            if (snap.connectionState == ConnectionState.waiting) {
                                                              return const Text("Sin registro", style: TextStyle(color: AppColors.textNormal));
                                                            }
                                                            final date = snap.data;
                                                            if (date == null) {
                                                              return const Text("Sin registro", style: TextStyle(color: AppColors.textNormal));
                                                            }
                                                            final formatted = MrFunctions.formatTimeAgo(date);
                                                            return Text(formatted, style: const TextStyle(color: AppColors.textNormal));
                                                          },
                                                        ),
                                                      ],
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
