import 'package:logger/logger.dart';
import 'package:mrfit/data/database_helper.dart';
import 'ejercicio/ejercicio.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';

class ModeloDatos {
  Future<Map<String, dynamic>?> getDatosFiltrosEjercicios() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> musculos = await db.query('ejercicios_musculo');
      final List<Map<String, dynamic>> equipamientos = await db.query('ejercicios_equipamiento');
      final List<Map<String, dynamic>> categorias = await db.query('ejercicios_categoria');

      return {
        'musculos': musculos,
        'equipamientos': equipamientos,
        'categorias': categorias,
      };
    } catch (e) {
      Logger().e('Error en getDatosFiltrosEjercicios: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getMusculos() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.query('ejercicios_musculo');
    } catch (e) {
      Logger().e('Error en getMusculos: $e');
      return null;
    }
  }

  Future<List<Ejercicio>?> buscarEjercicios(Map<String, String> filtros) async {
    try {
      final db = await DatabaseHelper.instance.database;

      List<String> condiciones = [];
      List<dynamic> argumentos = [];

      if ((filtros['nombre'] ?? '').isNotEmpty) {
        condiciones.add("nombre LIKE ?");
        argumentos.add("%${filtros['nombre']}%");
      }

      if ((filtros['categoria'] ?? '').isNotEmpty) {
        condiciones.add("categoria_id = ?");
        argumentos.add(filtros['categoria']);
      }

      if ((filtros['equipamiento'] ?? '').isNotEmpty) {
        condiciones.add("equipamiento_id = ?");
        argumentos.add(filtros['equipamiento']);
      }

      if ((filtros['musculo_primario'] ?? '').isNotEmpty) {
        condiciones.add("EXISTS (SELECT 1 FROM ejercicios_ejerciciomusculo em WHERE em.ejercicio_id = e.id AND em.tipo = 'P' AND em.musculo_id = ?)");
        argumentos.add(filtros['musculo_primario']);
      }

      if ((filtros['musculo_secundario'] ?? '').isNotEmpty) {
        condiciones.add("EXISTS (SELECT 1 FROM ejercicios_ejerciciomusculo em WHERE em.ejercicio_id = e.id AND em.tipo <> 'P' AND em.musculo_id = ?)");
        argumentos.add(filtros['musculo_secundario']);
      }

      // Build base query without ORDER BY.
      String query = '''
        SELECT e.*,
               d.titulo AS dificultad,
          (SELECT group_concat(m.titulo, ', ') 
           FROM ejercicios_ejerciciomusculo em
           INNER JOIN ejercicios_musculo m ON m.id = em.musculo_id 
           WHERE em.ejercicio_id = e.id AND em.tipo = 'P'
          ) as primary_musculos
        FROM ejercicios_ejercicio e
        LEFT JOIN ejercicios_dificultad d ON d.id = e.dificultad_id
      ''';

      if (condiciones.isNotEmpty) {
        query += " WHERE ${condiciones.join(" AND ")}";
      }
      // Append ORDER BY after the optional WHERE clause.
      query += " ORDER BY e.nombre";

      final List<Map<String, dynamic>> resultados = await db.rawQuery(query, argumentos);

      final List<Map<String, dynamic>> mutableResults = resultados.map((row) {
        var mutable = Map<String, dynamic>.from(row);
        // Si no existen datos en musculos_involucrados, usar primary_musculos
        if ((mutable['musculos_involucrados'] == null || (mutable['musculos_involucrados'] is String && (mutable['musculos_involucrados'] as String).isEmpty)) &&
            mutable['primary_musculos'] != null &&
            (mutable['primary_musculos'] as String).isNotEmpty) {
          final titles = (mutable['primary_musculos'] as String).split(',').map((s) => s.trim()).toList();
          mutable['musculos_involucrados'] = titles
              .map((titulo) => {
                    'id': 0,
                    'porcentajeImplicacion': 100,
                    'tipo': 'P',
                    'musculo': {'id': 0, 'titulo': titulo, 'imagen': ''}
                  })
              .toList();
        } else if (mutable['musculos_involucrados'] == null) {
          mutable['musculos_involucrados'] = [];
        }
        // Eliminar campo temporal de primary_musculos
        mutable.remove('primary_musculos');

        // Agregar el nivel de dificultad como objeto anidado
        if (mutable.containsKey('dificultad')) {
          mutable['dificultad'] = {'id': mutable['dificultad_id'] ?? 0, 'titulo': mutable['dificultad'] ?? ''};
        }

        return mutable;
      }).toList();

      final objetoEjercicios = mutableResults.map((json) => Ejercicio.fromJson(json)).toList();
      return objetoEjercicios;
    } catch (e) {
      Logger().e('Error en buscarEjercicios: $e');
      return null;
    }
  }

  static dynamic getDifficultyOptions({int? value}) {
    List<Map<String, dynamic>> options = [
      {
        'value': 1,
        'label': 'A mínimos',
        'description': 'Mínimo esfuerzo',
        'iconColor': Color.fromARGB(255, 145, 231, 148),
        'met': 2.5,
      },
      {
        'value': 2,
        'label': 'Ligero',
        'description': 'Pude haber hecho entre 4-6 repeticiones más',
        'iconColor': Colors.lightGreen,
        'met': 3.0,
      },
      {
        'value': 3,
        'label': 'Moderado',
        'description': 'Podría haber hecho 3 repeticiones más',
        'iconColor': Colors.yellow,
        'met': 3.5,
      },
      {
        'value': 4,
        'label': 'Intenso',
        'description': 'Podría haber hecho 2 repeticiones más',
        'iconColor': Colors.orange,
        'met': 4.5,
      },
      {
        'value': 5,
        'label': 'Al límite',
        'description': 'Podría haber hecho 1 repetición más',
        'iconColor': Colors.red,
        'met': 5.0,
      },
      {
        'value': 6,
        'label': 'Al fallo',
        'description': 'No pude hacer más repeticiones',
        'iconColor': Colors.purple.shade500,
        'met': 6.0,
      },
    ];

    if (value != null) {
      return options.firstWhere((option) => option['value'] == value);
    }

    return options;
  }

  // Helper method to get rating text based on value
  static String getSensacionText(double value) {
    if (value == -3) return "Día para el olvido";
    if (value == -2) return "Un poco por debajo de tu ritmo";
    if (value == -1) return "Ligeramente apagado";
    if (value == 0) return "Día normal, equilibrado";
    if (value == 1) return "Buen ritmo, se nota el esfuerzo";
    if (value == 2) return "Día enérgico y productivo";
    if (value == 3) return "¡Día espectacular!";
    return "";
  }

  // Función para matchear workoutActivityType
  Map<String, dynamic> getActivityTypeDetails(String activityType) {
    switch (activityType) {
      case "HealthWorkoutActivityType.OTHER":
        return {
          'icon': Icons.fitness_center,
          'nombre': "Entrenamiento",
        };
      case "HealthWorkoutActivityType.RUNNING":
        return {
          'icon': Icons.directions_run,
          'nombre': "Correr",
        };
      case "HealthWorkoutActivityType.WALKING":
        return {
          'icon': Icons.directions_walk,
          'nombre': "Caminar",
        };
      case "HealthWorkoutActivityType.WEIGHTLIFTING":
        return {
          'icon': Icons.fitness_center,
          'nombre': "Pesas",
        };
      default:
        return {
          'icon': Icons.fitness_center,
          'nombre': activityType,
        };
    }
  }

  // Map de tipos compatibles para Health Connect
  Map<String, HealthDataType> get healthDataTypesString => {
        "ACTIVE_ENERGY_BURNED": HealthDataType.ACTIVE_ENERGY_BURNED,
        "BLOOD_GLUCOSE": HealthDataType.BLOOD_GLUCOSE,
        "BLOOD_OXYGEN": HealthDataType.BLOOD_OXYGEN,
        "BLOOD_PRESSURE_DIASTOLIC": HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        "BLOOD_PRESSURE_SYSTOLIC": HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        "BODY_FAT_PERCENTAGE": HealthDataType.BODY_FAT_PERCENTAGE,
        "LEAN_BODY_MASS": HealthDataType.LEAN_BODY_MASS,
        "BODY_MASS_INDEX": HealthDataType.BODY_MASS_INDEX,
        "BODY_TEMPERATURE": HealthDataType.BODY_TEMPERATURE,
        "BODY_WATER_MASS": HealthDataType.BODY_WATER_MASS,
        "HEART_RATE": HealthDataType.HEART_RATE,
        "HEART_RATE_VARIABILITY_RMSSD": HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
        "HEIGHT": HealthDataType.HEIGHT,
        "STEPS": HealthDataType.STEPS,
        "WEIGHT": HealthDataType.WEIGHT,
        "DISTANCE_DELTA": HealthDataType.DISTANCE_DELTA,
        "SLEEP_ASLEEP": HealthDataType.SLEEP_ASLEEP,
        "SLEEP_AWAKE_IN_BED": HealthDataType.SLEEP_AWAKE_IN_BED,
        "SLEEP_AWAKE": HealthDataType.SLEEP_AWAKE,
        "SLEEP_DEEP": HealthDataType.SLEEP_DEEP,
        "SLEEP_LIGHT": HealthDataType.SLEEP_LIGHT,
        "SLEEP_OUT_OF_BED": HealthDataType.SLEEP_OUT_OF_BED,
        "SLEEP_REM": HealthDataType.SLEEP_REM,
        "SLEEP_SESSION": HealthDataType.SLEEP_SESSION,
        "SLEEP_UNKNOWN": HealthDataType.SLEEP_UNKNOWN,
        "WATER": HealthDataType.WATER,
        "WORKOUT": HealthDataType.WORKOUT,
        "RESTING_HEART_RATE": HealthDataType.RESTING_HEART_RATE,
        "FLIGHTS_CLIMBED": HealthDataType.FLIGHTS_CLIMBED,
        "BASAL_ENERGY_BURNED": HealthDataType.BASAL_ENERGY_BURNED,
        "RESPIRATORY_RATE": HealthDataType.RESPIRATORY_RATE,
        "NUTRITION": HealthDataType.NUTRITION,
        "TOTAL_CALORIES_BURNED": HealthDataType.TOTAL_CALORIES_BURNED,
        "MENSTRUATION_FLOW": HealthDataType.MENSTRUATION_FLOW,
      };

  Map<String, HealthDataAccess> get healthDataPermissions => {
        "ACTIVE_ENERGY_BURNED": HealthDataAccess.READ_WRITE,
        "BLOOD_GLUCOSE": HealthDataAccess.READ_WRITE,
        "BLOOD_OXYGEN": HealthDataAccess.READ_WRITE,
        "BLOOD_PRESSURE_DIASTOLIC": HealthDataAccess.READ_WRITE,
        "BLOOD_PRESSURE_SYSTOLIC": HealthDataAccess.READ_WRITE,
        "BODY_FAT_PERCENTAGE": HealthDataAccess.READ_WRITE,
        "LEAN_BODY_MASS": HealthDataAccess.READ_WRITE,
        "BODY_MASS_INDEX": HealthDataAccess.READ_WRITE,
        "BODY_TEMPERATURE": HealthDataAccess.READ_WRITE,
        "BODY_WATER_MASS": HealthDataAccess.READ_WRITE,
        "HEART_RATE": HealthDataAccess.READ_WRITE,
        "HEART_RATE_VARIABILITY_RMSSD": HealthDataAccess.READ_WRITE,
        "HEIGHT": HealthDataAccess.READ_WRITE,
        "STEPS": HealthDataAccess.READ_WRITE,
        "WEIGHT": HealthDataAccess.READ_WRITE,
        "DISTANCE_DELTA": HealthDataAccess.READ_WRITE,
        "SLEEP_ASLEEP": HealthDataAccess.READ_WRITE,
        "SLEEP_AWAKE_IN_BED": HealthDataAccess.READ_WRITE,
        "SLEEP_AWAKE": HealthDataAccess.READ_WRITE,
        "SLEEP_DEEP": HealthDataAccess.READ_WRITE,
        "SLEEP_LIGHT": HealthDataAccess.READ_WRITE,
        "SLEEP_OUT_OF_BED": HealthDataAccess.READ_WRITE,
        "SLEEP_REM": HealthDataAccess.READ_WRITE,
        "SLEEP_SESSION": HealthDataAccess.READ_WRITE,
        "SLEEP_UNKNOWN": HealthDataAccess.READ_WRITE,
        "WATER": HealthDataAccess.READ_WRITE,
        "WORKOUT": HealthDataAccess.READ_WRITE,
        "RESTING_HEART_RATE": HealthDataAccess.READ_WRITE,
        "FLIGHTS_CLIMBED": HealthDataAccess.READ_WRITE,
        "BASAL_ENERGY_BURNED": HealthDataAccess.READ_WRITE,
        "RESPIRATORY_RATE": HealthDataAccess.READ_WRITE,
        "NUTRITION": HealthDataAccess.READ_WRITE,
        "TOTAL_CALORIES_BURNED": HealthDataAccess.READ_WRITE,
        "MENSTRUATION_FLOW": HealthDataAccess.READ_WRITE,
      };
}
