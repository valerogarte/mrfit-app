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

    // Recorre los puntos de distancia y calcula la diferencia en segundos (con microsegundos) respecto al punto anterior.
    HealthDataPoint? previousDp;
    for (var dp in distancePoints) {
      if (dp.value is NumericHealthValue) {
        final value = (dp.value as NumericHealthValue).numericValue.toInt();
        final sourceName = dp.sourceName;
        final dateFrom = dp.dateFrom;
        final dateTo = dp.dateTo;

        // Calcula la diferencia en segundos (con microsegundos) entre el fin del punto anterior y el inicio del actual.
        double? diferenciaFinAnteriorInicioActual;
        if (previousDp != null) {
          final diff = dateFrom.difference(previousDp.dateTo);
          diferenciaFinAnteriorInicioActual = diff.inMicroseconds / 1000000.0;
        }

        // Imprime la información relevante, incluyendo la diferencia entre el fin del anterior y el inicio del actual.
        // Formatea las fechas a HH:mm:ss para mayor claridad en el log
        // Formatea las fechas a HH:mm:ss.SSS para mayor precisión en el log
        final formattedDateFrom = "${dateFrom.hour.toString().padLeft(2, '0')}:${dateFrom.minute.toString().padLeft(2, '0')}:${dateFrom.second.toString().padLeft(2, '0')}.${dateFrom.millisecond.toString().padLeft(3, '0')}";
        final formattedDateTo = "${dateTo.hour.toString().padLeft(2, '0')}:${dateTo.minute.toString().padLeft(2, '0')}:${dateTo.second.toString().padLeft(2, '0')}.${dateTo.millisecond.toString().padLeft(3, '0')}";
        print('$formattedDateFrom - $formattedDateTo : $value'
            '${diferenciaFinAnteriorInicioActual != null ? ' (Δ ${diferenciaFinAnteriorInicioActual.toStringAsFixed(6)} s)' : ''}, $sourceName');

        previousDp = dp;
      }
    }

    // Extraer valores de frecuencia cardiaca
    final heartRates = heartRatePoints.map((dp) => dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toDouble() : 0.0).toList();

    int? heartRateAvg;
    double? heartRateMin;
    double? heartRateMax;
    if (heartRatePoints.isNotEmpty) {
      // Calcula la media global agrupando por segundo y promediando cada grupo, devuelve un solo int
      heartRateAvg = HealthUtils.getAvgByGranularity(heartRatePoints, granularity: "second");
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
    Duration? sectionGap,
    bool filterByApp = false,
  }) {
    // 1) Ordena y quita duplicados
    dataPoints.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
    final seen = <String>{};
    final deduped = <HealthDataPoint>[];

    for (var p in dataPoints) {
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
    for (var p in processed) {
      if (sections.isEmpty) {
        sections.add(_TimeSection(p));
      } else {
        bool addedToSection = false;
        for (var section in sections) {
          // Si el final de la sección es igual al inicio del nuevo punto
          if (section.end == p.dateFrom) {
            section.points.add(p);
            section.end = p.dateTo;
            addedToSection = true;
            // Ordena las secciones por fecha de inicio de más reciente a más antigua
            // Con el objetivo de encontrar más rápido la sección a la que añadir el nuevo punto
            sections.sort((a, b) => b.end.compareTo(a.end));
            break;
          }
        }
        // Si no se añadió a ninguna sección existente
        //    Si la diferencia entre inicio de sesión y el end de una sección es menor que el sectionGap, añádelo a esa sección
        if (sectionGap != null) {
          for (var section in sections) {
            final diff = p.dateFrom.difference(section.end);
            if (diff.abs() <= sectionGap) {
              section.points.add(p);
              section.end = p.dateTo;
              addedToSection = true;
              break;
            }
          }
        }
        // Si finalmente no está dentro de ninguna sección, añádelo a una sección nueva
        if (!addedToSection) {
          sections.last.points.add(p);
          sections.last.end = p.dateTo;
        }
      }
    }
    // 4) Si hay secciones solapadas, unimos los puntos que haya diferentes y unificamos las secciones
    for (var sectionUno in sections) {
      // Compruebo si hay solapamiento con otras secciones
      for (var sectionDos in sections) {
        if (sectionUno.points.isNotEmpty && sectionDos.points.isNotEmpty) {
          // Si hay solapamiento, los puntos de sectionUno que están fuera de sectionDos se añaden a sectionDos
          if (sectionUno.end.isAfter(sectionDos.end) && sectionUno.end.isBefore(sectionDos.end.add(sectionGap!))) {
            // Añade los puntos de sectionUno a sectionDos si no están ya
            for (var p in sectionUno.points) {
              if (!sectionDos.points.contains(p)) {
                sectionDos.points.add(p);
              }
            }
            // Elimina la sección solapada
            sections.remove(sectionUno);
          }
        }
      }
    }

    // 5) Aplana la lista de secciones a una lista de puntos
    processed = sections.expand((s) => s.points).toList();

    return processed.isEmpty ? [] : processed;
  }

  /// Te da la media de los dataPoints agrupada por la granularidad elegida.
  /// Por ejemplo, si eliges "hour", te dará la media de cada hora.
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
class _TimeSection {
  DateTime end;
  final List<HealthDataPoint> points;

  _TimeSection(HealthDataPoint p)
      : end = p.dateTo,
        points = [p];
}
