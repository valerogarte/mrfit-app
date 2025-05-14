part of 'usuario.dart';

class _TimeSection {
  DateTime start;
  DateTime end;
  List<HealthDataPoint> points;

  // Inicializa la sección con el primer datapoint
  _TimeSection(HealthDataPoint p)
      : start = p.dateFrom,
        end = p.dateTo,
        points = [p];
}

extension UsuarioMedalsExtension on Usuario {
  /// Devuelve los 5 valores más altos de: STEPS, DISTANCE_DELTA, WORKOUT (min), TOTAL_CALORIES_BURNED
  Future<Map<String, List<Map<String, dynamic>>>> getTop5Records({bool getFromCache = true}) async {
    if (getFromCache) {
      final cacheGet = await CustomCache.getByKey("medals");
      final cacheValue = cacheGet?.value;
      if (cacheValue != null && cacheValue is String && cacheValue.trim().isNotEmpty) {
        final cacheDecoded = jsonDecode(cacheValue);
        final cacheGetter = {
          "STEPS": (cacheDecoded["STEPS"] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
          "WORKOUT": (cacheDecoded["WORKOUT"] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
          "LONGEST_SESSIONS": (cacheDecoded["LONGEST_SESSIONS"] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
          "WEEKLY_STREAK": (cacheDecoded["WEEKLY_STREAK"] as List).map((e) => Map<String, dynamic>.from(e)).toList(),
        };

        // Return DEMO
        // return {
        //   "STEPS": [
        //     {"value": 23500, "date": "2024-06-01"},
        //     {"value": 21500, "date": "2024-05-28"},
        //     {"value": 31000, "date": "2024-05-20"},
        //     {"value": 40500, "date": "2024-05-15"},
        //     {"value": 56000, "date": "2024-05-10"},
        //   ],
        //   "WORKOUT": [
        //     {"value": 121, "date": "2024-06-02"},
        //     {"value": 80, "date": "2024-05-29"},
        //     {"value": 75, "date": "2024-05-21"},
        //     {"value": 60, "date": "2024-05-16"},
        //     {"value": 55, "date": "2024-05-11"},
        //   ],
        //   "LONGEST_SESSIONS": [
        //     {"value": 121, "date": "2024-06-03", "start": "2024-06-03T08:00:00", "end": "2024-06-03T10:00:00"},
        //     {"value": 181, "date": "2024-05-30", "start": "2024-05-30T09:00:00", "end": "2024-05-30T10:50:00"},
        //     {"value": 361, "date": "2024-05-22", "start": "2024-05-22T07:30:00", "end": "2024-05-22T09:10:00"},
        //     {"value": 95, "date": "2024-05-17", "start": "2024-05-17T18:00:00", "end": "2024-05-17T19:35:00"},
        //     {"value": 90, "date": "2024-05-12", "start": "2024-05-12T06:00:00", "end": "2024-05-12T07:30:00"},
        //   ],
        //   "WEEKLY_STREAK": [
        //     {"value": 6, "date": "2024-06-03", "goal": 150},
        //     {"value": 11, "date": "2024-05-27", "goal": 150},
        //     {"value": 4, "date": "2024-05-20", "goal": 150},
        //     {"value": 3, "date": "2024-05-13", "goal": 150},
        //     {"value": 2, "date": "2024-05-06", "goal": 150},
        //   ],
        // };

        return cacheGetter;
      }
    }

    int nDays = DateTime.now().difference(fechaNacimiento).inDays;
    if (nDays < 1) {
      nDays = 365;
    }

    // Top 5 pasos
    final stepsDataPoints = await getStepsByDate(DateFormat('yyyy-MM-dd').format(fechaNacimiento), nDays: nDays);
    final Map<DateTime, int> stepsByDay = {};
    for (var dp in stepsDataPoints) {
      final date = DateTime(dp.dateFrom.year, dp.dateFrom.month, dp.dateFrom.day);
      final steps = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0;
      stepsByDay[date] = (stepsByDay[date] ?? 0) + steps;
    }
    final stepsRecords = stepsByDay.entries.where((e) => e.value > 0).map((e) => {"value": e.value, "date": e.key}).toList();
    stepsRecords.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
    final topSteps = stepsRecords.take(5).toList();

    // Top 5 entrenamientos (minutos) por día (suma total de minutos por día)
    final entrenosMap = await getDailyTrainingsByDate(DateFormat('yyyy-MM-dd').format(fechaNacimiento), nDays: nDays);
    final Map<DateTime, int> workoutMinutesByDay = {};
    final List<Map<String, dynamic>> allSessions = [];
    entrenosMap.forEach((_, sesiones) {
      for (var dp in sesiones) {
        final mins = dp.dateTo.difference(dp.dateFrom).inMinutes;
        if (mins > 0) {
          // Para sesiones individuales (para LONGEST_SESSIONS)
          allSessions.add({
            "value": mins,
            "date": dp.dateFrom,
            "start": dp.dateFrom,
            "end": dp.dateTo,
          });
          // Para suma diaria (para WORKOUT)
          final date = DateTime(dp.dateFrom.year, dp.dateFrom.month, dp.dateFrom.day);
          workoutMinutesByDay[date] = (workoutMinutesByDay[date] ?? 0) + mins;
        }
      }
    });
    final workoutRecords = workoutMinutesByDay.entries.where((e) => e.value > 0).map((e) => {"value": e.value, "date": e.key}).toList();
    workoutRecords.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
    final topWorkouts = workoutRecords.take(5).toList();

    // Top 5 sesiones más largas de entrenamiento (LONGEST_SESSIONS)
    allSessions.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
    final topLongestSessions = allSessions.take(5).toList();

    // Número de semanas seguidas cumpliendo el objetivo de entrenamiento semanal (WEEKLY_STREAK)
    // Agrupar minutos por semana
    final Map<int, int> weekMinutes = {}; // key: weekNumberSinceBirth, value: totalMinutes
    final birthMonday = fechaNacimiento.subtract(Duration(days: fechaNacimiento.weekday - 1));
    workoutMinutesByDay.forEach((date, mins) {
      final weekNumber = date.difference(birthMonday).inDays ~/ 7;
      weekMinutes[weekNumber] = (weekMinutes[weekNumber] ?? 0) + mins;
    });

    // Calcular streak de semanas consecutivas cumpliendo el objetivo
    final objetivo = objetivoEntrenamientoSemanal ?? 0;
    List<Map<String, dynamic>> streaks = [];
    int streak = 0;
    DateTime? streakEndDate;
    int currentWeek = ((DateTime.now().difference(birthMonday).inDays) ~/ 7);
    for (int i = currentWeek; i >= 0; i--) {
      final mins = weekMinutes[i] ?? 0;
      if (mins >= objetivo && objetivo > 0) {
        streak++;
        streakEndDate ??= birthMonday.add(Duration(days: i * 7 + 6));
      } else {
        if (streak > 0) {
          streaks.add({
            "value": streak,
            "date": streakEndDate ?? birthMonday.add(Duration(days: i * 7 + 6)),
            "goal": objetivo,
          });
          streak = 0;
          streakEndDate = null;
        }
      }
    }
    // Si termina con una racha activa
    if (streak > 0) {
      streaks.add({
        "value": streak,
        "date": streakEndDate ?? DateTime.now(),
        "goal": objetivo,
      });
    }
    // Ordenar y tomar las 5 mejores rachas
    streaks.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
    final weeklyStreak = streaks.take(5).toList();

    final cache = {
      "STEPS": topSteps,
      "WORKOUT": topWorkouts,
      "LONGEST_SESSIONS": topLongestSessions,
      "WEEKLY_STREAK": weeklyStreak,
    };

    // Serializar DateTime a String para jsonEncode
    Map<String, List<Map<String, dynamic>>> cacheSerializable = {};
    cache.forEach((key, value) {
      cacheSerializable[key] = value.map((item) {
        final newItem = Map<String, dynamic>.from(item);
        if (newItem.containsKey('date') && newItem['date'] is DateTime) {
          newItem['date'] = (newItem['date'] as DateTime).toIso8601String();
        }
        if (newItem.containsKey('start') && newItem['start'] is DateTime) {
          newItem['start'] = (newItem['start'] as DateTime).toIso8601String();
        }
        if (newItem.containsKey('end') && newItem['end'] is DateTime) {
          newItem['end'] = (newItem['end'] as DateTime).toIso8601String();
        }
        return newItem;
      }).toList();
    });

    await CustomCache.set("medals", jsonEncode(cacheSerializable));

    return cache;
  }
}
