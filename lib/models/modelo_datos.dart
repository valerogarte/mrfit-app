import 'package:logger/logger.dart';
import '../data/database_helper.dart';
import 'ejercicio/ejercicio.dart';
import 'package:flutter/material.dart';

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
        'iconColor': const Color.fromARGB(255, 145, 231, 148),
      },
      {
        'value': 2,
        'label': 'Ligero',
        'description': 'Pude haber hecho entre 4-6 repeticiones más',
        'iconColor': Colors.lightGreen,
      },
      {
        'value': 3,
        'label': 'Moderado',
        'description': 'Podría haber hecho 3 repeticiones más',
        'iconColor': Colors.yellow,
      },
      {
        'value': 4,
        'label': 'Intenso',
        'description': 'Podría haber hecho 2 repeticiones más',
        'iconColor': Colors.orange,
      },
      {
        'value': 5,
        'label': 'Al límite',
        'description': 'Podría haber hecho 1 repetición más',
        'iconColor': Colors.red,
      },
      {
        'value': 6,
        'label': 'Al fallo',
        'description': 'No pude hacer más repeticiones',
        'iconColor': Colors.purple.shade500,
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
    print(activityType);
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
      default:
        return {
          'icon': Icons.fitness_center,
          'nombre': activityType,
        };
    }
  }
}
