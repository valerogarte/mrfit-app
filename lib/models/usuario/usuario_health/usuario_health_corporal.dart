part of '../usuario.dart';

extension UsuarioHealthCorporalExtension on Usuario {
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
}
