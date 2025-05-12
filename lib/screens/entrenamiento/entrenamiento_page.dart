import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mrfit/models/entrenamiento/ejercicio_realizado.dart';
import 'package:mrfit/models/entrenamiento/serie_realizada.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/widgets/animated_image.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/screens/ejercicios/detalle/ejercicio_detalle.dart';
import 'finalizar.dart';
import 'entrenamiento_series/entrenamiento_series.dart';
import 'entrenadora.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'entrenamiento_editar/entrenamiento_editar.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/models/usuario/usuario.dart';

class EntrenamientoPage extends ConsumerStatefulWidget {
  final Entrenamiento entrenamiento;

  const EntrenamientoPage({Key? key, required this.entrenamiento}) : super(key: key);

  @override
  ConsumerState<EntrenamientoPage> createState() => _EntrenamientoPageState();
}

class _EntrenamientoPageState extends ConsumerState<EntrenamientoPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Entrenadora _entrenadora = Entrenadora(); // Use singleton instance
  final Map<String, TextEditingController> _repsControllers = {};
  final Map<String, TextEditingController> _weightControllers = {};
  final Map<String, bool> _expandedStates = {};
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late Usuario usuario; // Add a variable to hold the user instance

  // Variables para el temporizador
  DateTime? _inicio; // Fecha y hora de inicio del entrenamiento
  Duration _elapsedTime = Duration.zero; // Tiempo transcurrido
  Timer? _timer; // Temporizador que se actualiza cada segundo
  bool _readFirstExerciseDescription = false;
  bool _isResting = false;
  int? _restingTimeLeft;
  Timer? _restTimer;
  bool restartEntrenadora = false;
  bool _finalizado = false; // Flag para ocultar controles

  @override
  void initState() {
    super.initState();

    // initialize usuario early so build() can read it
    usuario = ref.read(usuarioProvider);

    // Habilitar la lectura
    _entrenadora.reanudar();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ir al primer ejercicio incompleto
      _animateToFirstIncompleteExercise();
    });

    // Parsear la fecha de inicio del entrenamiento
    _inicio = widget.entrenamiento.inicio.toUtc();

    // Inicializar el tiempo transcurrido
    final now = DateTime.now().toUtc();
    _elapsedTime = now.difference(_inicio!);

    // Iniciar el temporizador que se actualiza cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final now = DateTime.now().toUtc();
          _elapsedTime = now.difference(_inicio!);
        });
      }
    });

    // Inicializa controladores de texto y estados de expansión para cada serie en cada ejercicio
    for (int exerciseIndex = 0; exerciseIndex < widget.entrenamiento.countEjercicios(); exerciseIndex++) {
      final ejercicio = widget.entrenamiento.ejercicios[exerciseIndex];
      final seriesNoBorradas = ejercicio.getSeriesNoBorradas();
      for (int setIndex = 0; setIndex < seriesNoBorradas.length; setIndex++) {
        final set = seriesNoBorradas[setIndex];
        final String repsKey = '$exerciseIndex-${set.id}-reps';
        final String weightKey = '$exerciseIndex-${set.id}-weight';
        final String expandedKey = '$exerciseIndex-${set.id}-expanded';

        _repsControllers[repsKey] = TextEditingController(text: set.repeticiones.toString());
        _weightControllers[weightKey] = TextEditingController(text: set.peso.toString());

        // Expandir si no está realizada, colapsar si está realizada
        _expandedStates[expandedKey] = !(set.realizada == true);
      }
    }

    // Load the user instance and configure Entrenadora
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entrenadora.configure(
        aviso10Segundos: usuario.aviso10Segundos,
        avisoCuentaAtras: usuario.avisoCuentaAtras,
        entrenadorVoz: usuario.entrenadorVoz,
        entrenadorVolumen: usuario.entrenadorVolumen,
      );
      if (usuario.entrenadorActivo) {
        _leerEntrenamiento();
      }
    });
  }

  Future<void> _animateToFirstIncompleteExercise({bool hasToAnimate = false}) async {
    for (int index = 0; index < widget.entrenamiento.countEjercicios(); index++) {
      final ejercicio = widget.entrenamiento.ejercicios[index];
      final allSeriesCompleted = ejercicio.isAllSeriesRealizadas();

      if (!allSeriesCompleted) {
        if (!mounted) return;
        setState(() {
          _currentIndex = index;
        });

        // only jump/animate when controller is attached
        if (_pageController.hasClients) {
          if (hasToAnimate) {
            await _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
          } else {
            _pageController.jumpToPage(_currentIndex);
          }
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              if (hasToAnimate) {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              } else {
                _pageController.jumpToPage(_currentIndex);
              }
            }
          });
        }
        break;
      }
    }
  }

  void _setInicioNextSeries() {
    for (int index = 0; index < widget.entrenamiento.countEjercicios(); index++) {
      final ejercicio = widget.entrenamiento.ejercicios[index];
      final allSeriesCompleted = ejercicio.isAllSeriesRealizadas();

      if (!allSeriesCompleted) {
        final series = ejercicio.getSeriesNoBorradas();
        for (int i = 0; i < series.length; i++) {
          final serie = series[i];
          if (!serie.realizada) {
            serie.setInicio();
          }
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    _entrenadora.detener(); // Detener TTS al pulsar atrás
    return true; // Permitir la navegación hacia atrás
  }

  @override
  void dispose() {
    // Cancelar el temporizador cuando se destruya el widget
    _timer?.cancel();
    _restTimer?.cancel();

    // Limpia controladores de texto y paginador
    _pageController.dispose();
    _repsControllers.values.forEach((controller) => controller.dispose());
    _weightControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      String hours = twoDigits(duration.inHours);
      return "$hours:$minutes:$seconds";
    } else {
      return "$minutes:$seconds";
    }
  }

  Future<void> _leerEntrenamiento() async {
    final ejercicios = widget.entrenamiento.ejercicios;

    // INTRODUCCIÓN
    _animateToFirstIncompleteExercise();
    await _entrenadora.leerInicioEntrenamiento(widget.entrenamiento, ejercicios[_currentIndex]);

    // EJERCICIOS
    for (int index = _currentIndex; index < ejercicios.length; index++) {
      final ejercicio = ejercicios[index];
      final validSeries = (ejercicio.series).where((serie) => serie.deleted == false).toList();

      // LEER DESCRIPCIÓN
      if (!_readFirstExerciseDescription && validSeries.any((serie) => serie.realizada == false)) {
        await _entrenadora.leerDescripcion(ejercicio);
        if (mounted) {
          _readFirstExerciseDescription = true;
        }
      }

      // LEER SERIES
      for (var serieR in validSeries) {
        if (!serieR.realizada) {
          if (!await _entrenadora.waitWhileInterrupted()) return;

          serieR.setInicio();

          // Contar repeticiones
          await _entrenadora.contarRepeticiones(serieR, ejercicio);

          if (!await _entrenadora.waitWhileInterrupted()) return;

          // Simular "serie completada"
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                serieR.realizada = true;
              });
            }
          });

          if (!await _entrenadora.waitWhileInterrupted()) return;

          final String expandedKey = '$index-${serieR.id}-expanded';
          if (mounted) {
            setState(() {
              _expandedStates[expandedKey] = false;
            });
          }

          if (!await _entrenadora.waitWhileInterrupted()) return;

          await serieR.setRealizada();

          if (!await _entrenadora.waitWhileInterrupted()) return;

          // Descanso si no es la última serie del último ejercicio
          if (index != ejercicios.length - 1 || ejercicio.series.indexOf(serieR) != ejercicio.series.length - 1) {
            if (mounted) {
              setState(() {
                _isResting = true;
                _restingTimeLeft = serieR.descanso;
              });
            }
            _restTimer?.cancel();
            _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (_entrenadora.isPaused) return;
              if (_restingTimeLeft == null || _restingTimeLeft! <= 1) {
                timer.cancel();
                if (mounted) {
                  setState(() {
                    _isResting = false;
                    _restingTimeLeft = 0;
                  });
                }
              } else {
                if (mounted) {
                  setState(() {
                    _restingTimeLeft = _restingTimeLeft! - 1;
                  });
                }
              }
            });

            // Si es la última serie
            if (ejercicio.series.indexOf(serieR) == ejercicio.series.length - 1) {
              _animateToFirstIncompleteExercise(hasToAnimate: true);
            }

            await _entrenadora.realizarDescanso(
              serieR,
              ejercicio.series.indexOf(serieR),
              ejercicio.series.length,
              ejercicios,
              index,
            );

            if (mounted) {
              setState(() {
                _isResting = false;
                _restingTimeLeft = 0;
              });
            }
            _restTimer?.cancel();
          }
        }
        _entrenadora.setSaltarDescanso(false);
      }

      if (!await _entrenadora.waitWhileInterrupted()) return;

      // Si hay que terminar el entrenamiento
      if (index == widget.entrenamiento.countEjercicios() - 1) {
        restartEntrenadora = true;
        setState(() {
          _finalizado = true;
        });
        _entrenadora.anunciarFinalizacion(widget.entrenamiento);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ejercicios = widget.entrenamiento.ejercicios;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          appBar: AppBar(
            leadingWidth: 100,
            automaticallyImplyLeading: false,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón de retroceso: agregado _entrenadora.detener() antes de Navigator.pop
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _entrenadora.detener();
                    Navigator.pop(context);
                  },
                ),
                // Botón de edición
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.mutedAdvertencia),
                  onPressed: () {
                    _entrenadora.detener();
                    restartEntrenadora = true;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditarEntrenamientoPage(entrenamiento: widget.entrenamiento),
                      ),
                    );
                  },
                ),
              ],
            ),
            title: Text(_formatDuration(_elapsedTime)),
            actions: usuario.entrenadorActivo && !_finalizado
                ? [
                    IconButton(
                      icon: Icon(
                        restartEntrenadora ? Icons.restart_alt : (_entrenadora.isPaused ? Icons.play_arrow : Icons.pause),
                        color: restartEntrenadora ? AppColors.mutedAdvertencia : (_entrenadora.isPaused ? AppColors.textNormal : AppColors.textMedium),
                      ),
                      onPressed: () {
                        setState(() {
                          if (restartEntrenadora) {
                            _restTimer?.cancel();
                            _isResting = false;
                            restartEntrenadora = false;
                            _entrenadora = Entrenadora();
                            _entrenadora.reanudar();
                            _leerEntrenamiento();
                          } else {
                            if (_entrenadora.isPaused) {
                              _entrenadora.reanudar();
                            } else {
                              _entrenadora.pausar();
                            }
                          }
                        });
                      },
                    ),
                  ]
                : [],
          ),
          body: Column(
            children: [
              // Bullets
              Container(
                padding: const EdgeInsets.only(bottom: 8.0),
                color: AppColors.background,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    ejercicios.length,
                    (index) {
                      final ejercicio = ejercicios[index];
                      final series = (ejercicio.series).where((s) => s.deleted == false).toList();
                      final allSeriesCompleted = series.every((s) => s.realizada == true);

                      // Determinar el color del bullet
                      Color bulletColor;
                      if (index == _currentIndex) {
                        bulletColor = AppColors.textNormal; // Ejercicio actual
                      } else if (allSeriesCompleted) {
                        bulletColor = AppColors.accentColor; // Ejercicio completado
                      } else if (index < _currentIndex && !allSeriesCompleted) {
                        bulletColor = AppColors.mutedAdvertencia; // Ejercicio anterior incompleto
                      } else {
                        bulletColor = AppColors.textMedium; // Ejercicio pendiente
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        height: 10,
                        width: _currentIndex == index ? 20 : 10,
                        decoration: BoxDecoration(
                          color: bulletColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Paginador + contenido
              Expanded(
                child: PageView.builder(
                  padEnds: false,
                  itemCount: ejercicios.length,
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final ejercicio = ejercicios[index];
                    return buildEjercicio(ejercicio, index);
                  },
                ),
              ),
            ],
          ),

          // Sección inferior que ocupa el 100% del ancho en lugar de FAB flotantes
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón de finalizar, izquierda
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mutedAdvertencia,
                      foregroundColor: AppColors.cardBackground,
                    ),
                    icon: const Icon(Icons.flag, color: AppColors.cardBackground),
                    label: const Text("Finalizar"),
                    onPressed: () async {
                      await _entrenadora.detener();
                      // Obtener el usuario desde el provider
                      final usuario = ref.read(usuarioProvider);
                      await widget.entrenamiento.finalizar(usuario);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FinalizarPage(entrenamiento: widget.entrenamiento),
                        ),
                      );
                    },
                  ),

                  // Botón de descanso (solo se muestra si _isResting == true)
                  if (_isResting)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.appBarBackground,
                      ),
                      onPressed: () {
                        _setInicioNextSeries();
                        setState(() {
                          _restTimer?.cancel();
                          _isResting = false;
                          _restingTimeLeft = 0;
                          _entrenadora.setSaltarDescanso(true);
                        });
                        _entrenadora.reanudar();
                      },
                      icon: const Icon(Icons.fast_forward, color: AppColors.mutedAdvertencia),
                      label: TweenAnimationBuilder<double>(
                        key: ValueKey(_restingTimeLeft),
                        tween: Tween<double>(begin: 1.5, end: 1.0),
                        duration: const Duration(seconds: 1),
                        builder: (context, scaleValue, child) {
                          return Transform.scale(
                            scale: scaleValue,
                            child: Text(
                              '${_restingTimeLeft ?? 0}s',
                              style: const TextStyle(color: AppColors.mutedAdvertencia),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Botón de añadir serie, derecha
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.appBarBackground,
                    ),
                    icon: const Icon(Icons.add, color: AppColors.textMedium),
                    label: const Text("Serie"),
                    onPressed: () async {
                      final currentEjercicio = widget.entrenamiento.ejercicios[_currentIndex];
                      await currentEjercicio.insertSerieRealizada();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEjercicio(EjercicioRealizado ejercicioR, int exerciseIndex) {
    final List<SerieRealizada> filteredSeries = ejercicioR.series.where((s) => s.deleted == false).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Título del ejercicio + imagen con icono de información
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EjercicioDetallePage(
                          ejercicio: ejercicioR.ejercicio,
                        ),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                        child: AnimatedImage(
                          ejercicio: ejercicioR.ejercicio,
                          width: 150,
                          height: 100,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Icon(
                          Icons.info_outline,
                          color: AppColors.mutedAdvertencia,
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
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0, bottom: 0.0),
                    child: Text(
                      ejercicioR.ejercicio.nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Series filtradas
          Column(
            children: filteredSeries.asMap().entries.map<Widget>((entry) {
              int seriesIndex = entry.key;
              final serie = entry.value;

              final String repsKey = '$exerciseIndex-${serie.id}-reps';
              final String weightKey = '$exerciseIndex-${serie.id}-weight';
              final String expandedKey = '$exerciseIndex-${serie.id}-expanded';

              _repsControllers[repsKey] ??= TextEditingController(text: serie.repeticiones.toString());
              _weightControllers[weightKey] ??= TextEditingController(text: serie.peso.toString());
              _expandedStates[expandedKey] ??= !serie.realizada;

              return EntrenamientoSeries(
                key: ValueKey('${serie.id}-${serie.realizada}'),
                setIndex: (seriesIndex + 1).toString(),
                set: serie,
                repsController: _repsControllers[repsKey]!,
                weightController: _weightControllers[weightKey]!,
                isExpanded: _expandedStates[expandedKey]!,
                onExpand: () {
                  setState(() {
                    _expandedStates[expandedKey] = true;
                  });
                },
                onCollapse: () {
                  setState(() {
                    _expandedStates[expandedKey] = false;
                  });
                },
                onDelete: () async {
                  await serie.delete();
                  final ejercicios = widget.entrenamiento.ejercicios;
                  final quedanSeries = ejercicios.any((ej) => ej.series.any((s) => !s.deleted && !s.realizada));
                  if (!quedanSeries && mounted) {
                    setState(() {
                      _finalizado = true;
                    });
                  }
                  setState(() {
                    int originalIndex = ejercicioR.series.indexWhere((s) => s.id == serie.id);
                    if (originalIndex != -1) {
                      ejercicioR.series[originalIndex].deleted = true;
                    }
                    _repsControllers.remove('$exerciseIndex-${serie.id}-reps');
                    _weightControllers.remove('$exerciseIndex-${serie.id}-weight');
                    _expandedStates.remove('$exerciseIndex-${serie.id}-expanded');
                  });
                },
                onUpdate: () async {
                  // Pulsa en Actualizar Set
                  serie.updateRepesPeso();
                  setState(() {
                    _expandedStates[expandedKey] = false;
                  });
                },
                onComplete: () async {
                  // Pulsa en Set Completo
                  serie.setRealizada();
                  _setInicioNextSeries();
                  _entrenadora.detener();
                  if (mounted) {
                    setState(() {
                      serie.realizada = true;
                      _expandedStates[expandedKey] = false;
                      _restTimer?.cancel();
                      _isResting = true;
                      _restingTimeLeft = serie.descanso;
                      // Se activa el estado restartEntrenadora
                      restartEntrenadora = true;
                    });
                  }
                  _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                    if (_restingTimeLeft == null || _restingTimeLeft! <= 1) {
                      timer.cancel();
                      if (mounted) {
                        setState(() {
                          _isResting = false;
                          _restingTimeLeft = 0;
                        });
                      }
                    } else {
                      if (mounted) {
                        setState(() {
                          _restingTimeLeft = _restingTimeLeft! - 1;
                        });
                      }
                      if (_restingTimeLeft != null && _restingTimeLeft! <= 3 && _restingTimeLeft! > 0) {
                        Vibration.vibrate(duration: 300);
                      }
                      if (_restingTimeLeft != null && _restingTimeLeft! == 10) {
                        Vibration.vibrate(duration: 1000);
                      }

                      // Busco la siguiente serie y seteo su inicio
                      if (_restingTimeLeft == 1) {
                        _setInicioNextSeries();
                      }
                    }
                  });

                  final ejercicios = widget.entrenamiento.ejercicios;
                  final quedanSeries = ejercicios.any((ej) => ej.series.any((s) => !s.deleted && !s.realizada));
                  if (!quedanSeries && mounted) {
                    setState(() {
                      _finalizado = true;
                    });
                  }
                },
                ejercicioRealizado: ejercicioR,
              );
            }).toList(),
          ),
          const SizedBox(height: 50.0),
        ],
      ),
    );
  }
}
