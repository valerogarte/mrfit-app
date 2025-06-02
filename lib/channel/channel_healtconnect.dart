import 'package:flutter/services.dart';
import 'dart:async';
import 'package:logger/logger.dart';

class HealthConnectHelper {
  static const MethodChannel _channel = MethodChannel('es.mrfit.app/health');

  static Future<bool> hasHealthDataPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('hasHealthDataPermission');
      return hasPermission;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestHealthDataPermission() async {
    final completer = Completer<bool>();
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onPermissionResult") {
        completer.complete(call.arguments as bool);
      }
    });
    try {
      await _channel.invokeMethod('requestHealthDataPermission');
    } catch (e) {
      completer.complete(false);
    }
    return completer.future;
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      Logger().e("HealthConnectHelper: Error opening app settings: $e");
    }
  }
}
