import 'package:flutter/material.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/models/rutina/ejercicio_personalizado.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/widgets/animated_image.dart';
import 'package:mrfit/widgets/series_item.dart';
import 'package:mrfit/screens/entrenamiento/entrenamiento_page.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/screens/ejercicios/detalle/ejercicio_detalle.dart';
import 'package:mrfit/screens/ejercicios/buscar/ejercicios_buscar.dart';
import 'package:mrfit/screens/entrenamiento/entrenadora.dart';
import 'package:mrfit/models/rutina/sesion.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/widgets/pills_dificultad.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/widgets/not_found/not_found.dart';

part 'ejercicios_listado_serie.dart';

class EjerciciosListadoPage extends ConsumerStatefulWidget {
  final Sesion sesion;

  const EjerciciosListadoPage({
    Key? key,
    required this.sesion,
  }) : super(key: key);

  @override
  ConsumerState<EjerciciosListadoPage> createState() => _EjerciciosListadoPageState();
}

class _EjerciciosListadoPageState extends ConsumerState<EjerciciosListadoPage> with TickerProviderStateMixin {
  late List<EjercicioPersonalizado> _ejercicios;
  dynamic idEntrenandoAhora;

  @override
  void initState() {
    super.initState();
    _initializeSesion();
    _checkEntrenandoStatus();
  }

  void _initializeSesion() {
    _ejercicios = widget.sesion.ejerciciosPersonalizados ?? [];
    widget.sesion.getEjerciciosCount().then((count) {
      setState(() {});
    });
  }

  Future<void> _checkEntrenandoStatus() async {
    final status = await widget.sesion.isEntrenandoAhora();
    setState(() {
      idEntrenandoAhora = status ?? 0;
    });
  }

