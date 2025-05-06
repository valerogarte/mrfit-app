part of 'usuario.dart';

extension UsuarioHealthExtension on Usuario {
  Future<bool> isHealthConnectAvailable() async {
    return await _health.isHealthConnectAvailable();
  }

  Future<void> installHealthConnect() async {
    await _health.installHealthConnect();
  }

  Future<bool> isHealthDataHistoryAvailable() async {
    return await _health.isHealthDataHistoryAvailable();
  }

  Future<bool> isHealthDataHistoryAuthorized() async {
    return await _health.isHealthDataHistoryAuthorized();
  }

  Future<bool> requestHealthDataHistoryAuthorization() async {
    return await _health.requestHealthDataHistoryAuthorization();
  }

  Future<bool> requestPermissions() async {
    try {
      await _health.configure();
      final requested = await _health.requestAuthorization(
        healthDataTypesString.values.toList(),
        permissions: healthDataPermissions.values.toList(),
      );
      return requested;
    } catch (e) {
      Logger().e("Error al pedir permisos HC: $e");
      return false;
    }
  }

  Future<bool> checkPermissions() async {
    await _health.configure();
    bool allGranted = true;
    for (var key in healthDataTypesString.keys) {
      final type = healthDataTypesString[key]!;
      final permission = healthDataPermissions[key]!;
      bool granted = await _health.hasPermissions([type], permissions: [permission]) ?? false;
      if (!granted) {
        Logger().w("Falta el permiso para $type con acceso $permission");
        allGranted = false;
      }
    }
    return allGranted;
  }

  Future<bool> checkPermissionsFor(String name) async {
    await _health.configure();
    final type = healthDataTypesString[name];
    if (type == null) {
      // Logger().e('Error: Tipo de dato no reconocido en código ($name)');
      return false;
    }
    final permission = healthDataPermissions[name];
    if (permission == null) {
      // Logger().e('Error: Permiso no configurado en código para el tipo ($name)');
      return false;
    }
    bool granted = await _health.hasPermissions([type], permissions: [permission]) ?? false;
    // Logger().d("UsuarioHealthExtension: checkPermissionsFor $name: $granted");
    return granted;
  }

  Future<List<HealthDataPoint>> _readHealthData(HealthDataType type, int nDays) async {
    final now = DateTime.now();
    final past = now.subtract(Duration(days: nDays));
    try {
      List<HealthDataPoint> results = await _health.getHealthDataFromTypes(
        startTime: past,
        endTime: now,
        types: [type],
      );
      return results;
    } catch (e) {
      return [];
    }
  }
}
