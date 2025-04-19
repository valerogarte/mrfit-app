part of 'usuario.dart';

extension UsuarioHealthExtension on Usuario {
  // Map de tipos compatibles para Health Connect
  Map<String, HealthDataType> get healthDataTypesString => {
        "ACTIVE_ENERGY_BURNED": HealthDataType.ACTIVE_ENERGY_BURNED,
        "BLOOD_GLUCOSE": HealthDataType.BLOOD_GLUCOSE,
        "BLOOD_OXYGEN": HealthDataType.BLOOD_OXYGEN,
        "BLOOD_PRESSURE_DIASTOLIC": HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        "BLOOD_PRESSURE_SYSTOLIC": HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        "BODY_FAT_PERCENTAGE": HealthDataType.BODY_FAT_PERCENTAGE,
        "LEAN_BODY_MASS": HealthDataType.LEAN_BODY_MASS,
        "BODY_MASS_INDEX": HealthDataType.BODY_MASS_INDEX,
        "BODY_TEMPERATURE": HealthDataType.BODY_TEMPERATURE,
        "BODY_WATER_MASS": HealthDataType.BODY_WATER_MASS,
        "HEART_RATE": HealthDataType.HEART_RATE,
        "HEART_RATE_VARIABILITY_RMSSD": HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        "HEIGHT": HealthDataType.HEIGHT,
        "STEPS": HealthDataType.STEPS,
        "WEIGHT": HealthDataType.WEIGHT,
        "DISTANCE_DELTA": HealthDataType.DISTANCE_DELTA,
        "SLEEP_ASLEEP": HealthDataType.SLEEP_ASLEEP,
        "SLEEP_AWAKE_IN_BED": HealthDataType.SLEEP_AWAKE_IN_BED,
        "SLEEP_AWAKE": HealthDataType.SLEEP_AWAKE,
        "SLEEP_DEEP": HealthDataType.SLEEP_DEEP,
        "SLEEP_LIGHT": HealthDataType.SLEEP_LIGHT,
        "SLEEP_OUT_OF_BED": HealthDataType.SLEEP_OUT_OF_BED,
        "SLEEP_REM": HealthDataType.SLEEP_REM,
        "SLEEP_SESSION": HealthDataType.SLEEP_SESSION,
        "SLEEP_UNKNOWN": HealthDataType.SLEEP_UNKNOWN,
        "WATER": HealthDataType.WATER,
        "WORKOUT": HealthDataType.WORKOUT,
        "RESTING_HEART_RATE": HealthDataType.RESTING_HEART_RATE,
        "FLIGHTS_CLIMBED": HealthDataType.FLIGHTS_CLIMBED,
        "BASAL_ENERGY_BURNED": HealthDataType.BASAL_ENERGY_BURNED,
        "RESPIRATORY_RATE": HealthDataType.RESPIRATORY_RATE,
        "NUTRITION": HealthDataType.NUTRITION,
        "TOTAL_CALORIES_BURNED": HealthDataType.TOTAL_CALORIES_BURNED,
        "MENSTRUATION_FLOW": HealthDataType.MENSTRUATION_FLOW,
      };

  Map<String, HealthDataAccess> get healthDataPermissions => {
        "ACTIVE_ENERGY_BURNED": HealthDataAccess.READ_WRITE,
        "BLOOD_GLUCOSE": HealthDataAccess.READ_WRITE,
        "BLOOD_OXYGEN": HealthDataAccess.READ_WRITE,
        "BLOOD_PRESSURE_DIASTOLIC": HealthDataAccess.READ_WRITE,
        "BLOOD_PRESSURE_SYSTOLIC": HealthDataAccess.READ_WRITE,
        "BODY_FAT_PERCENTAGE": HealthDataAccess.READ_WRITE,
        "LEAN_BODY_MASS": HealthDataAccess.READ_WRITE,
        "BODY_MASS_INDEX": HealthDataAccess.READ_WRITE,
        "BODY_TEMPERATURE": HealthDataAccess.READ_WRITE,
        "BODY_WATER_MASS": HealthDataAccess.READ_WRITE,
        "HEART_RATE": HealthDataAccess.READ_WRITE,
        "HEART_RATE_VARIABILITY_RMSSD": HealthDataAccess.READ_WRITE,
        "HEIGHT": HealthDataAccess.READ_WRITE,
        "STEPS": HealthDataAccess.READ_WRITE,
        "WEIGHT": HealthDataAccess.READ_WRITE,
        "DISTANCE_DELTA": HealthDataAccess.READ_WRITE,
        "SLEEP_ASLEEP": HealthDataAccess.READ_WRITE,
        "SLEEP_AWAKE_IN_BED": HealthDataAccess.READ_WRITE,
        "SLEEP_AWAKE": HealthDataAccess.READ_WRITE,
        "SLEEP_DEEP": HealthDataAccess.READ_WRITE,
        "SLEEP_LIGHT": HealthDataAccess.READ_WRITE,
        "SLEEP_OUT_OF_BED": HealthDataAccess.READ_WRITE,
        "SLEEP_REM": HealthDataAccess.READ_WRITE,
        "SLEEP_SESSION": HealthDataAccess.READ_WRITE,
        "SLEEP_UNKNOWN": HealthDataAccess.READ_WRITE,
        "WATER": HealthDataAccess.READ_WRITE,
        "WORKOUT": HealthDataAccess.READ_WRITE,
        "RESTING_HEART_RATE": HealthDataAccess.READ_WRITE,
        "FLIGHTS_CLIMBED": HealthDataAccess.READ_WRITE,
        "BASAL_ENERGY_BURNED": HealthDataAccess.READ_WRITE,
        "RESPIRATORY_RATE": HealthDataAccess.READ_WRITE,
        "NUTRITION": HealthDataAccess.READ_WRITE,
        "TOTAL_CALORIES_BURNED": HealthDataAccess.READ_WRITE,
        "MENSTRUATION_FLOW": HealthDataAccess.READ_WRITE,
      };

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