  Future<void> _mostrarBusquedaEjercicios() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EjerciciosBuscarPage(
          sesion: widget.sesion,
        ),
      ),
    );
    await _fetchSesionCompleta();
  }

  Future<void> _fetchSesionCompleta() async {
    final ejercicios = await widget.sesion.getEjercicios();
    if (mounted) {
      setState(() {
        _ejercicios = ejercicios;
      });
    }
  }

  void _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final movedItem = _ejercicios.removeAt(oldIndex);
      _ejercicios.insert(newIndex, movedItem);
    });
    for (int i = 0; i < _ejercicios.length; i++) {
      await _ejercicios[i].setOrden(i.toDouble());
    }
    setState(() {});
  }

  Future<void> _agregarSerieAlEjercicioEnRutina(EjercicioPersonalizado ejercicioPersonalizado) async {
    await ejercicioPersonalizado.insertSeriePersonalizada();
    await ejercicioPersonalizado.getSeriesPersonalizadas();
  }

  void _openActionSheet(EjercicioPersonalizado ejercicioPersonalizado) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) {
        int? expandedSetIndex;
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.3,
          maxChildSize: 1,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, localSetState) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Series',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.whiteText,
                              ),
                            ),
                            FutureBuilder<List<dynamic>>(
                              future: Future.wait([ejercicioPersonalizado.calcularTiempo(), ejercicioPersonalizado.calcularVolumen()]),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                                  return const SizedBox();
                                } else {
                                  final int tiempo = snapshot.data![0] as int;
                                  final double volumen = snapshot.data![1] as double;
                                  final String tiempoFormateado = _formatDuration(Duration(seconds: tiempo));
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timer, color: AppColors.advertencia, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        tiempoFormateado,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.whiteText,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.fitness_center, color: AppColors.advertencia, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$volumen kg',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.whiteText,
                                        ),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      ListView.builder(
                        controller: scrollController,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ejercicioPersonalizado.countSeriesPersonalizadas(),
                        itemBuilder: (context, setIndex) {
                          final serieP = ejercicioPersonalizado.seriesPersonalizadas?[setIndex];
                          if (serieP != null) {
                            return SeriesItem(
                              key: ValueKey(serieP.id),
                              setIndex: setIndex,
                              serieP: serieP,
                              ejercicioP: ejercicioPersonalizado,
                              isExpanded: (expandedSetIndex == setIndex),
                              onToggleExpand: () {
                                localSetState(() {
                                  expandedSetIndex = expandedSetIndex == setIndex ? null : setIndex;
                                });
                              },
                              onDelete: () async {
                                setState(() => ejercicioPersonalizado.seriesPersonalizadas?.removeAt(setIndex));
                                localSetState(() {});
                              },
                              onSave: () async {
                                await ejercicioPersonalizado.getSeriesPersonalizadas();
                                localSetState(() {});
                              },
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                      _buildSeriesControls(ejercicioPersonalizado, localSetState),
                      _buildPromedioSeries(ejercicioPersonalizado),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    Entrenadora().detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Stack(
      children: [
        if (_ejercicios.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const NotFoundData(
              title: 'No hay ejercicios',
              textNoResults: 'Agrega ejercicios para comenzar.',
            ),
          )
        else
          Column(
            children: [
              Expanded(
                child: ReorderableListView(
                  onReorder: _onReorder,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      color: AppColors.advertencia,
                      child: child,
                    );
                  },
                  padding: const EdgeInsets.only(bottom: 80),
                  children: List.generate(_ejercicios.length, (index) {
                    final ejercicio = _ejercicios[index];
                    return Container(
                      key: ValueKey(ejercicio.id),
                      margin: EdgeInsets.only(
                        top: index == 0 ? 10.0 : 6.0,
                        bottom: 4.0,
                        left: 12.0,
                        right: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildExerciseHeader(index, ejercicio),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              _buildTrainingButton(),
            ],
          ),
        Positioned(
          bottom: (_ejercicios.isEmpty) ? 16 : 90,
          right: 16,
          child: FloatingActionButton(
            onPressed: _mostrarBusquedaEjercicios,
            backgroundColor: (_ejercicios.isEmpty || _ejercicios.any((e) => e.countSeriesPersonalizadas() == 0)) ? AppColors.advertencia : AppColors.secondaryColor,
            child: const Icon(Icons.add, color: AppColors.background),
          ),
        ),
      ],
    ));
  }

  Widget _buildExerciseHeader(int index, EjercicioPersonalizado ejercicioPersonalizado) {
    final ejercicio = ejercicioPersonalizado.ejercicio;
    int seriesCount = _ejercicios[index].countSeriesPersonalizadas();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _navigateToExerciseDetail(ejercicio),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: AnimatedImage(
                  ejercicio: ejercicioPersonalizado.ejercicio,
                  width: 105,
                  height: 70,
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Icon(
                  Icons.info_outline,
                  color: AppColors.advertencia,
                  size: 16,
                  shadows: [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 3.0,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => _openActionSheet(ejercicioPersonalizado),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Transform.translate(
                          offset: const Offset(0, -4), // desplaza 3px hacia arriba
                          child: Text(
                            ejercicio.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.whiteText,
                            ),
                            maxLines: 3, // Modificado de 2 a 3
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          buildDificultadPills(ejercicio, 6, 12),
                          const SizedBox(height: 8),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: Container(
                                  width: 40,
                                  child: Text(
                                    '$seriesCount',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: seriesCount == 0 ? AppColors.advertencia : AppColors.textColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: Transform.translate(
                                  offset: const Offset(0, 10),
                                  child: SizedBox(
                                    width: 40,
                                    child: Text(
                                      'series',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: seriesCount == 0 ? AppColors.advertencia : AppColors.textColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToExerciseDetail(Ejercicio ejercicio) async {
    final updatedExercise = await Ejercicio.loadById(ejercicio.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EjercicioDetallePage(ejercicio: updatedExercise),
      ),
    );
  }

  Widget _buildTrainingButton() {
    if (_ejercicios.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_ejercicios.any((e) => e.countSeriesPersonalizadas() == 0)) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.advertencia.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.advertencia),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Agrega series al ejercicio pulsando sobre él. Toca la imagen para ver detalles.",
                  style: TextStyle(color: AppColors.whiteText),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _handleTrainingButton,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          backgroundColor: (idEntrenandoAhora != null && idEntrenandoAhora > 0) ? AppColors.advertencia : AppColors.accentColor,
        ),
        child: Text(
          (idEntrenandoAhora != null && idEntrenandoAhora > 0) ? 'Continuar' : 'Comenzar entrenamiento',
          style: TextStyle(
            fontSize: 18,
            color: (idEntrenandoAhora != null && idEntrenandoAhora > 0) ? AppColors.background : AppColors.whiteText,
          ),
        ),
      ),
    );
  }

  Future<void> _handleTrainingButton() async {
    int currentTraining = idEntrenandoAhora ?? 0;
    Entrenamiento? entrenamiento;
    if (currentTraining > 0) {
      entrenamiento = await Entrenamiento.loadById(currentTraining);
    } else {
      final usuario = ref.read(usuarioProvider);
      entrenamiento = await widget.sesion.empezarEntrenamiento(usuario);
    }

    setState(() {
      idEntrenandoAhora = entrenamiento?.id ?? 0;
    });
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntrenamientoPage(entrenamiento: entrenamiento!),
      ),
    );
    if (mounted) await _checkEntrenandoStatus();
  }
}
