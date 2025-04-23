part of 'usuario.dart';

extension UsuarioHealthExtension on Usuario {
  Future<bool> requestPermissions() async {
    await _health.configure();
    final bool requested = await _health.requestAuthorization(
      healthDataTypesString.values.toList(),
      permissions: healthDataPermissions.values.toList(),
    );
    return requested;
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
      Logger().e('Error: Tipo de dato no reconocido en código ($name)');
      return false;
    }
    final permission = healthDataPermissions[name];
    if (permission == null) {
      Logger().e('Error: Permiso no configurado en código para el tipo ($name)');
      return false;
    }
    bool granted = await _health.hasPermissions([type], permissions: [permission]) ?? false;
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
