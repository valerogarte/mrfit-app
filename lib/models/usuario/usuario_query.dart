part of 'usuario.dart';

extension UsuarioQueryExtension on Usuario {
  Future<List<Map<String, dynamic>>?> getResumenEntrenamientos() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // Consulta modificada usando JOIN para recuperar el título de la rutina
      final results = await db.rawQuery('''
        SELECT e.*, r.titulo AS rutina_titulo
        FROM entrenamiento_entrenamiento e
        LEFT JOIN rutinas_sesion r ON r.id = e.sesion_id
        WHERE e.usuario_id = 1
        ORDER BY e.fin DESC
        LIMIT 50
      ''');

      final summary = <Map<String, dynamic>>[];

      for (var ent in results) {
        DateTime? inicio = DateTime.tryParse(ent['inicio']?.toString() ?? '');
        DateTime? fin = ent['fin'] != null ? DateTime.tryParse(ent['fin'] as String) : null;
        Duration? duracion = (inicio != null && fin != null) ? fin.difference(inicio) : null;

        summary.add({
          'id': ent['id'],
          'titulo': ent['rutina_titulo'] ?? 'Sin título',
          'inicio': ent['inicio'],
          'duracion': duracion?.toString().split('.')[0] ?? 'En curso',
        });
      }

      return summary;
    } catch (e) {
      Logger().e('Error en fetchResumenEntrenamientos: $e');
      return null;
    }
  }

  Future<List<Rutina>?> getRutinas() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery('''
        SELECT * FROM rutinas_rutina WHERE usuario_id = 1 ORDER BY peso DESC;
      ''');
      final rutinas = result.map((row) => Rutina.fromJson(row)).toList();
      return rutinas;
    } catch (e) {
      Logger().e('Error en getRutinas: $e');
      return [];
    }
  }

  Future<Rutina> crearRutina({required String titulo}) async {
    final db = await DatabaseHelper.instance.database;
    final numberRutinas = await db.rawQuery('''
      SELECT COUNT(*) as count FROM rutinas_rutina WHERE grupo_id = 1;
    ''');
    final imagen = "";
    final int id = await db.insert('rutinas_rutina', {
      'titulo': titulo,
      'descripcion': "",
      'imagen': imagen,
      'fecha_creacion': DateTime.now().toIso8601String(),
      'usuario_id': 1,
      'grupo_id': 1,
      "peso": numberRutinas.first["count"],
      "dificultad": 0,
    });
    return Rutina(
      id: id,
      titulo: titulo,
      descripcion: "",
      imagen: imagen,
      fechaCreacion: DateTime.now(),
      usuarioId: 1,
      grupoId: 1,
      peso: int.parse(numberRutinas.first["count"].toString()),
      dificultad: 1,
    );
  }

  Future<List<Entrenamiento>?> getEjerciciosLastDias(int daysAgo) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final threshold = DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String();
      final results = await db.rawQuery('''
        SELECT id FROM entrenamiento_entrenamiento 
        WHERE usuario_id = 1 AND inicio >= ?
        ORDER BY id DESC
      ''', [threshold]);

      final List<Entrenamiento> entrenamientos = [];
      for (final row in results) {
        final int entrenamientoId = row['id'] as int;
        final entrenamiento = await Entrenamiento.loadById(entrenamientoId);
        if (entrenamiento != null) {
          entrenamientos.add(entrenamiento);
        }
      }
      return entrenamientos;
    } catch (e) {
      Logger().e('Error en getEjerciciosLast5Dias: $e');
      return null;
    }
  }

  /// Obtiene los entrenamientos realizados en un día específico.
  /// [day] debe ser la fecha del día a consultar (solo la parte de fecha es relevante).
  Future<List<Entrenamiento>> getEjerciciosByDay(DateTime day) async {
    try {
      final db = await DatabaseHelper.instance.database;
      // Se obtiene el rango de tiempo para el día especificado.
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final results = await db.rawQuery('''
        SELECT id FROM entrenamiento_entrenamiento 
        WHERE usuario_id = 1 AND inicio >= ? AND inicio < ?
        ORDER BY id DESC
      ''', [startOfDay.toIso8601String(), endOfDay.toIso8601String()]);

      final List<Entrenamiento> entrenamientos = [];
      for (final row in results) {
        final int entrenamientoId = row['id'] as int;
        final entrenamiento = await Entrenamiento.loadById(entrenamientoId);
        if (entrenamiento != null) {
          entrenamientos.add(entrenamiento);
        }
      }
      return entrenamientos;
    } catch (e) {
      Logger().e('Error en getEjerciciosByDay: $e');
      return [];
    }
  }

  // Método para calcular el gasto por músculo a partir de los entrenamientos recientes.
  Future<Map<String, double>> getGastoActualPorMusculoPorcentaje(List<Entrenamiento> entrenamientos, Usuario usuario) async {
    final Map<String, double> gastoPorMusculo = {};

    if (entrenamientos.isNotEmpty) {
      for (final entrenamiento in entrenamientos) {
        await entrenamiento.calcularRecuperacion(usuario);
        final volumenEntrenamiento = entrenamiento.getVolumenActualPorMusculoPorcentaje();
        for (final item in volumenEntrenamiento) {
          final nombreMusculoOriginal = item.keys.first;
          final nombreMusculo = nombreMusculoOriginal.toLowerCase();
          final gastoActual = item.values.first;
          gastoPorMusculo[nombreMusculo] = (gastoPorMusculo[nombreMusculo] ?? 0) + gastoActual;
        }
      }
    } else {
      Logger().w('No se han encontrado entrenamientos recientes');
    }

    final gastoPorMusculoOrdenado = gastoPorMusculo.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(gastoPorMusculoOrdenado);
  }

  // Método para calcular el gasto por músculo a partir de los entrenamientos recientes.
  Future<Map<String, double>> getGastoPorMusculo(List<Entrenamiento> entrenamientos, Usuario usuario) async {
    final Map<String, double> gastoPorMusculo = {};

    if (entrenamientos.isNotEmpty) {
      for (final entrenamiento in entrenamientos) {
        await entrenamiento.calcularRecuperacion(usuario);
        final volumenEntrenamiento = entrenamiento.getVolumenActualPorMusculo();
        for (final item in volumenEntrenamiento) {
          final nombreMusculoOriginal = item.keys.first;
          final nombreMusculo = nombreMusculoOriginal.toLowerCase();
          final gastoActual = item.values.first;
          gastoPorMusculo[nombreMusculo] = (gastoPorMusculo[nombreMusculo] ?? 0) + gastoActual;
        }
      }
    } else {
      Logger().w('No se han encontrado entrenamientos recientes');
    }
    return gastoPorMusculo;
  }

  // Metodo para obtener el porcentaje de uso de los músculos en los entrenamientos
  Future<Map<String, double>> getMusculosUsadosEnLastEntrenamientos() async {
    final entrenamientos = await getEjerciciosLastDias(60) ?? [];
    for (final e in entrenamientos) {
      await e.calcularRecuperacion(this);
    }

    final Map<String, double> gastoPorMusculoTotal = {};
    if (entrenamientos.isNotEmpty) {
      for (final entrenamiento in entrenamientos) {
        final volumenEntrenamiento = entrenamiento.getVolumenPorMusculoPorcentaje();
        for (final item in volumenEntrenamiento) {
          final nombreMusculoOriginal = item.keys.first;
          final nombreMusculo = nombreMusculoOriginal.toLowerCase();
          final gastoActual = item.values.first;
          gastoPorMusculoTotal[nombreMusculo] = (gastoPorMusculoTotal[nombreMusculo] ?? 0) + gastoActual;
        }
      }
    } else {
      Logger().w('No se han encontrado entrenamientos recientes');
    }

    // Ahora dividimos el gasto por músculo entre el total de entrenamientos para obtener el porcentaje
    final gastoPorMusculo = gastoPorMusculoTotal.map((key, value) => MapEntry(key, value / entrenamientos.length));
    return gastoPorMusculo;
  }

  Future<Map<int, Map<String, dynamic>>> getEjerciciosMasUsados() async {
    final entrenamientos = await getEjerciciosLastDias(60) ?? [];
    final Map<int, Map<String, dynamic>> ejerciciosMasUsados = {};

    if (entrenamientos.isNotEmpty) {
      for (final entrenamiento in entrenamientos) {
        for (final ejercicioRealizado in entrenamiento.ejercicios) {
          if (ejercicioRealizado.countSeriesRealizadas() > 0) {
            final idEjercicio = ejercicioRealizado.ejercicio.id;
            if (ejerciciosMasUsados.containsKey(idEjercicio)) {
              ejerciciosMasUsados[idEjercicio]!['count'] = ejerciciosMasUsados[idEjercicio]!['count'] + 1;
            } else {
              ejerciciosMasUsados[idEjercicio] = {
                "count": 1,
                "ejercicio": ejercicioRealizado.ejercicio,
              };
            }
          }
        }
      }
    } else {
      Logger().w('No se han encontrado entrenamientos recientes');
    }

    return ejerciciosMasUsados;
  }
}
