part of 'usuario.dart';

extension UsuarioMedalsExtension on Usuario {
  /// Devuelve los 5 valores más altos de: STEPS, DISTANCE_DELTA, WORKOUT (min), TOTAL_CALORIES_BURNED
  Future<Map<String, List<Map<String, dynamic>>>> getTop5Records({bool getFromCache = true}) async {
    if (getFromCache) {
      final cacheGet = await CustomCache.getByKey("medals");
      final cacheValue = cacheGet?.value;
      if (cacheValue != null && cacheValue.trim().isNotEmpty) {
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
    List<Map<String, Object>> topSteps = [];
    if (isHealthConnectAvailable) {
      final stepsDataPoints = await getStepsByDate(DateFormat('yyyy-MM-dd').format(fechaNacimiento), nDays: nDays);
      final Map<DateTime, int> stepsByDay = {};
      for (var dp in stepsDataPoints) {
        final date = DateTime(dp.dateFrom.year, dp.dateFrom.month, dp.dateFrom.day);
        final steps = dp.value is NumericHealthValue ? (dp.value as NumericHealthValue).numericValue.toInt() : 0;
        stepsByDay[date] = (stepsByDay[date] ?? 0) + steps;
      }
      final stepsRecords = stepsByDay.entries
          .where((e) => e.value > 0)
          .map((e) => {
                "value": e.value,
                "date": e.key.toIso8601String(),
              })
          .toList();
      stepsRecords.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
      topSteps = stepsRecords.take(5).toList();
    } else {
      topSteps = [
        {"value": 0, "date": "1970-01-01"},
      ];
    }

    // Top 5 entrenamientos (minutos) por día (suma total de minutos por día)
    List<Map<String, Object>> topWorkouts = [];
    final Map<DateTime, int> workoutMinutesByDay = {};
    final List<Map<String, dynamic>> allSessions = [];
    if (isHealthConnectAvailable) {
      final entrenosMap = await getDailyTrainingsByDate(DateFormat('yyyy-MM-dd').format(fechaNacimiento), nDays: nDays);
      entrenosMap.forEach((_, sesiones) {
        for (var dp in sesiones) {
          final mins = dp.dateTo.difference(dp.dateFrom).inMinutes;
          if (mins > 0) {
            // Para sesiones individuales (para LONGEST_SESSIONS)
            allSessions.add({
              "value": mins,
              "date": dp.dateFrom.toIso8601String(),
              "start": dp.dateFrom.toIso8601String(),
              "end": dp.dateTo.toIso8601String(),
            });
            // Para suma diaria (para WORKOUT)
            final date = DateTime(dp.dateFrom.year, dp.dateFrom.month, dp.dateFrom.day);
            workoutMinutesByDay[date] = (workoutMinutesByDay[date] ?? 0) + mins;
          }
        }
      });
      final workoutRecords = workoutMinutesByDay.entries
          .where((e) => e.value > 0)
          .map((e) => {
                "value": e.value,
                "date": e.key.toIso8601String(), // Siempre string ISO
              })
          .toList();
      workoutRecords.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
      topWorkouts = workoutRecords.take(5).toList();
    } else {
      topWorkouts = [
        {"value": 0, "date": "1970-01-01"},
      ];
    }

    // Top 5 sesiones más largas de entrenamiento (LONGEST_SESSIONS)
    List<Map<String, dynamic>> topLongestSessions = [];
    if (isHealthConnectAvailable && allSessions.isNotEmpty) {
      allSessions.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
      // Ya están como string ISO arriba
      topLongestSessions = allSessions.take(5).toList();
    } else {
      topLongestSessions = [
        {"value": 0, "date": "1970-01-01", "start": "1970-01-01", "end": "1970-01-01"},
      ];
    }

    // Número de semanas seguidas cumpliendo el objetivo de entrenamiento semanal (WEEKLY_STREAK)
    final weeklyStreak = await fetchAndUpdateWeeklyStreaks();

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

    return cacheSerializable;
  }

  /// Verifica si el valor dado para la key es un récord, lo añade si corresponde y actualiza el cache.
  Future<bool> isRecord(String key, dynamic value, DateTime date) async {
    // Obtener cache de records
    final cacheGet = await CustomCache.getByKey("medals");
    Map<String, List<Map<String, dynamic>>> cacheDecoded;
    bool cacheWasEmpty = false;

    if (cacheGet?.value == null || (cacheGet?.value)?.trim().isEmpty == true) {
      // Inicializar cache vacío
      cacheDecoded = {
        "STEPS": [],
        "WORKOUT": [],
        "LONGEST_SESSIONS": [],
        "WEEKLY_STREAK": [],
      };
      cacheWasEmpty = true;
    } else {
      final raw = jsonDecode(cacheGet?.value ?? '{}');
      cacheDecoded = {
        "STEPS": (raw["STEPS"] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
        "WORKOUT": (raw["WORKOUT"] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
        "LONGEST_SESSIONS": (raw["LONGEST_SESSIONS"] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
        "WEEKLY_STREAK": (raw["WEEKLY_STREAK"] as List? ?? []).map((e) => Map<String, dynamic>.from(e)).toList(),
      };
    }

    // Determinar si es récord
    final List<Map<String, dynamic>> records = cacheDecoded[key] ?? [];
    bool isRecord = false;
    // Normalizar valor para comparar
    int newValue = value is int ? value : (value is num ? value.toInt() : 0);

    // Si el cache está vacío, añadir el primer récord
    if (records.isEmpty) {
      final record = {
        "value": newValue,
        "date": date.toIso8601String(),
      };
      cacheDecoded[key] = [record];
      isRecord = true;
    } else {
      // Revisar si el valor es mayor que alguno de los top 5
      final sorted = List<Map<String, dynamic>>.from(records)..sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
      if (sorted.length < 5 || newValue > (sorted.last['value'] as int)) {
        // Añadir y mantener top 5
        final record = {
          "value": newValue,
          "date": date.toIso8601String(),
        };
        records.add(record);
        records.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
        cacheDecoded[key] = records.take(5).toList();
        isRecord = true;
      }
    }

    // Guardar cache actualizado si hubo cambios
    if (isRecord || cacheWasEmpty) {
      await CustomCache.set("medals", jsonEncode(cacheDecoded));
    }

    return isRecord;
  }

  /// Actualiza la racha semanal de entrenamientos y devuelve los resultados.
  Future<List<Map<String, dynamic>>> fetchAndUpdateWeeklyStreaks() async {
    final objetivo = objetivoEntrenamientoSemanal;
    if (objetivo <= 0) {
      return [];
    }

    // Obtener cache actual para depués buscar en bbdd desde la última fecha cacheada
    Map<String, List<Map<String, dynamic>>> cacheDecoded;

    cacheDecoded = {
      "STEPS": [],
      "WORKOUT": [],
      "LONGEST_SESSIONS": [],
      "WEEKLY_STREAK": [],
    };

    // Acceso a la base de datos usando DatabaseHelper
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> results;

    results = await db.rawQuery(
      '''
        SELECT inicio, fin FROM entrenamiento_entrenamiento
        WHERE usuario_id = ?
        ORDER BY inicio ASC
        ''',
      [id],
    );

    if (results.isEmpty) {
      return cacheDecoded["WEEKLY_STREAK"] ?? [];
    }

    // Agrupa entrenamientos por semana, considerando que la semana inicia en lunes.
    final Map<int, int> entrenosPorSemana = {};
    // Encuentra el lunes anterior o igual a la fecha de nacimiento.
    final birthMonday = fechaNacimiento.subtract(Duration(days: fechaNacimiento.weekday - 1));
    DateTime? lastEntrenamientoDate;
    bool entrenamientoActivo = false;

    for (var row in results) {
      final inicio = row['inicio'];
      final fin = row['fin'];
      final date = inicio is DateTime ? inicio : DateTime.tryParse(inicio.toString());
      if (date != null) {
        // Calcula el lunes de la semana del entrenamiento.
        final weekMonday = date.subtract(Duration(days: date.weekday - 1));
        final weekNumber = weekMonday.difference(birthMonday).inDays ~/ 7;
        entrenosPorSemana[weekNumber] = (entrenosPorSemana[weekNumber] ?? 0) + 1;
        // Guarda la fecha del último entrenamiento.
        if (lastEntrenamientoDate == null || date.isAfter(lastEntrenamientoDate)) {
          lastEntrenamientoDate = date;
          entrenamientoActivo = fin == null;
        }
      }
    }

    // Buscar todas las rachas de semanas consecutivas cumpliendo el objetivo
    List<Map<String, dynamic>> streaks = [];
    int streak = 0;
    DateTime? streakEndDate;
    int currentWeek = ((DateTime.now().difference(birthMonday).inDays) ~/ 7);

    for (int i = 0; i <= currentWeek; i++) {
      final entrenos = entrenosPorSemana[i] ?? 0;
      if (entrenos >= objetivo) {
        streak++;
        streakEndDate = birthMonday.add(Duration(days: i * 7 + 6));
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

    // Si termina con una racha activa, comprobar si el último entrenamiento sigue activo y es de la semana actual
    if (streak > 0) {
      DateTime fechaFinRacha = streakEndDate ?? DateTime.now();
      // Si el último entrenamiento está activo y es de la semana actual, extiende la racha hasta hoy
      if (entrenamientoActivo && lastEntrenamientoDate != null) {
        final lastWeek = lastEntrenamientoDate.difference(birthMonday).inDays ~/ 7;
        if (lastWeek == currentWeek) {
          fechaFinRacha = DateTime.now();
        }
      }
      streaks.add({
        "value": streak,
        "date": fechaFinRacha,
        "goal": objetivo,
      });
    }

    // Filtrar para que solo haya una racha por valor, y que sea la más antigua
    final Map<int, Map<String, dynamic>> uniqueStreaks = {};
    for (final s in streaks) {
      final value = s['value'] as int;
      if (!uniqueStreaks.containsKey(value) || (s['date'] as DateTime).isBefore(uniqueStreaks[value]!['date'] as DateTime)) {
        uniqueStreaks[value] = s;
      }
    }

    // Ordenar por valor descendente y tomar las 5 mejores rachas
    final topStreaks = uniqueStreaks.values.toList()..sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
    final top5 = topStreaks.take(5).toList();

    // Comprobar si hay algún récord nuevo respecto al cache
    bool isRecord = false;
    final cachedValues = (cacheDecoded["WEEKLY_STREAK"] ?? []).map((e) => e['value'] as int).toSet();
    for (final streak in top5) {
      if (!cachedValues.contains(streak['value'])) {
        isRecord = true;
        break;
      }
    }

    // Actualizar cache si hay récord
    if (isRecord) {
      cacheDecoded["WEEKLY_STREAK"] = top5.map((s) {
        final item = Map<String, dynamic>.from(s);
        if (item['date'] is DateTime) {
          item['date'] = (item['date'] as DateTime).toIso8601String();
        }
        return item;
      }).toList();
      await CustomCache.set("medals", jsonEncode(cacheDecoded));
    }

    return cacheDecoded["WEEKLY_STREAK"] ?? [];
  }
}
