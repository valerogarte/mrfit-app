part of '../usuario.dart';

class SleepSlot {
  final DateTime start;
  final DateTime end;
  final String type;
  final String sourceName;
  int get duration => end.difference(start).inMinutes;

  SleepSlot({
    required this.start,
    required this.end,
    this.type = "",
    this.sourceName = "",
  });

  factory SleepSlot.fromMap(Map<dynamic, dynamic> map) {
    final start = map['start'];
    final end = map['end'];
    if (start == null || end == null) {
      throw ArgumentError('Invalid SleepSlot data: $map');
    }
    final s = DateTime.fromMillisecondsSinceEpoch(start);
    final e = DateTime.fromMillisecondsSinceEpoch(end);
    return SleepSlot(start: s, end: e, sourceName: map['sourceName'] ?? '');
  }
}

extension UsuarioSleepExtension on Usuario {
  /*
    ** Filtra y fusiona franjas de sueño para la fecha seleccionada.
    ** Filtra las franjas que caen dentro del rango de fechas especificado, elimina las franjas que se extienden más allá de la hora actual,
    ** y fusiona franjas consecutivas con menos de 2 minutos de separación. Además, incluye una franja del día anterior
    ** si comienza a medianoche y se extiende hasta la fecha seleccionada.
  */
  List<SleepSlot> filterAndMergeSlotsInactivity(List<SleepSlot> slots, DateTime selectedDate) {
    final inicio = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final fin = inicio.add(const Duration(hours: 11));

    // Filtrar franjas para la fecha seleccionada
    final hoy = slots.where((s) => !s.start.isBefore(inicio) && s.start.isBefore(fin)).toList();
    if (hoy.isEmpty) return [];

    // Eliminar franjas que terminan después de la hora actual
    final ahora = DateTime.now();
    hoy.removeWhere((s) => s.end.isAfter(ahora));
    if (hoy.isEmpty) return [];

    // Fusionar franjas con menos de 2 minutos de separación
    int tiempoTemporalVerMovil = 2;
    for (var i = 0; i < hoy.length - 1; i++) {
      final s1 = hoy[i];
      final s2 = hoy[i + 1];
      if (s1.end.isAfter(s2.start.subtract(Duration(minutes: tiempoTemporalVerMovil)))) {
        hoy[i] = SleepSlot(start: s1.start, end: s2.end);
        hoy.removeAt(i + 1);
        i--;
      }
    }

    hoy.sort((a, b) => b.duration.compareTo(a.duration));
    var principal = hoy.first;

    // Incluir franja del día anterior si comienza a medianoche
    if (principal.start == inicio) {
      final ayer = slots.where((s) => s.start.isBefore(inicio) && s.start.isAfter(inicio.subtract(const Duration(days: 1)))).toList();
      if (ayer.isNotEmpty) {
        final ext = ayer.last;
        principal = SleepSlot(
          start: ext.start,
          end: principal.end,
          sourceName: ext.sourceName,
        );
      }
    }

    final result = [principal]..sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  int calculateTotalMinutes(List<SleepSlot> slots) {
    return slots.fold(0, (sum, s) => sum + s.duration);
  }

  Future<List<SleepSlot>> getTypeSleepByDate(DateTime start, DateTime end) async {
    List<SleepSlot> sleepSlots = [];
    final sleepKeys = [
      "SLEEP_DEEP",
      "SLEEP_LIGHT",
      "SLEEP_REM",
      "SLEEP_ASLEEP",
      "SLEEP_AWAKE_IN_BED",
      "SLEEP_AWAKE",
      "SLEEP_IN_BED",
      "SLEEP_OUT_OF_BED",
      "SLEEP_UNKNOWN",
    ];
    for (var key in sleepKeys) {
      if (await checkPermissionsFor(key)) {
        final dataPoints = await _health.getHealthDataFromTypes(
          startTime: start.subtract(const Duration(days: 1)),
          endTime: end,
          types: [healthDataTypesString[key]!],
        );
        for (var dp in dataPoints) {
          sleepSlots.add(
            SleepSlot(
              start: dp.dateFrom,
              end: dp.dateTo,
              type: key,
              sourceName: dp.sourceName,
            ),
          );
        }
      }
    }
    return sleepSlots;
  }

  void filterAndMergeSlotsSessionHC(
    List<SleepSlot> slots,
    SleepSlot newSlot,
    List<String> priorityList,
  ) {
    var shouldAdd = true;
    int? replaceIdx;
    final newHigh = priorityList.contains(newSlot.sourceName);

    // Recorremos los slots existentes para buscar colisiones
    for (var i = 0; i < slots.length; i++) {
      final existing = slots[i];

      // Si no hay solapamiento, seguimos
      final overlaps = existing.start.isBefore(newSlot.end) && existing.end.isAfter(newSlot.start);
      if (!overlaps) continue;

      final oldHigh = priorityList.contains(existing.sourceName);

      if (newHigh && oldHigh) {
        // Ambos tienen prioridad: nos quedamos con el que tenga mejor posición en la lista
        if (priorityList.indexOf(newSlot.sourceName) < priorityList.indexOf(existing.sourceName)) {
          replaceIdx = i;
        } else {
          shouldAdd = false;
        }
      } else if (newHigh) {
        // Sólo el nuevo tiene prioridad → reemplaza al existente
        replaceIdx = i;
      } else if (oldHigh) {
        // Sólo el existente tiene prioridad → descartamos el nuevo
        shouldAdd = false;
      } else {
        // Ninguno tiene prioridad → reemplazamos el existente
        replaceIdx = i;
      }

      break; // ya gestionamos esta colisión, salimos del bucle
    }

    // Aplicamos la acción: reemplazar o añadir
    if (replaceIdx != null) {
      slots[replaceIdx] = newSlot;
    } else if (shouldAdd) {
      slots.add(newSlot);
    }
  }

  Future<List<SleepSlot>> getSleepSessionByDate(DateTime day) async {
    // Definir inicio y fin del día
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Lista de resultados y prioridades
    final sleepSlots = <SleepSlot>[];
    const sleepKeys = ['SLEEP_SESSION'];
    final priorityList = AppConstants.healthPriority;

    for (final key in sleepKeys) {
      // Comprobar permisos
      if (!await checkPermissionsFor(key)) continue;

      // Obtener datos desde un día antes hasta el final del día
      final dataPoints = await _health.getHealthDataFromTypes(
        startTime: startOfDay.subtract(const Duration(days: 1)),
        endTime: endOfDay,
        types: [healthDataTypesString[key]!],
      );

      for (final dp in dataPoints) {
        // Si el sueño termina al día siguiente, lo descartamos
        if (dp.dateTo.isAfter(endOfDay)) continue;
        // Solo interesa si hay solapamiento con [startOfDay, endOfDay]
        final overlapsDay = dp.dateFrom.isBefore(endOfDay) && dp.dateTo.isAfter(startOfDay);
        if (!overlapsDay) continue;

        // Creamos el slot candidato y lo filtramos/mezclamos
        final candidate = SleepSlot(
          start: dp.dateFrom,
          end: dp.dateTo,
          sourceName: dp.sourceName,
        );
        filterAndMergeSlotsSessionHC(sleepSlots, candidate, priorityList);
      }
    }

    return sleepSlots;
  }

  Future<List<SleepSlot>> getSleepSlotsForDay(DateTime day) async {
    if (!await UsageStats.hasUsageStatsPermission()) {
      return [];
    }

    final formattedDay = DateFormat('yyyy-MM-dd').format(day);
    final data = await UsageStats.getInactivitySlots(formattedDay);
    return data.map((m) => SleepSlot.fromMap(m)).toList();
  }

  /// Writes sleep data to the health store.
  ///
  /// Parameters:
  ///   * [timeInicio] - The start time of the sleep session
  ///   * [timeFin] - The end time of the sleep session
  ///   * [sleepType] - The type of sleep to record (defaults to SLEEP_SESSION)
  ///   * SLEEP_ASLEEP - Sleep Asleep
  ///   * SLEEP_AWAKE_IN_BED - Awake in Bed
  ///   * SLEEP_AWAKE - Awake
  ///   * SLEEP_DEEP - Sleep Deep
  ///   * SLEEP_IN_BED - In Bed
  ///   * SLEEP_LIGHT - Sleep Light
  ///   * SLEEP_OUT_OF_BED - Out of Bed
  ///   * SLEEP_REM - Sleep REM
  ///   * SLEEP_SESSION - Sleep Session
  ///   * SLEEP_UNKNOWN - Unknown Sleep State
  /// Returns true if the sleep data was successfully written, false otherwise.
  Future<bool> writeSleepData({
    required DateTime timeInicio,
    required DateTime timeFin,
    HealthDataType sleepType = HealthDataType.SLEEP_SESSION,
  }) async {
    if (timeInicio.isAfter(timeFin)) {
      return false;
    }

    try {
      // Se reemplaza la comprobación de permisos por checkPermissionsFor
      if (!await checkPermissionsFor("SLEEP_SESSION")) {
        return false;
      }

      Logger().w("Insertando sueño en HealthConnect");

      // Write sleep data
      final result = await _health.writeHealthData(
        value: 1, // For sleep data, the value is usually 1
        type: sleepType,
        startTime: timeInicio,
        endTime: timeFin,
        recordingMethod: RecordingMethod.manual,
      );

      return result;
    } catch (e) {
      Logger().e('Error writing sleep data: $e');
      return false;
    }
  }

  /// Calcula la calidad del sueño en base a la proporción de los diferentes tipos de sueño.
  /// - SLEEP_DEEP: 20% - 25%
  /// - SLEEP_REM: 20% - 25%
  /// - SLEEP_LIGHT: 50% - 60%
  /// La suma de los siguientes tipos no debe superar el 10%:
  /// SLEEP_ASLEEP, SLEEP_IN_BED, SLEEP_AWAKE_IN_BED, SLEEP_AWAKE, SLEEP_OUT_OF_BED, SLEEP_UNKNOWN
  ///
  /// El porcentaje final se calcula partiendo de 100 puntos y restando penalizaciones
  /// si los porcentajes de cada tipo principal están fuera de su rango ideal, y si los tipos secundarios superan el 10%.
  /// Cada desviación fuera del rango ideal penaliza el score, y el resultado se limita entre 0 y 100.
  double getQualitySleep(List<SleepSlot> slots) {
    if (slots.isEmpty) return 0.0;

    // Agrupar la duración por tipo de sueño
    final Map<String, int> durations = {};
    int totalMinutes = 0;

    for (var slot in slots) {
      durations[slot.type] = (durations[slot.type] ?? 0) + slot.duration;
      totalMinutes += slot.duration;
    }

    if (totalMinutes == 0) return 0.0;

    // Tipos principales
    final deep = durations['SLEEP_DEEP'] ?? 0;
    final rem = durations['SLEEP_REM'] ?? 0;
    final light = durations['SLEEP_LIGHT'] ?? 0;

    // Tipos secundarios (no deben superar el 10%)
    final secondaryTypes = [
      'SLEEP_ASLEEP',
      'SLEEP_IN_BED',
      'SLEEP_AWAKE_IN_BED',
      'SLEEP_AWAKE',
      'SLEEP_OUT_OF_BED',
      'SLEEP_UNKNOWN',
    ];
    final secondary = secondaryTypes.fold<int>(0, (sum, t) => sum + (durations[t] ?? 0));

    // Calcular porcentajes
    final deepPct = deep / totalMinutes * 100;
    final remPct = rem / totalMinutes * 100;
    final lightPct = light / totalMinutes * 100;
    final secondaryPct = secondary / totalMinutes * 100;

    // Puntuación basada en la cercanía a los rangos ideales
    double score = 100.0;

    // Penalización por estar fuera de los rangos ideales
    double penalty(double pct, double min, double max) {
      if (pct < min) return (min - pct) * 2;
      if (pct > max) return (pct - max) * 2;
      return 0.0;
    }

    score -= penalty(deepPct, 20, 25);
    score -= penalty(remPct, 20, 25);
    score -= penalty(lightPct, 50, 60);

    // Penalización fuerte si los secundarios superan el 10%
    if (secondaryPct > 10) {
      score -= (secondaryPct - 10) * 3;
    }

    // Limitar el score entre 0 y 100
    if (score < 0) score = 0;
    if (score > 100) score = 100;

    return double.parse(score.toStringAsFixed(1));
  }
}
