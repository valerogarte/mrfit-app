import 'package:mrfit/models/usuario/usuario.dart';
import 'package:health/health.dart';
import 'package:mrfit/utils/constants.dart';

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
      filterByApp: true,
    );
    final stepsPoints = HealthUtils.customRemoveDuplicates(
      dataPoints.where((dp) => dp.type == HealthDataType.STEPS).toList(),
      filterByApp: true,
    );

    // Filtra y elimina duplicados de los puntos de distancia, usando un sectionGap de 5 milisegundos
    final distancePoints = HealthUtils.customRemoveDuplicates(
      dataPoints.where((dp) => dp.type == HealthDataType.DISTANCE_DELTA).toList(),
      filterByApp: true,
    );

    // Extraer valores de frecuencia cardiaca
    int? heartRateAvg;
    double? heartRateMin;
    double? heartRateMax;
    if (heartRatePoints.isNotEmpty) {
      heartRateAvg = HealthUtils.getAvgByGranularity(heartRatePoints, granularity: "second");
      heartRateMin = heartRatePoints.map((dp) => dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toDouble() : double.infinity).reduce((a, b) => a < b ? a : b);
      heartRateMax = heartRatePoints.map((dp) => dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toDouble() : double.negativeInfinity).reduce((a, b) => a > b ? a : b);
    }

    // Extraer valores agregados para pasos
    final stepsList = stepsPoints.map((dp) => dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0).toList();
    int stepsSum = stepsList.fold(0, (sum, v) => sum + v);

    // Extraer valores agregados para distancia
    final distanceList = distancePoints.map((dp) => dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0).toList();
    int distanceSum = distanceList.fold(0, (sum, v) => sum + v);

    // Serializar los dataPoints a JSON
    final stepsJson = stepsPoints.map((dp) => dp.toJson()).toList();
    final distanceJson = distancePoints.map((dp) => dp.toJson()).toList();

    return {
      'HEART_RATE': {
        'avg': heartRateAvg,
        'min': heartRateMin,
        'max': heartRateMax,
        'dataPoints': heartRatePoints,
      },
      'STEPS': {
        'sum': stepsSum,
        'dataPoints': stepsJson,
      },
      'DISTANCE_DELTA': {
        'sum': distanceSum,
        'dataPoints': distanceJson,
      },
    };
  }
}

/// Utilidades para el manejo de datos de salud.
/// Enum para definir la granularidad de agrupación de tiempo.

class HealthUtils {
  /// Elimina duplicados y agrupa puntos de datos de salud según criterios personalizados.
  ///
  /// Esta función toma una lista de [HealthDataPoint] y realiza las siguientes operaciones:
  /// - Ordena los puntos por fecha de inicio.
  /// - Elimina puntos de datos duplicados exactos (por fecha y valor).
  /// - Opcionalmente, filtra los puntos por la fuente de datos (app) de mayor prioridad o frecuencia.
  /// - Agrupa los puntos en secciones de tiempo si se especifica [sectionGap].
  ///
  /// Parámetros:
  /// - [dataPoints]: Lista de puntos de datos de salud a procesar.
  /// - [sectionGap]: (Opcional) Duración máxima entre puntos para agruparlos en la misma sección.
  /// - [filterByApp]: (Opcional) Si es `true`, solo se consideran los puntos de la app prioritaria.
  ///
  /// Retorna una lista de [HealthDataPoint] sin duplicados y agrupados según los criterios dados.
  static List<HealthDataPoint> customRemoveDuplicates(
    List<HealthDataPoint> dataPoints, {
    bool filterByApp = false,
  }) {
    // 1) Ordena y quita duplicados
    dataPoints.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    final seen = <String>{};
    final deduped = <HealthDataPoint>[];

    for (var p in dataPoints) {
      // ignora rangos de día completo
      if (p.dateFrom.hour == 0 && p.dateFrom.minute == 0 && p.dateFrom.second == 0 && p.dateTo.hour == 23 && p.dateTo.minute == 59 && p.dateTo.second == 59) continue;

      final key = [
        p.dateFrom.millisecondsSinceEpoch,
        p.dateTo.millisecondsSinceEpoch,
        (p.value as NumericHealthValue).numericValue,
      ].join('-');

      if (seen.add(key)) deduped.add(p);
    }

    // 2) Filtra por app si toca
    var processed = deduped;
    if (filterByApp && processed.isNotEmpty) {
      String? src;
      for (var app in AppConstants.healthPriority) {
        if (processed.any((p) => p.sourceName == app)) {
          src = app;
          break;
        }
      }
      src ??= processed
          .fold<Map<String, int>>({}, (m, p) {
            m[p.sourceName] = (m[p.sourceName] ?? 0) + 1;
            return m;
          })
          .entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      processed = processed.where((p) => p.sourceName == src).toList();
    }

    // 3) Agrupa por secciones de tiempo
    final sections = <_TimeSection>[];
    // Buscamos si cada punto ya está en una sección
    for (var p in processed) {
      bool added = false;
      for (var section in sections) {
        // Si el inicio de el dataPoint es el final de una section, todo OK
        if (p.dateFrom.isAtSameMomentAs(section.end)) {
          section.points.add(p);
          section.end = p.dateTo.isAfter(section.end) ? p.dateTo : section.end;
          added = true;
          break;
        } else if ((p.dateFrom.isAfter(section.start) && p.dateFrom.isBefore(section.end)) || (p.dateTo.isAfter(section.start) && p.dateTo.isBefore(section.end))) {
          // Encuentra los puntos con los que se solapan
          // final overlappingPoints = section.points.where((sp) => p.dateFrom.isBefore(sp.dateTo) && p.dateTo.isAfter(sp.dateFrom)).toList();
          // if (overlappingPoints.isNotEmpty) {
          // Se podría optimizar aún más la function.
          // NO HACER: La suma de los valores de los puntos que se solapan, deja un valor demasiado alto
          added = true;
          break;
          // }
        }
      }
      if (!added) {
        sections.add(_TimeSection(p));
      }
    }

    // 4) Aplana la lista de secciones a una lista de puntos
    processed = sections.expand((s) => s.points).toList();

    // 5) Ordena por fecha de inicio
    processed.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

    return processed.isEmpty ? [] : processed;
  }

