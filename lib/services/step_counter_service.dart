import 'dart:async';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:intl/intl.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter/widgets.dart';
import 'dart:io' show Platform;

/// Service that records steps using the pedometer plugin.
/// It saves the daily steps in [SharedPreferences] so they are
/// available even when the app is not running.
class StepCounterService {
  static StreamSubscription<StepCount>? _subscription;

  /// Requests the necessary activity recognition permission.
  static Future<bool> _ensurePermission() async {
    if (Platform.isIOS) {
      final status = await Permission.sensors.request();
      return status.isGranted;
    }
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  /// Initializes the alarm manager and starts listening for step events.
  static Future<void> initialize() async {
    if (!await _ensurePermission()) return;
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
      // Launch a periodic background task to keep the pedometer active.
      await AndroidAlarmManager.periodic(
        const Duration(minutes: 15),
        // Identifier for this alarm.
        1001,
        backgroundCallback,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      final service = FlutterBackgroundService();
      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: backgroundCallback,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'mrfit_steps',
          initialNotificationTitle: 'MrFit',
          initialNotificationContent: 'Contando pasos en segundo plano',
          foregroundServiceNotificationId: 888,
        ),
        iosConfiguration: const IosConfiguration(),
      );
      await service.startService();
    }

    start();
  }

  /// Starts listening to the pedometer stream in the main isolate.
  static void start() {
    _subscription ??=
        Pedometer.stepCountStream.listen(_onStepCount, onError: _onError);
  }

  /// Stops listening to the pedometer stream.
  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  @pragma('vm:entry-point')
  static Future<void> backgroundCallback([ServiceInstance? service]) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: 'MrFit',
        content: 'Contando pasos',
      );
    }

    if (!await _ensurePermission()) return;
    Pedometer.stepCountStream.listen(_onStepCount, onError: _onError);
  }

  static Future<void> _onStepCount(StepCount event) async {
    await _saveSteps(event.steps, event.timeStamp);
  }

  static void _onError(error) {
    // Ignore errors from the pedometer plugin.
  }

  static Future<void> _saveSteps(int steps, DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final storedDate = prefs.getString('steps_date');
    if (storedDate != todayKey) {
      await prefs.setString('steps_date', todayKey);
      await prefs.setInt('pedometer_base', steps);
      await prefs.setInt('daily_steps', 0);
      return;
    }
    final base = prefs.getInt('pedometer_base') ?? steps;
    await prefs.setInt('daily_steps', steps - base);
  }

  /// Returns the current step count for today.
  static Future<int> getDailySteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('daily_steps') ?? 0;
  }
}
