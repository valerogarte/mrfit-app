import 'dart:async';
import 'dart:convert';
import 'package:pedometer/pedometer.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/models/cache/custom_cache.dart';

/// Servicio dedicado a gestionar el conteo de pasos y su registro.
/// Agrupa los pasos y los inserta periódicamente para optimizar recursos.
class StepCounterService {
  static const Duration _batchDuration = Duration(minutes: 1);
  static const String _cacheKey = 'step_counter_last';

  final Usuario usuario;
  final void Function(dynamic error)? onError;
  final void Function(bool walking)? onStatusChanged;

  StreamSubscription<StepCount>? _stepCountSub;
  StreamSubscription<PedestrianStatus>? _statusSub;
  Timer? _flushTimer;
  int _lastStepsValue = 0;
  DateTime? _lastStepTime;
  bool _isWalking = false;
  bool get isWalking => _isWalking;

  int _pendingSteps = 0;
  DateTime? _pendingStartTime;
  DateTime? _pendingEndTime;

  Future<void> _loadLastInfo() async {
    final cache = await CustomCache.getByKey(_cacheKey);
    if (cache != null) {
      try {
        final data = jsonDecode(cache.value) as Map<String, dynamic>;
        _lastStepsValue = data['value'] as int? ?? 0;
        final timeStr = data['time'] as String?;
        if (timeStr != null && timeStr.isNotEmpty) {
          _lastStepTime = DateTime.tryParse(timeStr);
        }
      } catch (_) {}
    }
  }

  Future<void> _persistLastInfo() async {
    await CustomCache.set(
      _cacheKey,
      jsonEncode({
        'value': _lastStepsValue,
        'time': _lastStepTime?.toIso8601String() ?? '',
      }),
    );
  }

  StepCounterService({
    required this.usuario,
    this.onError,
    this.onStatusChanged,
  });

  Future<void> start() async {
    await _loadLastInfo();
    _stepCountSub = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: onError,
    );
    _statusSub = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatus,
      onError: (_) {},
    );
    _flushTimer = Timer.periodic(_batchDuration, (_) => _flushSteps());
  }

  void _onStepCount(StepCount event) {
    final currentSteps = event.steps;
    final timestamp = event.timeStamp;

    if (_lastStepTime == null) {
      _lastStepsValue = currentSteps;
      _lastStepTime = timestamp;
      return;
    }

    int newSteps = currentSteps - _lastStepsValue;
    if (newSteps < 0) {
      // El contador se reinició (posible reinicio del dispositivo)
      newSteps = currentSteps;
      _pendingStartTime = timestamp;
    }
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
    _persistLastInfo();
  }

  void _onPedestrianStatus(PedestrianStatus status) {
    final walking = status == PedestrianStatus.walking;
    _isWalking = walking;
    onStatusChanged?.call(walking);
  }

  void dispose() {
    _stepCountSub?.cancel();
    _statusSub?.cancel();
    _flushTimer?.cancel();
    _flushSteps();
    _persistLastInfo();
  }
}
