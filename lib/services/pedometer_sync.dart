import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mrfit/models/usuario/usuario.dart';

Future<void> initializePedometerService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: _onStart,
      onBackground: (_) async => true,
    ),
  );
  await service.startService();
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'Mr Fit',
      content: 'Registrando pasos...',
    );
  }

  final usuario = await Usuario.load();
  final isGranted = await Permission.activityRecognition.isGranted;
  if (!isGranted) {
    service.stopSelf();
    return;
  }

  int? lastSteps;
  StreamSubscription<StepCount>? sub;
  sub = Pedometer.stepCountStream.listen((event) async {
    lastSteps ??= event.steps;
    if (lastSteps == null) return;
    final delta = event.steps - lastSteps!;
    lastSteps = event.steps;
    if (delta > 0) {
      await usuario.addSteps(delta);
    }
  });

  service.on('stopService').listen((event) {
    sub?.cancel();
    service.stopSelf();
  });
}