  /// Devuelve la media de los dataPoints agrupada por la granularidad elegida.
  /// Por ejemplo, si eliges "hour", te dará la media agrupando el tiempo en grupos de cada hora.
  /// [points]: Lista de puntos de datos de salud.
  /// [granularity]: Granularidad de agrupación (segundo, minuto, hora).
  /// Devuelve la media global como entero.
  static int getAvgByGranularity(
    List<HealthDataPoint> points, {
    String granularity = "second",
  }) {
    final Map<int, List<double>> valuesByGroup = {};

    for (var dp in points) {
      if (dp.value is NumericHealthValue) {
        int groupKey = 0; // Valor por defecto para evitar error de variable no inicializada
        final date = dp.dateFrom;
        // Agrupa los puntos según la granularidad de tiempo especificada.
        switch (granularity) {
          case "hour":
            groupKey = DateTime(date.year, date.month, date.day, date.hour).millisecondsSinceEpoch;
            break;
          case "minute":
            groupKey = DateTime(date.year, date.month, date.day, date.hour, date.minute).millisecondsSinceEpoch;
            break;
          case "second":
            groupKey = DateTime(date.year, date.month, date.day, date.hour, date.minute, date.second).millisecondsSinceEpoch;
            break;
          default:
            groupKey = DateTime(date.year, date.month, date.day, date.hour, date.minute, date.second).millisecondsSinceEpoch;
            break;
        }
        valuesByGroup.putIfAbsent(groupKey, () => []);
        valuesByGroup[groupKey]!.add((dp.value as NumericHealthValue).numericValue.toDouble());
      }
    }

    if (valuesByGroup.isEmpty) return 0;

    // Calcula la media de cada grupo
    final mediasPorGrupo = valuesByGroup.values.map((values) => values.reduce((a, b) => a + b) / values.length).toList();

    // Calcula la media global y la convierte a int
    final mediaGlobal = mediasPorGrupo.reduce((a, b) => a + b) / mediasPorGrupo.length;
    return mediaGlobal.round();
  }
}

/// Clase interna para agrupar puntos de datos por secciones de tiempo.
/// Clase interna para agrupar puntos de datos por secciones de tiempo.
/// Cumple con el principio de responsabilidad única (SRP) al encargarse solo de la agrupación temporal.
class _TimeSection {
  DateTime start;
  DateTime end;
  final List<HealthDataPoint> points;

  _TimeSection(HealthDataPoint p)
      : start = p.dateFrom,
        end = p.dateTo,
        points = [p];
}
