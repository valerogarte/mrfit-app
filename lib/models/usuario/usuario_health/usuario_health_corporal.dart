part of '../usuario.dart';

extension UsuarioHealthCorporalExtension on Usuario {
  Future<bool> setHeartRate(double heartRate, {DateTime? date}) async {
    await _health.configure();

    final type = healthDataTypesString["HEART_RATE"]!;
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

    if (!await checkPermissionsFor("HEIGHT")) {
      return false;
    }

    double heightMeter = height / 100;
    final type = healthDataTypesString["HEIGHT"]!;
    var end = DateTime.now();
    var start = end.subtract(Duration(minutes: 1));

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

  Future<List<HealthDataPoint>> getReadHeartRate(DateTime date) async {
    if (!await checkPermissionsFor("HEART_RATE")) return [];
    // Ahora se pasa una lista de tipos, no un solo tipo
    return readHealthDataByDate([healthDataTypesString["HEART_RATE"]!], date);
  }

  Future<int> getDailySpo2(DateTime date) async {
    await _health.configure();
    if (!await checkPermissionsFor("BLOOD_OXYGEN")) return 0;
    // lee últimas 24 h
    final raw = await readHealthDataByDate([healthDataTypesString["BLOOD_OXYGEN"]!], date);
    if (raw.isEmpty) return 0;
    final avg = raw.map((dp) => (dp.value as NumericHealthValue).numericValue).reduce((a, b) => a + b) / raw.length;
    return avg.round();
  }

  Future<int> getDailyStress(DateTime date) async {
    await _health.configure();
    if (!await checkPermissionsFor("HEART_RATE_VARIABILITY_RMSSD")) return 0;
    final raw = await readHealthDataByDate([healthDataTypesString["HEART_RATE_VARIABILITY_RMSSD"]!], date);
    if (raw.isEmpty) return 0;
    final avg = raw.map((dp) => (dp.value as NumericHealthValue).numericValue).reduce((a, b) => a + b) / raw.length;
    return avg.round(); // RMSSD en ms, pero lo usas como “estrés”
  }

  Future<int> getDailyStairsClimbed(DateTime date) async {
    await _health.configure();
    if (!await checkPermissionsFor("FLIGHTS_CLIMBED")) return 0;
    final raw = await readHealthDataByDate([healthDataTypesString["FLIGHTS_CLIMBED"]!], date);
    if (raw.isEmpty) return 0;
    return raw.map((dp) => (dp.value as NumericHealthValue).numericValue.toInt()).reduce((a, b) => a + b);
  }

  Future<Map<DateTime, dynamic>> getReadHeight(int nDays) async {
    if (!await checkPermissionsFor("HEIGHT")) return {};

    final dataPoints = await _readHealthDataFromNDaysAgoToNow(healthDataTypesString["HEIGHT"]!, nDays);
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
    if (!await checkPermissionsFor("HEIGHT") || !isHealthConnectAvailable) {
      return altura ?? 0;
    }

    final userYears = DateTime.now().difference(fechaNacimiento).inDays ~/ 365;
    final heights = await getReadHeight(userYears * 365);
    if (heights.entries.isEmpty) {
      return 0;
    }
    return heights.entries.last.value;
  }

  Future<Map<DateTime, double>> getReadWeight(int nDays) async {
    if (!await checkPermissionsFor("WEIGHT")) return {};

    final dataPoints = await _readHealthDataFromNDaysAgoToNow(healthDataTypesString["WEIGHT"]!, nDays);
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
    if (weight > 0.0 || !isHealthConnectAvailable) return weight;
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

  Future<Map<DateTime, double>> getReadMuscleMass(int nDays) async {
    if (!await checkPermissionsFor("MUSCLE_MASS")) return {};

    final dataPoints = await _readHealthDataFromNDaysAgoToNow(healthDataTypesString["MUSCLE_MASS"]!, nDays);
    final Map<DateTime, double> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final value = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[dateFormat] = double.parse(value.toStringAsFixed(2));
    }
    return tempMap;
  }

  Future<Map<DateTime, double>> getReadLeanBodyMass(int nDays) async {
    if (!await checkPermissionsFor("LEAN_BODY_MASS")) return {};

    final dataPoints = await _readHealthDataFromNDaysAgoToNow(healthDataTypesString["LEAN_BODY_MASS"]!, nDays);
    final Map<DateTime, double> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final value = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[dateFormat] = double.parse(value.toStringAsFixed(2));
    }
    return tempMap;
  }

  Future<Map<DateTime, double>> getReadBodyFat(int nDays) async {
    if (!await checkPermissionsFor("BODY_FAT_PERCENTAGE")) return {};

    final dataPoints = await _readHealthDataFromNDaysAgoToNow(healthDataTypesString["BODY_FAT_PERCENTAGE"]!, nDays);
    final Map<DateTime, double> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final value = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[dateFormat] = double.parse(value.toStringAsFixed(2));
    }
    return tempMap;
  }

  Future<Map<DateTime, double>> getReadBodyBone(int nDays) async {
    if (!await checkPermissionsFor("BONE_MASS")) return {};

    final dataPoints = await _readHealthDataFromNDaysAgoToNow(healthDataTypesString["BONE_MASS"]!, nDays);
    final Map<DateTime, double> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final value = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[dateFormat] = double.parse(value.toStringAsFixed(2));
    }
    return tempMap;
  }

  Future<Map<DateTime, double>> getReadBodyWater(int nDays) async {
    if (!await checkPermissionsFor("BODY_WATER_MASS")) return {};

    final dataPoints = await _readHealthDataFromNDaysAgoToNow(healthDataTypesString["BODY_WATER_MASS"]!, nDays);
    final Map<DateTime, double> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final value = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[dateFormat] = double.parse(value.toStringAsFixed(2));
    }
    return tempMap;
  }

  Future<Map<DateTime, double>> getReadBMI(int nDays) async {
    if (!await checkPermissionsFor("BODY_MASS_INDEX")) return {};

    final dataPoints = await _readHealthDataFromNDaysAgoToNow(healthDataTypesString["BODY_MASS_INDEX"]!, nDays);
    final Map<DateTime, double> tempMap = {};
    for (var dp in dataPoints) {
      final localDate = dp.dateFrom.toLocal();
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final dateFormat = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
      final value = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[dateFormat] = double.parse(value.toStringAsFixed(2));
    }
    return tempMap;
  }

  Future<double> getCurrentBasalMetabolicRate(int nDays) async {
    if (!await checkPermissionsFor("BASAL_ENERGY_BURNED")) return 0.0;

    final dataPoints = await _readHealthDataFromNDaysAgoToNow(healthDataTypesString["BASAL_ENERGY_BURNED"]!, nDays);
    if (dataPoints.isEmpty) return 0.0;
    final dp = dataPoints.last;
    final value = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0.0;
    return double.parse(value.toStringAsFixed(2));
  }
}
