import 'package:mrfit/models/usuario/usuario.dart';
import 'package:health/health.dart';

/// Clase para obtener un resumen de salud del usuario en un rango de fechas o por UUID.
/// Utiliza una sola llamada para obtener varios tipos de datos de salud.
class HealthSummary {
  final Usuario usuario;

  HealthSummary(this.usuario);

  /// Obtiene el resumen de salud entre [start] y [end] usando una sola llamada a Health.
  /// Devuelve un mapa con frecuencia cardiaca, pasos y distancia, incluyendo los dataPoints en formato JSON.
  Future<Map<String, dynamic>> getSummaryByDateRange(DateTime start, DateTime end) async {
    // Definir los tipos de datos a consultar
    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.STEPS,
      HealthDataType.DISTANCE_DELTA,
    ];

    // Obtener todos los datos de los tipos especificados en el rango
    final dataPoints = await Health().getHealthDataFromTypes(
      types: types,
      startTime: start,
      endTime: end,
    );

    // Eliminar duplicados y limpiar los dataPoints por tipo usando HealthUtils
    final heartRatePoints = HealthUtils.customRemoveDuplicates(
      dataPoints.where((dp) => dp.type == HealthDataType.HEART_RATE).toList(),
    );
    final stepsPoints = HealthUtils.customRemoveDuplicates(
      dataPoints.where((dp) => dp.type == HealthDataType.STEPS).toList(),
    );
    final distancePoints = HealthUtils.customRemoveDuplicates(
      dataPoints.where((dp) => dp.type == HealthDataType.DISTANCE_DELTA).toList(),
    );

    // Extraer valores de frecuencia cardiaca
    final heartRates = heartRatePoints.map((dp) => dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toDouble() : 0.0).toList();

    double? heartRateAvg;
    double? heartRateMin;
    double? heartRateMax;
    if (heartRates.isNotEmpty) {
      heartRateAvg = heartRates.reduce((a, b) => a + b) / heartRates.length;
      heartRateMin = heartRates.reduce((a, b) => a < b ? a : b);
      heartRateMax = heartRates.reduce((a, b) => a > b ? a : b);
    }

    // Extraer valores agregados para pasos
    final stepsList = stepsPoints.map((dp) => dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0).toList();
    int stepsSum = stepsList.fold(0, (sum, v) => sum + v);
    double? stepsAvg;
    int? stepsMin;
    int? stepsMax;
    if (stepsList.isNotEmpty) {
      stepsAvg = stepsSum / stepsList.length;
      stepsMin = stepsList.reduce((a, b) => a < b ? a : b);
      stepsMax = stepsList.reduce((a, b) => a > b ? a : b);
    }

    // Extraer valores agregados para distancia
    final distanceList = distancePoints.map((dp) => dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0).toList();
    int distanceSum = distanceList.fold(0, (sum, v) => sum + v);
    double? distanceAvg;
    int? distanceMin;
    int? distanceMax;
    if (distanceList.isNotEmpty) {
      distanceAvg = distanceSum / distanceList.length;
      distanceMin = distanceList.reduce((a, b) => a < b ? a : b);
      distanceMax = distanceList.reduce((a, b) => a > b ? a : b);
    }

    // Serializar los dataPoints a JSON
    final heartRateJson = heartRatePoints.map((dp) => dp.toJson()).toList();
    final stepsJson = stepsPoints.map((dp) => dp.toJson()).toList();
    final distanceJson = distancePoints.map((dp) => dp.toJson()).toList();

    return {
      'HEART_RATE': {
        'values': heartRates,
        'avg': heartRateAvg,
        'min': heartRateMin,
        'max': heartRateMax,
        'dataPoints': heartRateJson,
      },
      'STEPS': {
        'sum': stepsSum,
        'avg': stepsAvg,
        'min': stepsMin,
        'max': stepsMax,
        'dataPoints': stepsJson,
      },
      'DISTANCE_DELTA': {
        'sum': distanceSum,
        'avg': distanceAvg,
        'min': distanceMin,
        'max': distanceMax,
        'dataPoints': distanceJson,
      },
    };
  }
}

/// Utilidades para el manejo de datos de salud.
class HealthUtils {
  /// Elimina duplicados y agrupa puntos de datos de salud por secciones de tiempo.
  /// [dataPoints]: Lista de puntos de datos de salud.
  /// [sectionGap]: Margen de tiempo para agrupar secciones.
  static List<HealthDataPoint> customRemoveDuplicates(
    List<HealthDataPoint> dataPoints, {
    Duration sectionGap = const Duration(seconds: 2),
  }) {
    // Ordena los puntos por fecha de inicio.
    dataPoints.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    // Elimina puntos de datos exactos.
    final seen = <String>{};
    final filtered = <HealthDataPoint>[];
    for (var p in dataPoints) {
      if (p.dateFrom.hour == 0 && p.dateFrom.minute == 0 && p.dateFrom.second == 0 && p.dateTo.hour == 23 && p.dateTo.minute == 59 && p.dateTo.second == 59) continue;

      final key = [
        p.dateFrom.millisecondsSinceEpoch,
        p.dateTo.millisecondsSinceEpoch,
        (p.value as NumericHealthValue).numericValue,
      ].join('-');

      if (seen.add(key)) filtered.add(p);
    }

    // Agrupa los puntos en secciones de tiempo.
    final sections = <_TimeSection>[];
    for (var p in filtered) {
      var added = false;
      for (var sec in sections) {
        if (p.dateFrom.isBefore(sec.end.add(sectionGap)) || p.dateFrom.isAtSameMomentAs(sec.end.add(sectionGap))) {
          sec.points.add(p);
          if (p.dateTo.isAfter(sec.end)) sec.end = p.dateTo;
          added = true;
          break;
        }
      }
      if (!added) {
        sections.add(_TimeSection(p));
      }
    }

    final clean = sections.expand((s) => s.points).toList();
    return clean;
  }
}

/// Clase interna para agrupar puntos de datos por secciones de tiempo.
class _TimeSection {
  DateTime end;
  final List<HealthDataPoint> points;

  _TimeSection(HealthDataPoint p)
      : end = p.dateTo,
        points = [p];
}
