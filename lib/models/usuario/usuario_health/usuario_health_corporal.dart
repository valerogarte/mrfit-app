part of '../usuario.dart';

extension UsuarioHealthCorporalExtension on Usuario {
  Future<bool> setHeartRate(double heartRate, {DateTime? date}) async {
    await _health.configure();

    final type = healthDataTypesString["HEART_RATE"]!;
    final permission = healthDataPermissions["HEART_RATE"]!;
    var end = DateTime.now();
    var start = end.subtract(Duration(minutes: 1));

    if (!await checkPermissionsFor("HEART_RATE")) {
      return false;
    }

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

  Future<bool> setHeight(int height) async {
    await _health.configure();

    double heightMeter = height / 100;
    final type = healthDataTypesString["HEIGHT"]!;
    final permission = healthDataPermissions["HEIGHT"]!;
    var end = DateTime.now();
    var start = end.subtract(Duration(minutes: 1));

    if (!await checkPermissionsFor("HEIGHT")) {
      return false;
    }

    bool success = await _health.writeHealthData(
      value: heightMeter,
      type: type,
      startTime: start,
      endTime: end,
      recordingMethod: RecordingMethod.manual,
    );

    return success;
  }

  Future<bool> setWeight(double weight, {DateTime? date}) async {
    await _health.configure();

    final type = healthDataTypesString["WEIGHT"]!;
    final permission = healthDataPermissions["WEIGHT"]!;
    var end = DateTime.now();
    var start = end.subtract(Duration(minutes: 1));

    if (!await checkPermissionsFor("WEIGHT")) {
      return false;
    }

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

  Future<List<HealthDataPoint>> getReadHeartRate(int nDays) async {
    return _readHealthData(healthDataTypesString["HEART_RATE"]!, nDays);
  }

  Future<Map<DateTime, double>> getReadHeartRateByDate(DateTime date) async {
    await _health.configure();
    if (!await checkPermissionsFor("HEART_RATE")) return {};

    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    // 1) Leer y limpiar duplicados
    var dataPoints = await _health.getHealthDataFromTypes(
      types: [HealthDataType.HEART_RATE],
      startTime: startOfDay,
      endTime: endOfDay,
    );
    dataPoints = _health.removeDuplicates(dataPoints);

    // 2) Ordenar cronológicamente
    dataPoints.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    final result = <DateTime, double>{};

    for (var dp in dataPoints) {
      final localTime = dp.dateFrom.toLocal();
      final double value = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toDouble() : 0.0;

      // 3) Si ya hay lectura en esa hora, hacemos promedio
      result.update(
        localTime,
        (old) => (old + value) / 2,
        ifAbsent: () => value,
      );
    }

    return result;
  }

  Future<int> getDailySpo2(DateTime date) async {
    await _health.configure();
    if (!await checkPermissionsFor("BLOOD_OXYGEN")) return 0;
    // lee últimas 24 h
    final raw = await _readHealthData(healthDataTypesString["BLOOD_OXYGEN"]!, 1);
    if (raw.isEmpty) return 0;
    final avg = raw.map((dp) => (dp.value as NumericHealthValue).numericValue).reduce((a, b) => a + b) / raw.length;
    return avg.round();
  }

  Future<int> getDailyStress(DateTime date) async {
    await _health.configure();
    if (!await checkPermissionsFor("HEART_RATE_VARIABILITY_RMSSD")) return 0;
    final raw = await _readHealthData(healthDataTypesString["HEART_RATE_VARIABILITY_RMSSD"]!, 1);
    if (raw.isEmpty) return 0;
    final avg = raw.map((dp) => (dp.value as NumericHealthValue).numericValue).reduce((a, b) => a + b) / raw.length;
    return avg.round(); // RMSSD en ms, pero lo usas como “estrés”
  }

  Future<int> getDailyStairsClimbed(DateTime date) async {
    await _health.configure();
    if (!await checkPermissionsFor("FLIGHTS_CLIMBED")) return 0;
    final raw = await _readHealthData(healthDataTypesString["FLIGHTS_CLIMBED"]!, 1);
    if (raw.isEmpty) return 0;
    return raw.map((dp) => (dp.value as NumericHealthValue).numericValue.toInt()).reduce((a, b) => a + b);
  }

  Future<Map<DateTime, dynamic>> getReadHeight(int nDays) async {
    if (!await checkPermissionsFor("HEIGHT")) return {};

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

  Future<int> getCurrentHeight() async {
    final userYears = DateTime.now().difference(fechaNacimiento!).inDays ~/ 365;
    final heights = await getReadHeight(userYears * 365);
    if (heights.entries.isEmpty) {
      return 0;
    }
    return heights.entries.last.value;
  }

  Future<Map<DateTime, double>> getReadWeight(int nDays) async {
    if (!await checkPermissionsFor("WEIGHT")) return {};

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
    final defaultWeight = Usuario.getDefaultWeight();
    if (weight > 0.0) return weight;
    final weights = await getReadWeight(9999);
    if (weights.entries.isEmpty) {
      return defaultWeight;
    }
    weight = weights.entries.last.value;
    if (weight == 0.0) {
      weight = defaultWeight;
    }
    return weight;
  }
}
