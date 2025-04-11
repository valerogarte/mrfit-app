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
    if (heights.entries.isEmpty) {
      return 0;
    }
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

  Future<Map<DateTime, int>> getReadStepsByDate(String date) async {
    final hasPermission = await _health.hasPermissions(
          [healthDataTypesString["STEPS"]!],
          permissions: [healthDataPermissions["STEPS"]!],
        ) ??
        false;
    if (!hasPermission) return {};

    final parsedDate = DateTime.parse(date);
    final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final end = start.add(const Duration(days: 1));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [healthDataTypesString["STEPS"]!],
    );

    Map<DateTime, int> tempMap = {parsedDate: 0};
    for (var dp in dataPoints) {
      final stepsValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0;
      tempMap[parsedDate] = (tempMap[parsedDate] ?? 0) + stepsValue;
    }
    return tempMap;
  }

  // Modificado getReadSteps para aceptar (DateTime startDate, int nDays)
  Future<Map<DateTime, int>> getReadSteps(DateTime startDate, int nDays) async {
    final hasPermission = await _health.hasPermissions(
          [healthDataTypesString["STEPS"]!],
          permissions: [healthDataPermissions["STEPS"]!],
        ) ??
        false;
    if (!hasPermission) return {};

    final endDate = startDate.add(Duration(days: nDays));
    List<HealthDataPoint> dataPoints = await _health.getHealthDataFromTypes(
      startTime: startDate,
      endTime: endDate,
      types: [healthDataTypesString["STEPS"]!],
    );
    Map<DateTime, int> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final stepsValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0;
      tempMap[dateFormat] = (tempMap[dateFormat] ?? 0) + stepsValue;
    }
    return tempMap;
  }

  // Modificado getTotalCaloriesBurned para aceptar (DateTime startDate, int nDays)
  Future<Map<DateTime, double>> getTotalCaloriesBurned(DateTime startDate, int nDays) async {
    final hasPermission = await _health.hasPermissions(
          [healthDataTypesString["TOTAL_CALORIES_BURNED"]!],
          permissions: [healthDataPermissions["TOTAL_CALORIES_BURNED"]!],
        ) ??
        false;
    if (!hasPermission) return {};

    final endDate = startDate.add(Duration(days: nDays));
    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: startDate,
      endTime: endDate,
      types: [healthDataTypesString["TOTAL_CALORIES_BURNED"]!],
    );
    final Map<DateTime, double> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final calValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[dateFormat] = (tempMap[dateFormat] ?? 0) + double.parse(calValue.toStringAsFixed(2));
    }
    return tempMap;
  }

  Future<Map<DateTime, double>> getTotalCaloriesBurnedByDay(String date) async {
    final hasPermission = await _health.hasPermissions(
          [healthDataTypesString["TOTAL_CALORIES_BURNED"]!],
          permissions: [healthDataPermissions["TOTAL_CALORIES_BURNED"]!],
        ) ??
        false;
    if (!hasPermission) return {};

    final parsedDate = DateTime.parse(date);
    final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final end = start.add(const Duration(days: 1));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [healthDataTypesString["TOTAL_CALORIES_BURNED"]!],
    );

    Map<DateTime, double> tempMap = {parsedDate: 0.0};
    for (var dp in dataPoints) {
      final calValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0.0;
      tempMap[parsedDate] = (tempMap[parsedDate] ?? 0.0) + calValue;
    }
    return tempMap;
  }

  /*
  * Sale de la suma de WORKOUTS
  *
  */
  Future<Map<DateTime, int>> getReadTimeActivityByDate(String date) async {
    final hasPermissionWorkout = await _health.hasPermissions(
          [healthDataTypesString["WORKOUT"]!],
          permissions: [healthDataPermissions["WORKOUT"]!],
        ) ??
        false;
    if (!hasPermissionWorkout) return {};

    final parsedDate = DateTime.parse(date);
    final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final end = start.add(const Duration(days: 1));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [healthDataTypesString["WORKOUT"]!],
    );

    Map<DateTime, int> activityTimeTotal = {parsedDate: 0};
    for (var dp in dataPoints) {
      print(dp);
      if (dp.value is WorkoutHealthValue) {
        final duration = dp.dateTo.difference(dp.dateFrom).inMinutes;
        activityTimeTotal[parsedDate] = (activityTimeTotal[parsedDate] ?? 0) + duration;
      }
    }

    return activityTimeTotal;
  }

  Future<Map<DateTime, double>> getTotalCaloriesBurnedInActivityByDay(String date) async {
    final hasPermission = await _health.hasPermissions(
          [healthDataTypesString["ACTIVE_ENERGY_BURNED"]!],
          permissions: [healthDataPermissions["ACTIVE_ENERGY_BURNED"]!],
        ) ??
        false;
    if (!hasPermission) return {};

    final parsedDate = DateTime.parse(date);
    final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final end = start.add(const Duration(days: 1));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [healthDataTypesString["ACTIVE_ENERGY_BURNED"]!],
    );

    Map<DateTime, double> tempMap = {parsedDate: 0.0};
    print(dataPoints);
    for (var dp in dataPoints) {
      final calValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0.0;
      tempMap[parsedDate] = (tempMap[parsedDate] ?? 0.0) + calValue;
    }
    return tempMap;
  }

  Future<Map<DateTime, int>> getReadDistanceByDate(String date) async {
    final hasPermission = await _health.hasPermissions(
          [healthDataTypesString["DISTANCE_DELTA"]!],
          permissions: [healthDataPermissions["DISTANCE_DELTA"]!],
        ) ??
        false;
    if (!hasPermission) return {};

    final parsedDate = DateTime.parse(date);
    final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final end = start.add(const Duration(days: 1));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [healthDataTypesString["DISTANCE_DELTA"]!],
    );

    Map<DateTime, int> tempMap = {parsedDate: 0};
    for (var dp in dataPoints) {
      final calValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[parsedDate] = (tempMap[parsedDate] ?? 0) + calValue.toInt();
    }
    return tempMap;
  }
}
