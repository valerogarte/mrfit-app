part of 'ejercicio.dart';

extension EjercicioQuery on Ejercicio {
  Map<String, double> obtenerImplicacionMuscular() {
    final implicaciones = <String, double>{};
    for (final m in musculosInvolucrados) {
      final nombreMusculo = m.musculo.titulo.toLowerCase().trim();
      final porcentaje = m.porcentajeImplicacion.toDouble() / 100.0;
      implicaciones[nombreMusculo] = porcentaje;
    }
    return implicaciones;
  }

  Future<Map<String, dynamic>> getRecord() async {
    final db = await DatabaseHelper.instance.database;
    // Consulta uniendo series y ejercicios realizados para este ejercicio
    final result = await db.rawQuery('''
      SELECT ser.peso, ser.repeticiones
      FROM entrenamiento_serierealizada ser
      JOIN entrenamiento_ejerciciorealizado er ON ser.ejercicio_realizado_id = er.id
      WHERE er.ejercicio_id = ?
        AND ser.realizada = 1
        AND ser.deleted = 0
    ''', [id]);

    double bestRM = 0.0;
    Map<String, dynamic> bestReps = {'peso': 0.0, 'repeticiones': 0};
    double bestVolumen = 0.0;
    double pesoMaximo = 0.0; // Nueva variable para el peso máximo
    int seriesRealizadas = 0; // Nueva variable para el número total de series realizadas

    for (final row in result) {
      final peso = (row['peso'] as num).toDouble();
      final reps = (row['repeticiones'] as num).toInt();
      // Calcular 1 RM estimado usando fórmula de Epley
      final rm = peso * (1 + reps / 30.0);

      if (rm > bestRM) bestRM = rm;
      if (reps > bestReps['repeticiones']) {
        bestReps = {'peso': peso, 'repeticiones': reps};
      }
      final volumen = peso * reps;
      if (volumen > bestVolumen) bestVolumen = volumen;
      if (peso > pesoMaximo) pesoMaximo = peso;
      seriesRealizadas++; // Incrementar el contador de series realizadas
    }

    return {
      'rm': bestRM,
      'maxReps': bestReps,
      'volumenMaximo': bestVolumen,
      'pesoMaximo': pesoMaximo,
      'seriesRealizadas': seriesRealizadas, // Añadir el número total de series realizadas al resultado
    };
  }

  Future<Map<String, Map<String, dynamic>>> getProgressionRecords() async {
    final db = await DatabaseHelper.instance.database;
    // Primero, obtener los ids de entrenamiento_ejerciciorealizado para el ejercicio actual
    final erRecords = await db.rawQuery('''
      SELECT id
      FROM entrenamiento_ejerciciorealizado
      WHERE ejercicio_id = ?
    ''', [id]);

    if (erRecords.isEmpty) {
      return {};
    }

    // print('-Ejercicios realizados: ${erRecords.length}');

    final erIds = erRecords.map((row) => row['id'] as int).toList();
    final placeholders = List.filled(erIds.length, '?').join(', ');

    // Obtener todas las series realizadas para esos ejercicios realizados
    final seriesResult = await db.rawQuery('''
      SELECT ejercicio_realizado_id, inicio, peso, repeticiones as reps
      FROM entrenamiento_serierealizada
      WHERE ejercicio_realizado_id IN ($placeholders)
        AND realizada = 1
        AND deleted = 0
    ''', erIds);

    // print('--Series realizadas: ${seriesResult.length}');

    // Agrupar por ejercicio_realizado_id
    final Map<int, List<Map<String, dynamic>>> groups = {};
    for (final row in seriesResult) {
      final erId = row['ejercicio_realizado_id'] as int;
      groups.putIfAbsent(erId, () => []).add(row);
    }

    // print('--- Grupos: ${groups.length}');

    // Calcular para cada entrenamiento los valores deseados
    final Map<String, Map<String, dynamic>> progression = {};
    groups.forEach((erId, rows) {
      double bestRM = 0.0;
      int maxReps = 0;
      double maxPeso = 0.0;
      double maxVolumen = 0.0;
      String fechaInicioEx = '';

      // print('---- Con ${rows.length} series');
      for (final row in rows) {
        final peso = (row['peso'] as num).toDouble();
        final reps = (row['reps'] as num).toInt();
        final rm = peso * (1 + reps / 30.0);
        if (rm > bestRM) bestRM = rm;
        if (reps > maxReps) maxReps = reps;
        if (peso > maxPeso) maxPeso = peso;
        final volumen = peso * reps;
        if (volumen > maxVolumen) maxVolumen = volumen;
        final currentInicio = row['inicio'] as String? ?? '';
        // print('-----' + row.toString());
        if (currentInicio.compareTo(fechaInicioEx) > 0) {
          fechaInicioEx = currentInicio;
        }
      }

      // print('${fechaInicioEx.toString()}, $bestRM, $maxReps, $maxPeso, $maxVolumen');

      progression[fechaInicioEx] = {
        'rm': bestRM,
        'maxReps': maxReps,
        'pesoMaximo': maxPeso,
        'volumenMaximo': maxVolumen,
      };
    });

    // print('Progresión: ${progression.length}');

    return progression;
  }

  Future<Map<int, Map<String, dynamic>>> getSeriesByEjercicio() async {
    final db = await DatabaseHelper.instance.database;
    final seriesResult = await db.rawQuery('''
      SELECT et.id AS entrenamiento_id, et.inicio AS entrenamiento_inicio, ser.*
      FROM entrenamiento_serierealizada ser
      JOIN entrenamiento_ejerciciorealizado ee ON ser.ejercicio_realizado_id = ee.id
      JOIN entrenamiento_entrenamiento et ON ee.entrenamiento_id = et.id
      WHERE ee.ejercicio_id = ?
        AND ser.realizada = 1
        AND ser.deleted = 0
      ORDER BY et.inicio ASC
    ''', [id]);

    final Map<int, Map<String, dynamic>> grouped = {};
    for (final row in seriesResult) {
      final trainingId = row['entrenamiento_id'] as int;
      final inicioEntrenamiento = row['entrenamiento_inicio'];
      final serieR = SerieRealizada.fromJson(row);
      if (grouped[trainingId] == null) {
        grouped[trainingId] = {
          'inicio': inicioEntrenamiento,
          'series': [serieR],
        };
      } else {
        grouped[trainingId]!['series'].add(serieR);
      }
    }
    return grouped;
  }
}
