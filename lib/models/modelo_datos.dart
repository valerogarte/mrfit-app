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

      // Búsqueda flexible por nombre: todas las palabras deben estar presentes en cualquier orden
      if ((filtros['nombre'] ?? '').isNotEmpty) {
        final palabras = filtros['nombre']!.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        for (final palabra in palabras) {
          condiciones.add("LOWER(e.nombre) LIKE ?");
          argumentos.add("%$palabra%");
        }
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
    // Opciones de dificultad predefinidas
    List<Map<String, dynamic>> options = [
      {
        'value': 1,
        'label': 'A mínimos',
        'description': 'Sin apenas esfuerzo',
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
      // Busca la opción correspondiente, si no existe devuelve una opción por defecto
      return options.firstWhere(
        (option) => option['value'] == value,
        orElse: () => {
          'value': 1,
          'label': 'Sin valor',
          'iconColor': Color.fromARGB(255, 145, 231, 148),
          'met': 2.5,
        },
      );
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
      case "HealthWorkoutActivityType.AMERICAN_FOOTBALL":
        return {'icon': Icons.sports_football, 'nombre': "Fútbol americano"};
      case "HealthWorkoutActivityType.ARCHERY":
        return {'icon': Icons.add_circle, 'nombre': "Tiro con arco"};
      case "HealthWorkoutActivityType.AUSTRALIAN_FOOTBALL":
        return {'icon': Icons.sports_football, 'nombre': "Fútbol australiano"};
      case "HealthWorkoutActivityType.BADMINTON":
        return {'icon': Icons.sports_tennis, 'nombre': "Bádminton"};
      case "HealthWorkoutActivityType.BARRE":
        return {'icon': Icons.fitness_center, 'nombre': "Barre"};
      case "HealthWorkoutActivityType.BASEBALL":
        return {'icon': Icons.sports_baseball, 'nombre': "Béisbol"};
      case "HealthWorkoutActivityType.BASKETBALL":
        return {'icon': Icons.sports_basketball, 'nombre': "Baloncesto"};
      case "HealthWorkoutActivityType.BIKING":
        return {'icon': Icons.directions_bike, 'nombre': "Ciclismo"};
      case "HealthWorkoutActivityType.BOWLING":
        return {'icon': Icons.sports_sharp, 'nombre': "Bolos"};
      case "HealthWorkoutActivityType.BOXING":
        return {'icon': Icons.sports_mma, 'nombre': "Boxeo"};
      case "HealthWorkoutActivityType.CALISTHENICS":
        return {'icon': Icons.fitness_center, 'nombre': "Calistenia"};
      case "HealthWorkoutActivityType.CARDIO_DANCE":
        return {'icon': Icons.self_improvement, 'nombre': "Cardio dance"};
      case "HealthWorkoutActivityType.CLIMBING":
        return {'icon': Icons.terrain, 'nombre': "Escalada"};
      case "HealthWorkoutActivityType.COOLDOWN":
        return {'icon': Icons.fitness_center, 'nombre': "Enfriamiento"};
      case "HealthWorkoutActivityType.CORE_TRAINING":
        return {'icon': Icons.fitness_center, 'nombre': "Entrenamiento de core"};
      case "HealthWorkoutActivityType.CRICKET":
        return {'icon': Icons.sports_cricket, 'nombre': "Críquet"};
      case "HealthWorkoutActivityType.CROSS_COUNTRY_SKIING":
        return {'icon': Icons.downhill_skiing, 'nombre': "Esquí de fondo"};
      case "HealthWorkoutActivityType.CROSS_TRAINING":
        return {'icon': Icons.fitness_center, 'nombre': "Entrenamiento cruzado"};
      case "HealthWorkoutActivityType.CURLING":
        return {'icon': Icons.sports, 'nombre': "Curling"};
      case "HealthWorkoutActivityType.DANCING":
        return {'icon': Icons.music_note, 'nombre': "Baile"};
      case "HealthWorkoutActivityType.DISC_SPORTS":
        return {'icon': Icons.sports, 'nombre': "Deportes de disco"};
      case "HealthWorkoutActivityType.DOWNHILL_SKIING":
        return {'icon': Icons.downhill_skiing, 'nombre': "Esquí alpino"};
      case "HealthWorkoutActivityType.ELLIPTICAL":
        return {'icon': Icons.fitness_center, 'nombre': "Elíptica"};
      case "HealthWorkoutActivityType.EQUESTRIAN_SPORTS":
        return {'icon': Icons.fitness_center, 'nombre': "Equitación"};
      case "HealthWorkoutActivityType.FENCING":
        return {'icon': Icons.fitness_center, 'nombre': "Esgrima"};
      case "HealthWorkoutActivityType.FISHING":
        return {'icon': Icons.anchor, 'nombre': "Pesca"};
      case "HealthWorkoutActivityType.FITNESS_GAMING":
        return {'icon': Icons.sports_esports, 'nombre': "Fitness gaming"};
      case "HealthWorkoutActivityType.FLEXIBILITY":
        return {'icon': Icons.self_improvement, 'nombre': "Flexibilidad"};
      case "HealthWorkoutActivityType.FRISBEE_DISC":
        return {'icon': Icons.sports, 'nombre': "Disco volador"};
      case "HealthWorkoutActivityType.FUNCTIONAL_STRENGTH_TRAINING":
        return {'icon': Icons.fitness_center, 'nombre': "Fuerza funcional"};
      case "HealthWorkoutActivityType.GOLF":
        return {'icon': Icons.sports_golf, 'nombre': "Golf"};
      case "HealthWorkoutActivityType.GUIDED_BREATHING":
        return {'icon': Icons.bubble_chart, 'nombre': "Respiración guiada"};
      case "HealthWorkoutActivityType.GYMNASTICS":
        return {'icon': Icons.fitness_center, 'nombre': "Gimnasia"};
      case "HealthWorkoutActivityType.HAND_CYCLING":
        return {'icon': Icons.directions_bike, 'nombre': "Ciclismo de mano"};
      case "HealthWorkoutActivityType.HANDBALL":
        return {'icon': Icons.sports_handball, 'nombre': "Balonmano"};
      case "HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING":
        return {'icon': Icons.fitness_center, 'nombre': "HIIT"};
      case "HealthWorkoutActivityType.HIKING":
        return {'icon': Icons.explore, 'nombre': "Senderismo"};
      case "HealthWorkoutActivityType.HOCKEY":
        return {'icon': Icons.sports_hockey, 'nombre': "Hockey"};
      case "HealthWorkoutActivityType.HUNTING":
        return {'icon': Icons.fitness_center, 'nombre': "Caza"};
      case "HealthWorkoutActivityType.JUMP_ROPE":
        return {'icon': Icons.fitness_center, 'nombre': "Comba"};
      case "HealthWorkoutActivityType.KICKBOXING":
        return {'icon': Icons.sports_mma, 'nombre': "Kickboxing"};
      case "HealthWorkoutActivityType.LACROSSE":
        return {'icon': Icons.fitness_center, 'nombre': "Lacrosse"};
      case "HealthWorkoutActivityType.MARTIAL_ARTS":
        return {'icon': Icons.sports_mma, 'nombre': "Artes marciales"};
      case "HealthWorkoutActivityType.MIND_AND_BODY":
        return {'icon': Icons.self_improvement, 'nombre': "Mente y cuerpo"};
      case "HealthWorkoutActivityType.MIXED_CARDIO":
        return {'icon': Icons.fitness_center, 'nombre': "Cardio mixto"};
      case "HealthWorkoutActivityType.PADDLE_SPORTS":
        return {'icon': Icons.rowing, 'nombre': "Deportes de pala"};
      case "HealthWorkoutActivityType.PARAGLIDING":
        return {'icon': Icons.flight, 'nombre': "Parapente"};
      case "HealthWorkoutActivityType.PICKLEBALL":
        return {'icon': Icons.fitness_center, 'nombre': "Pickleball"};
      case "HealthWorkoutActivityType.PILATES":
        return {'icon': Icons.self_improvement, 'nombre': "Pilates"};
      case "HealthWorkoutActivityType.PLAY":
        return {'icon': Icons.sports, 'nombre': "Juego"};
      case "HealthWorkoutActivityType.PREPARATION_AND_RECOVERY":
        return {'icon': Icons.fitness_center, 'nombre': "Preparación y recuperación"};
      case "HealthWorkoutActivityType.RACQUETBALL":
        return {'icon': Icons.sports, 'nombre': "Ráquetbol"};
      case "HealthWorkoutActivityType.ROCK_CLIMBING":
        return {'icon': Icons.terrain, 'nombre': "Escalada en roca"};
      case "HealthWorkoutActivityType.ROWING":
        return {'icon': Icons.rowing, 'nombre': "Remo"};
      case "HealthWorkoutActivityType.RUGBY":
        return {'icon': Icons.sports_rugby, 'nombre': "Rugby"};
      case "HealthWorkoutActivityType.RUNNING":
        return {'icon': Icons.directions_run, 'nombre': "Correr"};
      case "HealthWorkoutActivityType.RUNNING_TREADMILL":
        return {'icon': Icons.directions_run, 'nombre': "Cinta de correr"};
      case "HealthWorkoutActivityType.SAILING":
        return {'icon': Icons.directions_boat, 'nombre': "Vela"};
      case "HealthWorkoutActivityType.SCUBA_DIVING":
        return {'icon': Icons.pool, 'nombre': "Buceo"};
      case "HealthWorkoutActivityType.SKATING":
        return {'icon': Icons.skateboarding, 'nombre': "Patinaje"};
      case "HealthWorkoutActivityType.SKIING":
        return {'icon': Icons.downhill_skiing, 'nombre': "Esquí"};
      case "HealthWorkoutActivityType.SNOW_SPORTS":
        return {'icon': Icons.downhill_skiing, 'nombre': "Deportes de nieve"};
      case "HealthWorkoutActivityType.SNOWBOARDING":
        return {'icon': Icons.downhill_skiing, 'nombre': "Snowboard"};
      case "HealthWorkoutActivityType.SOCCER":
        return {'icon': Icons.sports_soccer, 'nombre': "Fútbol"};
      case "HealthWorkoutActivityType.SOCIAL_DANCE":
        return {'icon': Icons.music_note, 'nombre': "Baile social"};
      case "HealthWorkoutActivityType.SOFTBALL":
        return {'icon': Icons.sports_baseball, 'nombre': "Softbol"};
      case "HealthWorkoutActivityType.SQUASH":
        return {'icon': Icons.sports_tennis, 'nombre': "Squash"};
      case "HealthWorkoutActivityType.STAIR_CLIMBING":
        return {'icon': Icons.stairs, 'nombre': "Subida de escaleras"};
      case "HealthWorkoutActivityType.STAIR_CLIMBING_MACHINE":
        return {'icon': Icons.stairs, 'nombre': "Máquina de escaleras"};
      case "HealthWorkoutActivityType.STAIRS":
        return {'icon': Icons.stairs, 'nombre': "Escaleras"};
      case "HealthWorkoutActivityType.STEP_TRAINING":
        return {'icon': Icons.directions_walk, 'nombre': "Entrenamiento de pasos"};
      case "HealthWorkoutActivityType.STRENGTH_TRAINING":
        return {'icon': Icons.fitness_center, 'nombre': "Entrenamiento de fuerza"};
      case "HealthWorkoutActivityType.SURFING":
        return {'icon': Icons.pool, 'nombre': "Surf"};
      case "HealthWorkoutActivityType.SWIMMING":
        return {'icon': Icons.pool, 'nombre': "Natación"};
      case "HealthWorkoutActivityType.SWIMMING_OPEN_WATER":
        return {'icon': Icons.pool, 'nombre': "Aguas abiertas"};
      case "HealthWorkoutActivityType.SWIMMING_POOL":
        return {'icon': Icons.pool, 'nombre': "Piscina"};
      case "HealthWorkoutActivityType.TABLE_TENNIS":
        return {'icon': Icons.sports_tennis, 'nombre': "Tenis de mesa"};
      case "HealthWorkoutActivityType.TAI_CHI":
        return {'icon': Icons.self_improvement, 'nombre': "Tai chi"};
      case "HealthWorkoutActivityType.TENNIS":
        return {'icon': Icons.sports_tennis, 'nombre': "Tenis"};
      case "HealthWorkoutActivityType.TRACK_AND_FIELD":
        return {'icon': Icons.directions_run, 'nombre': "Atletismo"};
      case "HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING":
        return {'icon': Icons.fitness_center, 'nombre': "Fuerza tradicional"};
      case "HealthWorkoutActivityType.UNDERWATER_DIVING":
        return {'icon': Icons.pool, 'nombre': "Buceo submarino"};
      case "HealthWorkoutActivityType.VOLLEYBALL":
        return {'icon': Icons.sports_volleyball, 'nombre': "Vóley"};
      case "HealthWorkoutActivityType.WALKING":
        return {'icon': Icons.directions_walk, 'nombre': "Caminar"};
      case "HealthWorkoutActivityType.WATER_FITNESS":
        return {'icon': Icons.pool, 'nombre': "Aquafitness"};
      case "HealthWorkoutActivityType.WATER_POLO":
        return {'icon': Icons.pool, 'nombre': "Waterpolo"};
      case "HealthWorkoutActivityType.WATER_SPORTS":
        return {'icon': Icons.pool, 'nombre': "Deportes acuáticos"};
      case "HealthWorkoutActivityType.WEIGHTLIFTING":
        return {'icon': Icons.fitness_center, 'nombre': "Levantamiento de pesas"};
      case "HealthWorkoutActivityType.WHEELCHAIR":
        return {'icon': Icons.accessible, 'nombre': "Silla de ruedas"};
      case "HealthWorkoutActivityType.WHEELCHAIR_RUN_PACE":
        return {'icon': Icons.accessible, 'nombre': "Correr en silla"};
      case "HealthWorkoutActivityType.WHEELCHAIR_WALK_PACE":
        return {'icon': Icons.accessible, 'nombre': "Caminar en silla"};
      case "HealthWorkoutActivityType.WRESTLING":
        return {'icon': Icons.sports_mma, 'nombre': "Lucha"};
      case "HealthWorkoutActivityType.YOGA":
        return {'icon': Icons.self_improvement, 'nombre': "Yoga"};
      case "HealthWorkoutActivityType.OTHER":
        return {'icon': Icons.fitness_center, 'nombre': "Otro"};
      default:
        final label = activityType.replaceFirst('HealthWorkoutActivityType.', '').replaceAll('_', ' ').toLowerCase().split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
        return {'icon': Icons.fitness_center, 'nombre': label};
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
