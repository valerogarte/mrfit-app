import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:mrfit/models/usuario/usuario.dart';

class StepCounterService {
  static const _channel = MethodChannel('background_step_counter');

  final Usuario usuario;
  final void Function(dynamic error)? onError;
  final void Function(bool walking)? onStatusChanged;
  StreamSubscription<PedestrianStatus>? _statusSub;

  StepCounterService({
    required this.usuario,
    this.onError,
    this.onStatusChanged,
  });

  Future<void> start() async {
    // print('[StepCounterService] start() called.');
    // 1) Escuchar status para el icono de “andando”
    _statusSub?.cancel(); // Cancelar suscripción anterior si existe
    _statusSub = Pedometer.pedestrianStatusStream.listen(
      (s) {
        final isWalking = s.status == 'walking';
        // print('[StepCounterService] Pedestrian status changed: ${s.status}. Is walking: $isWalking');
        onStatusChanged?.call(isWalking);
      },
      onError: (error) {
        // print('[StepCounterService] Error in pedestrianStatusStream: $error');
        onError?.call(error);
      },
    );

    // 2) Registrar callback nativo para pasos
    // print('[StepCounterService] Setting MethodCallHandler...');
    _channel.setMethodCallHandler((call) async {
      // print('[StepCounterService] Received method call from native: ${call.method}');
      if (call.method == 'registerSteps') {
        final pasos = call.arguments as int;
        final fin = DateTime.now();
        // Se asume que los pasos son del último minuto, como en el servicio nativo.
        final inicio = fin.subtract(const Duration(minutes: 1));
        // print('[StepCounterService] registerSteps: $pasos pasos from $inicio to $fin');
        usuario.healthconnectRegistrarPasos(pasos, inicio, fin);
      }
    });
    // print('[StepCounterService] MethodCallHandler set.');

    // 3) Arrancar el foreground service en el lado nativo
    try {
      // print('[StepCounterService] Invoking native startStepCounter...');
      await _channel.invokeMethod('startStepCounter');
      // print('[StepCounterService] Native startStepCounter invoked successfully.');
    } catch (e) {
      // print('[StepCounterService] Error invoking startStepCounter: $e');
      onError?.call(e);
    }
  }

  Future<void> stopService() async {
    // print('[StepCounterService] stopService() called.');
    await _statusSub?.cancel();
    _statusSub = null;
    try {
      // print('[StepCounterService] Invoking native stopStepCounter...');
      await _channel.invokeMethod('stopStepCounter');
      // print('[StepCounterService] Native stopStepCounter invoked successfully.');
    } catch (e) {
      // print('[StepCounterService] Error invoking stopStepCounter: $e');
      onError?.call(e);
      // Incluso si hay un error, intentamos limpiar el handler
      _channel.setMethodCallHandler(null);
      // print('[StepCounterService] MethodCallHandler cleared due to error in stopService.');
    }
    // Limpiar el handler después de detener el servicio exitosamente también
    _channel.setMethodCallHandler(null);
    // print('[StepCounterService] MethodCallHandler cleared after stopService.');
  }

  /// Cancela las suscripciones locales sin detener el servicio nativo.
  void dispose() {
    // print('[StepCounterService] dispose() called.');
    _statusSub?.cancel();
    _statusSub = null;
    // No se detiene el servicio nativo aquí para permitir que siga en background.
    // El MethodCallHandler se mantiene para recibir pasos si el servicio sigue corriendo.
    // Si se quisiera limpiar el handler al hacer dispose de esta instancia de servicio Dart:
    // _channel.setMethodCallHandler(null);
    // print('[StepCounterService] MethodCallHandler potentially cleared in dispose (if uncommented).');
  }
}
