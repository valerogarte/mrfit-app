part of 'usuario.dart';

extension UsuarioHealthExtension on Usuario {
  // Map de tipos compatibles para Health Connect
  Map<String, HealthDataType> get healthDataTypesString => {
        "HEART_RATE": HealthDataType.HEART_RATE,
        "HEIGHT": HealthDataType.HEIGHT,
        "WEIGHT": HealthDataType.WEIGHT,
        "STEPS": HealthDataType.STEPS,
        // Solo Health Connect
        "TOTAL_CALORIES_BURNED": HealthDataType.TOTAL_CALORIES_BURNED,
        // No funciona
        // "ACTIVE_ENERGY_BURNED": HealthDataType.ACTIVE_ENERGY_BURNED,
        // Solo IOS
        // "GENDER": HealthDataType.GENDER,
        // "BIRTH_DATE": HealthDataType.BIRTH_DATE,
      };

  // Map de permisos asociados a cada tipo
  Map<String, HealthDataAccess> get healthDataPermissions => {
        "HEART_RATE": HealthDataAccess.READ_WRITE,
        "HEIGHT": HealthDataAccess.READ_WRITE,
        "WEIGHT": HealthDataAccess.READ_WRITE,
        "STEPS": HealthDataAccess.READ_WRITE,
        "TOTAL_CALORIES_BURNED": HealthDataAccess.READ_WRITE,
        // No funciona
        // "ACTIVE_ENERGY_BURNED": HealthDataAccess.READ_WRITE,
        // Solo IOS
        // "GENDER": HealthDataAccess.READ_WRITE,
        // "BIRTH_DATE": HealthDataAccess.READ_WRITE,
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
        // print("Falta el permiso para $type con acceso $permission");
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

  // Setter: HEART_RATE (ppm)
  Future<bool> setHeartRate(double heartRate, {DateTime? date}) async {
    await _health.configure();

    final type = healthDataTypesString["HEART_RATE"]!;
    final permission = healthDataPermissions["HEART_RATE"]!;
    var end = DateTime.now();
    var start = end.subtract(Duration(minutes: 1));

    await _health.requestAuthorization([type], permissions: [permission]);

    bool success = await _health.writeHealthData(
      value: heartRate,
      unit: HealthDataUnit.BEATS_PER_MINUTE,
      type: type,
      startTime: start,
      endTime: end,
      recordingMethod: RecordingMethod.manual,
    );

    return success;
  }

  // Setter: HEIGHT
  Future<bool> setHeight(int height, {DateTime? date}) async {
    await _health.configure();

    double heightMeter = height / 100;
    final type = healthDataTypesString["HEIGHT"]!;
    final permission = healthDataPermissions["HEIGHT"]!;
    var end = DateTime.now();
    var start = end.subtract(Duration(minutes: 1));

    await _health.requestAuthorization([type], permissions: [permission]);

    bool success = await _health.writeHealthData(
      value: heightMeter,
      type: type,
      startTime: start,
      endTime: end,
      recordingMethod: RecordingMethod.manual,
    );

    return success;
  }

  // Setter: WEIGHT (kg)
  Future<bool> setWeight(double weight, {DateTime? date}) async {
    await _health.configure();

    final type = healthDataTypesString["WEIGHT"]!;
    final permission = healthDataPermissions["WEIGHT"]!;
    var end = DateTime.now();
    var start = end.subtract(Duration(minutes: 1));

    await _health.requestAuthorization([type], permissions: [permission]);

    bool success = await _health.writeHealthData(
      value: weight,
      unit: HealthDataUnit.KILOGRAM,
      type: type,
      startTime: start,
      endTime: end,
      recordingMethod: RecordingMethod.manual,
    );

    return success;
  }

  // Setter: STEPS (contador)
  Future<bool> setSteps(int steps, {DateTime? date}) async {
    await _health.configure();

    final type = healthDataTypesString["STEPS"]!;
    final permission = healthDataPermissions["STEPS"]!;
    var end = DateTime.now();
    var start = end.subtract(Duration(minutes: 1));

    await _health.requestAuthorization([type], permissions: [permission]);

    bool success = await _health.writeHealthData(
      value: steps.toDouble(),
      unit: HealthDataUnit.COUNT,
      type: type,
      startTime: start,
      endTime: end,
      recordingMethod: RecordingMethod.manual,
    );

    return success;
  }

  // Setter: TOTAL_CALORIES_BURNED (kcal) - actualizado a partir de ACTIVE_ENERGY_BURNED
  Future<bool> setCaloriesBurned(double calories, {DateTime? date}) async {
    await _health.configure();

    final type = healthDataTypesString["ACTIVE_ENERGY_BURNED"]!;
    final permission = healthDataPermissions["ACTIVE_ENERGY_BURNED"]!;
    var end = DateTime.now();
    var start = end.subtract(Duration(minutes: 1));

    await _health.requestAuthorization([type], permissions: [permission]);

    bool success = await _health.writeHealthData(
      value: calories,
      unit: HealthDataUnit.KILOCALORIE,
      type: type,
      startTime: start,
      endTime: end,
      recordingMethod: RecordingMethod.manual,
    );
    return success;
  }

  // Lecturas
  Future<List<HealthDataPoint>> getReadHeartRate(int nDays) async {
    return _readHealthData(healthDataTypesString["HEART_RATE"]!, nDays);
  }

  Future<Map<DateTime, dynamic>> getReadHeight(int nDays) async {
    final hasPermission = await _health.hasPermissions([healthDataTypesString["HEIGHT"]!], permissions: [healthDataPermissions["HEIGHT"]!]) ?? false;
    if (!hasPermission) return {};

    final dataPoints = await _readHealthData(healthDataTypesString["HEIGHT"]!, nDays);
    final Map<DateTime, dynamic> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final heightValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      if (dp.unit == HealthDataUnit.METER) {
        tempMap[dateFormat] = (heightValue * 100).toInt();
      } else {
        Logger().e('Error: Unidad de altura no reconocida (${dp.unit})');
      }
    }
    return tempMap;
  }

