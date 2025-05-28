part of 'usuario.dart';

extension UsuarioHealthExtension on Usuario {
  Future<bool> isHealthConnectAvailableUser() async {
    final hc = await _health.isHealthConnectAvailable();
    return setHealthConnectAvaliable(hc);
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

  /// Lee los datos de salud para un tipo específico en los últimos [nDays] días,
  /// y los devuelve ordenados de más antiguo a más moderno.
  Future<List<HealthDataPoint>> _readHealthDataFromNDaysAgoToNow(HealthDataType type, int nDays) async {
    final now = DateTime.now();
    final past = now.subtract(Duration(days: nDays));
    try {
      List<HealthDataPoint> results = await _health.getHealthDataFromTypes(
        startTime: past,
        endTime: now,
        types: [type],
      );
      // Ordena los resultados por fecha de más antiguo a más moderno
      results.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
      return results;
    } catch (e) {
      // En caso de error, retorna una lista vacía
      return [];
    }
  }

  /// Lee los datos de salud para un tipo específico en una fecha dada,
  /// desde las 00:00 hasta las 23:59:59 de ese día.
  Future<List<HealthDataPoint>> _readHealthDataByDate(HealthDataType type, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      List<HealthDataPoint> results = await _health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: endOfDay,
        types: [type],
      );
      return results;
    } catch (e) {
      // En caso de error, retorna una lista vacía
      return [];
    }
  }
}
