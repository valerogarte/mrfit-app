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
import 'package:mrfit/screens/rutinas/rutinas_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class RutinaListadoSesionesPage extends ConsumerStatefulWidget {
  final Rutina rutina;
  const RutinaListadoSesionesPage({super.key, required this.rutina});

  @override
  ConsumerState<RutinaListadoSesionesPage> createState() => _RutinaListadoSesionesPageState();
}

class _RutinaListadoSesionesPageState extends ConsumerState<RutinaListadoSesionesPage> with RouteAware {
  List<Sesion> _listadoSesiones = [];
  final RouteObserver<PageRoute> _routeObserver = RouteObserver<PageRoute>();

  // Cache de futuros para evitar recargas innecesarias tras navegar
  final Map<int, Future<int>> _ejerciciosCountFutures = {};
  final Map<int, Future<String>> _tiempoEntrenamientoFutures = {};
  final Map<int, Future<DateTime?>> _ultimoEntrenamientoFutures = {};
  final Map<int, Future<int?>> _isEntrenandoFutures = {};

  late Usuario usuario;

  @override
  void initState() {
    super.initState();
    usuario = ref.read(usuarioProvider);
    _cargarSesionesYCache();
  }

  // Carga sesiones y cachea los futuros asociados
  Future<void> _cargarSesionesYCache() async {
    final sesiones = await widget.rutina.getSesiones();
    setState(() {
      _listadoSesiones = sesiones;
      _cachearFuturosSesiones(sesiones);
    });
  }

  // Cachea los futuros de cada sesión por id
  void _cachearFuturosSesiones(List<Sesion> sesiones) {
    for (final sesion in sesiones) {
      _ejerciciosCountFutures[sesion.id] = sesion.getEjerciciosCount();
      _tiempoEntrenamientoFutures[sesion.id] = sesion.calcularTiempoEntrenamiento();
      _ultimoEntrenamientoFutures[sesion.id] = sesion.getTimeUltimoEntrenamiento();
      _isEntrenandoFutures[sesion.id] = sesion.isEntrenandoAhora();
    }
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
      _cachearFuturosSesiones(sesionesActualizadas);
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
                      await FirebaseAnalytics.instance.logEvent(
                        name: 'dia_entrenamiento_creado',
                        parameters: {
                          'sesion_id': sesionCreada.id,
                          'sesion_titulo': sesionCreada.titulo,
                          'dificultad': dificultad,
                          'rutina_id': widget.rutina.id,
                          'rutina_titulo': widget.rutina.titulo,
                          'user': usuario.username,
                        },
                      );
                      // ignore: use_build_context_synchronously
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
        // Cachear futuros para la nueva sesión
        _ejerciciosCountFutures[nuevaSesion.id] = nuevaSesion.getEjerciciosCount();
        _tiempoEntrenamientoFutures[nuevaSesion.id] = nuevaSesion.calcularTiempoEntrenamiento();
        _ultimoEntrenamientoFutures[nuevaSesion.id] = nuevaSesion.getTimeUltimoEntrenamiento();
        _isEntrenandoFutures[nuevaSesion.id] = nuevaSesion.isEntrenandoAhora();
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
    final bool puedeAgregarSesion = widget.rutina.grupoId == 1 || widget.rutina.grupoId == 2;

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
                                        // ignore: use_build_context_synchronously
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SesionPage(
                                            sesion: sesion,
                                            rutina: widget.rutina,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        // Al volver, refrescar sesiones y cache
                                        await _refrescarSesiones();
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
                                                          future: _ejerciciosCountFutures[sesion.id],
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
                                                          future: _tiempoEntrenamientoFutures[sesion.id],
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
                                                          future: _ultimoEntrenamientoFutures[sesion.id],
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
                                    future: _isEntrenandoFutures[sesion.id],
                                    builder: (context, snap) {
                                      if (snap.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                                      return (snap.data ?? 0) > 0
                                          ? AnimatedContainer(
                                              duration: const Duration(seconds: 1),
                                              height: 4,
                                              color: Colors.orangeAccent,
                                            )
                                          : const SizedBox.shrink();
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
      floatingActionButton: puedeAgregarSesion
          ? SafeArea(
              child: FloatingActionButton(
                onPressed: _mostrarDialogoNuevaSesion,
                backgroundColor: AppColors.appBarBackground,
                child: const Icon(Icons.add, color: AppColors.background),
              ),
            )
          : null,
      bottomNavigationBar: !puedeAgregarSesion
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mutedAdvertencia,
                      foregroundColor: AppColors.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      // Duplica la rutina y navega a la página de rutinas
                      final rutinaNueva = await widget.rutina.duplicar();
                      await usuario.setRutinaActual(rutinaNueva.id);
                      if (!mounted) return;
                      // Navega a RutinasPage y elimina el stack hasta la raíz
                      // ignore: use_build_context_synchronously
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const RutinasPage()),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'Iniciar Rutina',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.background,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