  Future<int> getCurrentHeight(int nDays) async {
    final heights = await getReadHeight(nDays);
    return heights.entries.last.value;
  }

  Future<Map<DateTime, double>> getReadWeight(int nDays) async {
    final hasPermission = await _health.hasPermissions([healthDataTypesString["WEIGHT"]!], permissions: [healthDataPermissions["WEIGHT"]!]) ?? false;
    if (!hasPermission) return {};

    final dataPoints = await _readHealthData(healthDataTypesString["WEIGHT"]!, nDays);
    final Map<DateTime, double> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final weightValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[dateFormat] = double.parse(weightValue.toStringAsFixed(2));
    }
    return tempMap;
  }

  Future<double> getCurrentWeight() async {
    if (weight == 0.0) return weight;
    final weights = await getReadWeight(9999);
    weight = weights.entries.last.value;
    return weight;
  }

  Future<Map<DateTime, int>> getReadSteps(int nDays) async {
    final hasPermission = await _health.hasPermissions([healthDataTypesString["STEPS"]!], permissions: [healthDataPermissions["STEPS"]!]) ?? false;
    if (!hasPermission) return {};

    List<HealthDataPoint> dataPoints = await _readHealthData(healthDataTypesString["STEPS"]!, nDays);
    Map<DateTime, int> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final stepsValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 1;
      tempMap[dateFormat] = (tempMap[dateFormat] ?? 0) + stepsValue;
    }
    return tempMap;
  }

  Future<Map<DateTime, double>> getTotalCaloriesActivityBurned(int nDays) async {
    final hasPermission = await _health.hasPermissions([healthDataTypesString["TOTAL_CALORIES_BURNED"]!], permissions: [healthDataPermissions["TOTAL_CALORIES_BURNED"]!]) ?? false;
    if (!hasPermission) return {};

    final dataPoints = await _readHealthData(healthDataTypesString["TOTAL_CALORIES_BURNED"]!, nDays);
    final Map<DateTime, double> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final calValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[dateFormat] = double.parse(calValue.toStringAsFixed(2));
    }
    return tempMap;
  }

  Future<Map<DateTime, double>> getTotalCaloriesTotalBurned(int nDays) async {
    final hasPermission = await _health.hasPermissions([healthDataTypesString["ACTIVE_ENERGY_BURNED"]!], permissions: [healthDataPermissions["ACTIVE_ENERGY_BURNED"]!]) ?? false;
    if (!hasPermission) return {};

    final dataPoints = await _readHealthData(healthDataTypesString["ACTIVE_ENERGY_BURNED"]!, nDays);
    final Map<DateTime, double> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final calValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[dateFormat] = double.parse(calValue.toStringAsFixed(2));
    }
    return tempMap;
  }
}
