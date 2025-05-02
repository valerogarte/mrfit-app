import 'package:flutter/services.dart';
import 'dart:async';

class HealthConnectHelper {
  static const MethodChannel _channel = MethodChannel('com.vagfit/health');

  static Future<bool> hasHealthDataPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('hasHealthDataPermission');
      print("HealthConnectHelper: hasHealthDataPermission: $hasPermission");
      return hasPermission;
    } catch (e) {
      print("HealthConnectHelper: Error in hasHealthDataPermission: $e");
      return false;
    }
  }

  static Future<bool> requestHealthDataPermission() async {
    final completer = Completer<bool>();
    _channel.setMethodCallHandler((call) async {
      if (call.method == "onPermissionResult") {
        print("HealthConnectHelper: onPermissionResult: ${call.arguments}");
        completer.complete(call.arguments as bool);
      }
    });
    try {
      print("HealthConnectHelper: Requesting permission...");
      await _channel.invokeMethod('requestHealthDataPermission');
    } catch (e) {
      print("HealthConnectHelper: Error in requestHealthDataPermission: $e");
      completer.complete(false);
    }
    return completer.future;
  }

  static Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } catch (e) {
      print("HealthConnectHelper: Error opening app settings: $e");
    }
  }
}
