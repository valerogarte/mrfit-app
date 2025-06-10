part of '../usuario.dart';

extension UsuarioHCActivityExtension on Usuario {
  Future<List<HealthDataPoint>> getStepsByDate(String date, {int nDays = 1}) async {
    if (!await checkPermissionsFor("STEPS")) return [];

    final parsedDate = DateTime.parse(date);
    final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final end = start.add(Duration(days: nDays));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [healthDataTypesString["STEPS"]!],
    );

    final dataPointsRaw = _health.removeDuplicates(dataPoints);
    final dataPointsClean = HealthUtils.customRemoveDuplicates(dataPointsRaw);
    return dataPointsClean;
  }

  Future<int> getTotalStepsByDateForCalendar(String date, {int nDays = 1}) async {
    final dataPoints = await getStepsByDate(date, nDays: nDays);
    int stepsByDay = 0;
    for (var dp in dataPoints) {
      final steps = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0;
      stepsByDay = stepsByDay + steps;
    }
    return stepsByDay;
  }

  Future<Map<String, List<HealthDataPoint>>> getDailyTrainingsByDate(String date, {int nDays = 1}) async {
    if (!await checkPermissionsFor("WORKOUT")) return {};

    final parsedDate = DateTime.parse(date);
    final dateKey = DateFormat('yyyy-MM-dd').format(parsedDate);
    final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final end = start.add(Duration(days: nDays));

    final List<HealthDataPoint> dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [healthDataTypesString["WORKOUT"]!],
    );

    final dataPointsClean = _health.removeDuplicates(dataPoints);

    Map<String, List<HealthDataPoint>> tempMap = {dateKey: []};
    for (var dp in dataPointsClean) {
      if (tempMap[dateKey]!.any((element) => element.dateFrom == dp.dateFrom && element.dateTo == dp.dateTo)) {
        continue;
      }
      tempMap[dateKey]!.add(dp);
    }
    return tempMap;
  }

  Future<List<HealthDataPoint>> getCaloriesBurnedByDay(String date, {int nDays = 1}) async {
    if (!await checkPermissionsFor("TOTAL_CALORIES_BURNED")) return [];

    final parsedDate = DateTime.parse(date);
    final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final end = start.add(Duration(days: nDays));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [healthDataTypesString["TOTAL_CALORIES_BURNED"]!],
    );

    var dataPointsClean = _health.removeDuplicates(dataPoints);

    final filteredDataPoints = <HealthDataPoint>[];

    for (var dpc in dataPointsClean) {
      if (dpc.value is NumericHealthValue) {
        final start = dpc.dateFrom;
        final end = dpc.dateTo;

        // Skip values that represent the entire day
        if (start.hour == 0 && start.minute == 0 && start.second == 0 && end.hour == 23 && end.minute == 59 && end.second == 59) {
          continue;
        }
        // Skip values where the end date is in the future
        if (end.isAfter(DateTime.now())) {
          continue;
        }
      }
      filteredDataPoints.add(dpc);
    }

    return filteredDataPoints;
  }

  Future<double> getTotalCaloriesBurnedByDateForCalendar(String date, {int nDays = 1}) async {
    final dataPoints = await getCaloriesBurnedByDay(date, nDays: nDays);
    double caloriesByDay = 0.0;

    for (var dp in dataPoints) {
      final calories = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0.0;

      caloriesByDay = caloriesByDay + calories;
    }

    return caloriesByDay;
  }

  Future<Map<DateTime, double>> getTotalCaloriesBurned({String? date, DateTime? startDate, int nDays = 1}) async {
    final parsedDate = date != null ? DateTime.parse(date) : startDate!;
    final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

    final dataPoints = await getCaloriesBurnedByDay(start.toIso8601String(), nDays: nDays);

    Map<DateTime, double> tempMap = {parsedDate: 0.0};
    for (var dp in dataPoints) {
      final calValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0.0;
      tempMap[parsedDate] = (tempMap[parsedDate] ?? 0.0) + calValue;
    }
    return tempMap;
  }

  /// Calcula los pasos a partir de los dataPoints recibidos.
  int getTotalSteps(List<HealthDataPoint> dataPointsSteps) {
    int steps = 0;
    for (var dp in dataPointsSteps) {
      if (dp.value is NumericHealthValue) {
        steps += (dp.value as NumericHealthValue).numericValue.toInt();
      }
    }
    return steps;
  }

  /// Calcula el número de horas activas del usuario en base a entrenamientos y pasos.
  /// Una hora se considera activa si:
  /// - Hay un entrenamiento (o entrenamientoMrFit) de más de 5 minutos en esa hora, o
  /// - Se han dado más de 400 pasos en esa hora.
  int getTimeUserActivity({
    List<HealthDataPoint>? steps,
    List<HealthDataPoint>? entrenamientos,
    List<Map<String, dynamic>>? entrenamientosMrFit,
  }) {
    final tiempoActivoMinimoEnEjercicio = 5;
    final pasosMinimosPorHora = 400;
    // Mapa para registrar si una hora específica es activa
    final Map<DateTime, bool> horasActivas = {};

    // Procesa entrenamientos (HealthDataPoint)
    if (entrenamientos != null) {
      for (var entrenamiento in entrenamientos) {
        final start = entrenamiento.dateFrom;
        final end = entrenamiento.dateTo;
        final durationMin = end.difference(start).inMinutes;
        if (durationMin > 5) {
          // Marca todas las horas cubiertas por este entrenamiento como activas
          DateTime current = DateTime(start.year, start.month, start.day, start.hour);
          while (current.isBefore(end)) {
            horasActivas[current] = true;
            current = current.add(const Duration(hours: 1));
          }
        }
      }
    }

    // Procesa entrenamientos MrFit (Map)
    if (entrenamientosMrFit != null) {
      for (var entrenamiento in entrenamientosMrFit) {
        final start = entrenamiento['start'] as DateTime;
        final end = entrenamiento['end'] as DateTime;
        final durationMin = end.difference(start).inMinutes;
        if (durationMin > tiempoActivoMinimoEnEjercicio) {
          DateTime current = DateTime(start.year, start.month, start.day, start.hour);
          while (current.isBefore(end)) {
            horasActivas[current] = true;
            current = current.add(const Duration(hours: 1));
          }
        }
      }
    }

    // Procesa pasos
    if (steps != null) {
      // Agrupa pasos por hora
      final Map<DateTime, int> pasosPorHora = {};
      for (var dp in steps) {
        if (dp.value is NumericHealthValue) {
          final pasos = (dp.value as NumericHealthValue).numericValue.toInt();
          final start = dp.dateFrom;
          final end = dp.dateTo;
          // Marca cada hora cubierta por el segmento de pasos
          DateTime current = DateTime(start.year, start.month, start.day, start.hour);
          while (current.isBefore(end)) {
            pasosPorHora[current] = (pasosPorHora[current] ?? 0) + pasos;
            current = current.add(const Duration(hours: 1));
          }
        }
      }
      // Marca como activa la hora si supera los 400 pasos y no fue marcada por entrenamiento
      for (var entry in pasosPorHora.entries) {
        if (entry.value > pasosMinimosPorHora) {
          horasActivas[entry.key] = true;
        }
      }
    }

    // Devuelve el número de horas activas
    return horasActivas.values.where((v) => v).length;
  }

  int getTimeActivityByDateForCalendar(
    Map<String, bool> grantedPermissions,
    List<HealthDataPoint> steps,
    List<HealthDataPoint> entrenamientos,
    List<Map<String, dynamic>> entrenamientosMrFit,
  ) {
    // Si steps o entrenamientos no se proporcionan, no los pasamos a getActivity para evitar lógica innecesaria.
    final activities = getActivity(
      steps,
      entrenamientos,
      entrenamientosMrFit,
    );

    int minutes = 0;
    for (var activity in activities) {
      final start = activity['start'] as DateTime;
      final end = activity['end'] as DateTime;
      final duration = end.difference(start).inMinutes;
      minutes += duration;
    }

    return minutes;
  }

  Future<Map<DateTime, int>> getReadDistanceByDate(String date) async {
    if (!await checkPermissionsFor("DISTANCE_DELTA")) return {};

    final parsedDate = DateTime.parse(date);
    final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    final end = start.add(const Duration(days: 1));

    final dataPoints = await _health.getHealthDataFromTypes(
      startTime: start,
      endTime: end,
      types: [healthDataTypesString["DISTANCE_DELTA"]!],
    );

    final dataPointsClean = _health.removeDuplicates(dataPoints);

    Map<DateTime, int> tempMap = {parsedDate: 0};
    for (var dp in dataPointsClean) {
      final calValue = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue : 0;
      tempMap[parsedDate] = (tempMap[parsedDate] ?? 0) + calValue.toInt();
    }
    return tempMap;
  }

  List<Map<String, dynamic>> getActivityFromSteps(List<HealthDataPoint> dataPoints) {
    final pasosPorMinuto = 70;
    final minutosActivos = 10;
    final descansoPermitido = 10;

    // 1) Filtrar resúmenes diarios
    final segments = dataPoints.where((dp) => dp.dateFrom != dp.dateTo);

    // 2) Sumar pasos por minuto
    final Map<DateTime, int> stepsPerMinute = {};
    for (var dp in segments) {
      final pasos = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0;
      final minuto = DateTime(
        dp.dateFrom.year,
        dp.dateFrom.month,
        dp.dateFrom.day,
        dp.dateFrom.hour,
        dp.dateFrom.minute,
      );
      stepsPerMinute[minuto] = (stepsPerMinute[minuto] ?? 0) + pasos;
    }

    // 3) Buscar bloques ≥15 min con ≥100 pasos/min
    final walkingPeriods = <Map<String, dynamic>>[];
    final sortedMinutes = stepsPerMinute.keys.toList()..sort();
    DateTime? start;
    int streak = 0;

    void cerrarBloque() {
      if (start != null && streak >= minutosActivos) {
        final periodStart = start;
        final periodEnd = periodStart.add(Duration(minutes: streak));
        final total = stepsPerMinute.entries.where((e) => !e.key.isBefore(periodStart) && e.key.isBefore(periodEnd)).fold<int>(0, (s, e) => s + e.value);
        walkingPeriods.add({
          'start': periodStart,
          'end': periodEnd,
          'durationMin': streak,
          'avgStepspm': total ~/ streak,
        });
      }
    }

    for (var minute in sortedMinutes) {
      if (stepsPerMinute[minute]! >= pasosPorMinuto) {
        start ??= minute;
        streak++;
      } else {
        cerrarBloque();
        start = null;
        streak = 0;
      }
    }
    cerrarBloque();

    // 4) Unir bloques separados por <10 min
    final merged = <Map<String, dynamic>>[];
    for (var period in walkingPeriods) {
      if (merged.isEmpty) {
        merged.add(Map.from(period));
        continue;
      }
      final last = merged.last;
      final gap = (period['start'] as DateTime).difference(last['end'] as DateTime).inMinutes;
      if (gap < descansoPermitido) {
        // fusionar
        final newStart = last['start'] as DateTime;
        final newEnd = period['end'] as DateTime;
        final newDur = newEnd.difference(newStart).inMinutes;
        final totalPasos = stepsPerMinute.entries.where((e) => !e.key.isBefore(newStart) && e.key.isBefore(newEnd)).fold<int>(0, (s, e) => s + e.value);
        last
          ..['end'] = newEnd
          ..['durationMin'] = newDur
          ..['avgStepspm'] = totalPasos ~/ newDur;
      } else {
        merged.add(Map.from(period));
      }
    }

    return merged;
  }

  Future<List<Map<String, dynamic>>> getActivityMrFit(DateTime day) async {
    List<Map<String, dynamic>> activity = [];

    final entrenamientosMrFit = await getEjerciciosByDay(day);

    for (var entrenamiento in entrenamientosMrFit) {
      activity.add({
        'uuid': "",
        'id': entrenamiento.id,
        'type': 'workout',
        'start': entrenamiento.inicio,
        'end': entrenamiento.fin,
        'sourceName': AppConstants.domainNameApp,
        'title': entrenamiento.titulo,
        'activityType': "HealthWorkoutActivityType.WEIGHTLIFTING",
      });
    }

    // Ordena las actividades por fecha de inicio descendente.
    activity.sort((a, b) => (b['start'] as DateTime).compareTo(a['start'] as DateTime));
    return activity;
  }

  /// Obtiene la lista de actividades (entrenamientos y pasos) para una fecha dada.
  /// Separa la lógica según la disponibilidad de Health Connect.
  /// Evita solapamientos entre pasos y entrenamientos.
  List<Map<String, dynamic>> getActivity(
    List<HealthDataPoint> stepsDataPoints,
    List<HealthDataPoint> entrenamientos,
    List<Map<String, dynamic>> entrenamientosMrFit,
  ) {
    List<Map<String, dynamic>> activity = [];

    for (var entrenamiento in entrenamientos) {
      activity.add({
        'uuid': entrenamiento.uuid,
        'type': 'workout',
        'start': entrenamiento.dateFrom,
        'end': entrenamiento.dateTo,
        'sourceName': entrenamiento.sourceName,
        'activityType': (entrenamiento.value as WorkoutHealthValue).workoutActivityType.toString(),
      });
    }

    // Añade bloques de pasos solo si no solapan con entrenamientos.
    final steps = getActivityFromSteps(stepsDataPoints);
    for (var step in steps) {
      final stepStart = step['start'] as DateTime;
      final stepEnd = step['end'] as DateTime;

      final overlaps = activity.any((act) {
        final actStart = act['start'] as DateTime;
        final actEnd = act['end'] as DateTime;
        return stepStart.isBefore(actEnd) && stepEnd.isAfter(actStart);
      });

      if (!overlaps) {
        activity.add({
          'type': 'steps',
          'start': step['start'],
          'end': step['end'],
          'durationMin': step['durationMin'],
          'avgStepspm': step['avgStepspm'],
        });
      }
    }

    const porcentajeSolapamientoMinimo = 0.9;

    // Mergeo si hay entrenamientos que coinciden con sí mismos
    // Fusiona actividades que se solapan en al menos porcentajeSolapamientoMinimo
    final indicesToRemove = <int>{};
    for (int i = 0; i < activity.length; i++) {
      final actA = activity[i];
      final startA = actA['start'] as DateTime;
      final endA = actA['end'] as DateTime;
      final durationA = endA.difference(startA).inSeconds;

      for (int j = i + 1; j < activity.length; j++) {
        if (indicesToRemove.contains(j)) continue;
        final actB = activity[j];
        final startB = actB['start'] as DateTime;
        final endB = actB['end'] as DateTime;
        final durationB = endB.difference(startB).inSeconds;

        // Calcula el rango de solapamiento
        final overlapStart = startA.isAfter(startB) ? startA : startB;
        final overlapEnd = endA.isBefore(endB) ? endA : endB;
        final overlapDuration = overlapEnd.isAfter(overlapStart) ? overlapEnd.difference(overlapStart).inSeconds : 0;

        // Si el solapamiento es al menos el porcentaje mínimo para cualquiera de las dos actividades, elimina la más corta
        if (durationA > 0 && durationB > 0) {
          final overlapA = overlapDuration / durationA;
          final overlapB = overlapDuration / durationB;
          if (overlapA >= porcentajeSolapamientoMinimo || overlapB >= porcentajeSolapamientoMinimo) {
            // Elimina la actividad más corta para evitar duplicidad
            if (durationA <= durationB) {
              indicesToRemove.add(i);
            } else {
              indicesToRemove.add(j);
            }
          }
        }
      }
    }
    // Elimina las actividades marcadas para eliminar
    activity = [
      for (int i = 0; i < activity.length; i++)
        if (!indicesToRemove.contains(i)) activity[i]
    ];

    // Mergeo con MrFit
    // Si el entrenamiento de MrFit coincide en un 90% o más del tiempo con alguna actividad existente,
    // se elimina la actividad existente y se agrega el de MrFit.
    for (var entrenamiento in entrenamientosMrFit) {
      final start = entrenamiento['start'] as DateTime;
      final end = entrenamiento['end'] as DateTime;
      final duracionEntrenamiento = end.difference(start).inSeconds;

      // Busca actividades existentes que solapen significativamente con el entrenamiento de MrFit
      final indicesSolapados = <int>[];
      for (int i = 0; i < activity.length; i++) {
        final act = activity[i];
        final actStart = act['start'] as DateTime;
        final actEnd = act['end'] as DateTime;

        // Calcula el rango de solapamiento
        final overlapStart = start.isAfter(actStart) ? start : actStart;
        final overlapEnd = end.isBefore(actEnd) ? end : actEnd;
        final overlapDuration = overlapEnd.isAfter(overlapStart) ? overlapEnd.difference(overlapStart).inSeconds : 0;

        // Si el solapamiento es al menos el 90% de la duración del entrenamiento, marca para reemplazo
        if (duracionEntrenamiento > 0 && overlapDuration / duracionEntrenamiento >= porcentajeSolapamientoMinimo) {
          indicesSolapados.add(i);
        }
      }

      // Elimina las actividades solapadas y agrega el entrenamiento de MrFit
      if (indicesSolapados.isNotEmpty) {
        // Elimina de mayor a menor para evitar problemas de índices
        for (final idx in indicesSolapados.reversed) {
          activity.removeAt(idx);
        }
        activity.add(entrenamiento);
      } else {
        // Si no hay solapamiento significativo, simplemente agrega el entrenamiento
        activity.add(entrenamiento);
      }
    }

    activity.sort((a, b) => (b['start'] as DateTime).compareTo(a['start'] as DateTime));
    return activity;
  }

  Future<String> healthconnectRegistrarEntrenamiento(
    String titulo,
    DateTime inicio,
    DateTime fin,
    int kcalConsumidas,
  ) async {
    if (!await checkPermissionsFor("WORKOUT")) {
      return "0";
    }

    HealthWorkoutActivityType activityType = Platform.isIOS ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING : HealthWorkoutActivityType.WEIGHTLIFTING;

    await Health().writeWorkoutData(
      activityType: activityType,
      start: inicio,
      end: fin,
      totalEnergyBurned: kcalConsumidas,
      title: titulo,
    );

    final List<HealthDataPoint> workoutDataPoint = await _health.getHealthDataFromTypes(
      startTime: inicio,
      endTime: fin,
      types: [healthDataTypesString["WORKOUT"]!],
    );

    if (workoutDataPoint.isEmpty) {
      return "0";
    }

    final workout = workoutDataPoint.first;
    final workoutId = workout.uuid;

    return workoutId;
  }

  Future<bool> healthconnectRegistrarPasos(
    int steps,
    DateTime inicio,
    DateTime fin,
  ) async {
    await _health.configure();
    if (!await checkPermissionsFor("STEPS")) {
      return false;
    }

    try {
      final type = healthDataTypesString["STEPS"]!;
      return await _health.writeHealthData(
        value: steps.toDouble(),
        type: type,
        startTime: inicio,
        endTime: fin,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      Logger().e('Error writing steps to Health Connect: $e');
      return false;
    }
  }
}
