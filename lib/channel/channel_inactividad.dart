import 'package:flutter/services.dart';

class UsageStats {
  static const MethodChannel _channel = MethodChannel('com.vagfit/usage_stats');

  static Future<bool> hasUsageStatsPermission() async {
    final bool hasPermission = await _channel.invokeMethod('hasUsageStatsPermission');
    return hasPermission;
  }

  static Future<void> openUsageStatsSettings() async {
    await _channel.invokeMethod('openUsageStatsSettings');
  }

  /// Solicita al código nativo todos los slots de inactividad del día indicado.
  /// El día se debe enviar en formato "yyyy-MM-dd".
  /// Cada slot es un mapa con:
  /// - "start": minuto relativo al inicio del día,
  /// - "end": minuto relativo al inicio del día,
  /// - "duration": duración en minutos.
  static Future<List<dynamic>> getInactivitySlots(String day) async {
    final List<dynamic> slots = await _channel.invokeMethod('getInactivitySlots', {'day': day});
    return slots;
  }
}
