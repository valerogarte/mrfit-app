import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/main.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/widgets/entrenamiento/entrenamiento_resumen_series.dart';
import 'package:mrfit/widgets/entrenamiento/entrenamiento_resumen_pastilla.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/models/usuario/usuario.dart';

class FinalizarPage extends ConsumerStatefulWidget {
  final Entrenamiento entrenamiento;

  const FinalizarPage({super.key, required this.entrenamiento});

  @override
  ConsumerState<FinalizarPage> createState() => _FinalizarPageState();
}

class _FinalizarPageState extends ConsumerState<FinalizarPage> {
  late ConfettiController _controllerLeft;
  late ConfettiController _controllerRight;
  double _ratingValue = 0; // Default rating value (Normal)
  bool _isUpdatingMrPoints = true;
  int _dotCount = 0;
  Timer? _dotTimer;

  @override
  void initState() {
    super.initState();
    // Initialize the confetti controllers
    _controllerLeft = ConfettiController(duration: const Duration(seconds: 5));
    _controllerRight = ConfettiController(duration: const Duration(seconds: 5));

    // Start the confetti animation when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controllerLeft.play();
      _controllerRight.play();
    });

    // Inicia la animación de puntos progresivos
    _dotTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        _dotCount = (_dotCount + 1) % 3; // ciclo: 0,1,2
      });
    });

    final usuario = ref.read(usuarioProvider);
    usuario.updateMrPointsFromEntrenamiento(widget.entrenamiento).then((_) {
      setState(() {
        _isUpdatingMrPoints = false;
      });
      _dotTimer?.cancel();
      _dotTimer = null;
    });
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    // Dispose the controllers when the widget is disposed
    _controllerLeft.dispose();
    _controllerRight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entrenamiento.titulo),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 60, color: AppColors.mutedAdvertencia),
                  const SizedBox(height: 20),
                  const Text(
                    '¡Entrenamiento completado!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textNormal),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    '¿Cómo ha ido el entrenamiento?',
                    style: TextStyle(fontSize: 16, color: AppColors.textNormal),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Desastre', style: TextStyle(color: AppColors.textNormal, fontSize: 12)),
                            Text('Normal', style: TextStyle(color: AppColors.textNormal, fontSize: 12)),
                            Text('Increíble', style: TextStyle(color: AppColors.textNormal, fontSize: 12)),
                          ],
                        ),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.mutedAdvertencia,
                          inactiveTrackColor: AppColors.mutedAdvertencia,
                          thumbColor: AppColors.mutedAdvertencia,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _ratingValue,
                          min: -3,
                          max: 3,
                          divisions: 6,
                          onChanged: (value) {
                            setState(() {
                              _ratingValue = value;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          ModeloDatos.getSensacionText(_ratingValue),
                          style: const TextStyle(color: AppColors.mutedAdvertencia, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ResumenPastilla(entrenamiento: widget.entrenamiento),
                  const SizedBox(height: 30),
                  Column(
                    children: widget.entrenamiento.ejercicios.map((ejercicio) {
                      if (ejercicio.countSeriesRealizadas() == 0) return const SizedBox.shrink();
                      return ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ejercicio.ejercicio.nombre,
                              style: const TextStyle(color: AppColors.textNormal, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: ejercicio.series.asMap().entries.map((entry) {
                            final index = entry.key;
                            final serie = entry.value;
                            return ResumenSerie(index: index, serie: serie, pesoUsuario: widget.entrenamiento.pesoUsuario);
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Left top confetti - placed at the end of Stack to be on top
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _controllerLeft,
              blastDirection: 0.5, // slightly downward to the right
              emissionFrequency: 0.05,
              numberOfParticles: 3,
              maxBlastForce: 30,
              minBlastForce: 15,
              gravity: 0.1,
              shouldLoop: false,
              minimumSize: const Size(4, 4), // much smaller particles
              maximumSize: const Size(6, 6), // much smaller particles
              colors: const [
                AppColors.mutedAdvertencia,
                AppColors.mutedRed,
                AppColors.appBarBackground,
                AppColors.mutedRed,
                AppColors.mutedAdvertencia,
                AppColors.textMedium,
              ],
            ),
          ),

          // Right top confetti - placed at the end of Stack to be on top
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _controllerRight,
              blastDirection: 2.6, // slightly downward to the left
              emissionFrequency: 0.05,
              numberOfParticles: 3,
              maxBlastForce: 30,
              minBlastForce: 15,
              gravity: 0.1,
              shouldLoop: false,
              minimumSize: const Size(4, 4),
              maximumSize: const Size(6, 6),
              colors: const [
                AppColors.mutedAdvertencia,
                AppColors.mutedRed,
                AppColors.appBarBackground,
                AppColors.accentColor,
                AppColors.mutedAdvertencia,
                AppColors.textMedium,
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: AppColors.mutedAdvertencia,
          ),
          onPressed: _isUpdatingMrPoints
              ? null
              : () async {
                  await widget.entrenamiento.setSensacion(_ratingValue.toInt());
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MyHomePage()),
                    (Route<dynamic> route) => false,
                  );
                },
          child: Text(
            _isUpdatingMrPoints ? 'Actualizando Datos${'.' * (_dotCount + 1)}' : 'Continuar',
            style: TextStyle(fontSize: 18, color: _isUpdatingMrPoints ? AppColors.mutedAdvertencia : AppColors.background),
          ),
        ),
      ),
    );
  }
}
