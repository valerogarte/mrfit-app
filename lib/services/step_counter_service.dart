import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:mrfit/models/usuario/usuario.dart';

/// Servicio dedicado a gestionar el conteo de pasos y su registro.
/// Agrupa los pasos y los inserta periódicamente para optimizar recursos.
class StepCounterService {
  static const Duration _batchDuration = Duration(minutes: 1);

  final Usuario usuario;
  final void Function(dynamic error)? onError;

  StreamSubscription<StepCount>? _stepCountSub;
  Timer? _flushTimer;
  int _lastStepsValue = 0;
  DateTime? _lastStepTime;

  int _pendingSteps = 0;
  DateTime? _pendingStartTime;
  DateTime? _pendingEndTime;

  StepCounterService({
    required this.usuario,
    this.onError,
  });

  void start() {
    _stepCountSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: onError,
    );
    _flushTimer = Timer.periodic(_batchDuration, (_) => _flushSteps());
  }

  void _onStepCount(StepCount event) {
    int currentSteps = event.steps;
    DateTime timestamp = event.timeStamp;

    if (_lastStepTime == null) {
      _lastStepsValue = currentSteps;
      _lastStepTime = timestamp;
      return;
    }
    int newSteps = currentSteps - _lastStepsValue;
    if (newSteps > 0) {
      _pendingSteps += newSteps;
      _pendingStartTime ??= _lastStepTime;
      _pendingEndTime = timestamp;
    }
    _lastStepsValue = currentSteps;
    _lastStepTime = timestamp;
  }

  void _flushSteps() {
    if (_pendingSteps > 0 && _pendingStartTime != null && _pendingEndTime != null) {
      usuario.healthconnectRegistrarPasos(_pendingSteps, _pendingStartTime!, _pendingEndTime!);
      _pendingSteps = 0;
      _pendingStartTime = null;
      _pendingEndTime = null;
    }
  }

  void dispose() {
    _stepCountSub?.cancel();
    _flushTimer?.cancel();
    _flushSteps();
  }
}
