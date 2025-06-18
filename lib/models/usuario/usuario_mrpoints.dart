part of 'usuario.dart';

extension UsuarioMrPointsExtension on Usuario {
  Future<Map<String, double>> getCurrentMrPoints() async {
    if (_cachedMrPoints != null) {
      return _cachedMrPoints!;
    }
    Map<String, double> mrPoints = await _computeMrPoints();
    _cachedMrPoints = mrPoints;
    return mrPoints;
  }

  Future<Map<String, double>> _computeMrPoints() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.rawQuery('''
      SELECT t1.volumen, e.titulo
      FROM accounts_volumenmaximo t1
      JOIN (
          SELECT musculo_id, MAX(fecha) AS ultima_fecha
          FROM accounts_volumenmaximo
          GROUP BY musculo_id
      ) t2
      ON t1.musculo_id = t2.musculo_id AND t1.fecha = t2.ultima_fecha
      JOIN ejercicios_musculo e
      ON t1.musculo_id = e.id
    ''');

    final Map<String, double> volumenesMaximos = {};
    for (final row in results) {
      final String nombreMusculo = row['titulo'] as String;
      final double volumen = (row['volumen'] as num).toDouble();
      volumenesMaximos[nombreMusculo] = volumen;
    }

    // Comprueba que todos los músculos tengan un volumen máximo
    final volumenMusculosDefault = getMuscleMaxVolumeDefault();
    for (final musculo in volumenMusculosDefault.keys) {
      if (!volumenesMaximos.containsKey(musculo)) {
        volumenesMaximos[musculo] = volumenMusculosDefault[musculo]!;
      }
    }

    volumenMaximo = volumenesMaximos;

    return volumenesMaximos;
  }

  Future<double> setMrPointsInMuscle(String musculoName, double volumen) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query('ejercicios_musculo', columns: ['id'], where: 'LOWER(titulo) = LOWER(?)', whereArgs: [musculoName]);
    final musculoId = result.isNotEmpty ? result.first['id'].toString() : '';
    if (musculoId.isEmpty) {
      Logger().w('No se ha encontrado el músculo "$musculoName"');
      return 0;
    }

    // Formatea la fecha como 'yyyy-MM-dd' para cumplir con el formato requerido
    final now = DateTime.now();
    final fecha = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final id = await db.insert('accounts_volumenmaximo', {
      'fecha': fecha,
      'volumen': volumen,
      'musculo_id': musculoId,
      'usuario_id': 1,
    });
    return id.toDouble();
  }

  Map<String, double> getMuscleMaxVolumeDefault() {
    return {
      'abductores': 400,
      'abdominales': 2000,
      'aductores': 30,
      'antebrazos': 250,
      'bíceps': 800,
      'cuádriceps': 750,
      'cuello': 800,
      'dorsales': 450,
      'lumbares': 1000,
      'espalda': 2000,
      'glúteos': 600,
      'hombros': 1200,
      'isquiotibiales': 600,
      'pantorrillas': 750,
      'pecho': 900,
      'trapecios': 800,
      'tríceps': 1000,
    };
  }

  Future<Map<String, double>> updateMrPointsFromEntrenamiento(Entrenamiento entrenamiento) async {
    final currentMrPoints = await getCurrentMrPoints();

    final entrenamientos = await getEjerciciosLastDias(5) ?? [];
    for (final e in entrenamientos) {
      await e.calcularRecuperacion(this);
    }
    final gastoPorMusculo = await getGastoPorMusculo(entrenamientos, this);
    final aumentoPermitido = 0.15;
    for (final musculo in gastoPorMusculo.keys) {
      final volumenEntrenamiento = (gastoPorMusculo[musculo] as num).toDouble();
      final volumenMaximo = currentMrPoints[musculo] ?? 0.0;
      // Ahora comparo los volúmenes de entrenamiento con los volúmenes máximos
      // Si el volumen de entrenamiento es mayor que el máximo, se actualiza el máximo
      if (volumenEntrenamiento > volumenMaximo) {
        final diferencia = volumenEntrenamiento - volumenMaximo;
        // Pero para que sea progresivo, solo hace un aumento del aumentoPermitido
        final aumento = diferencia * aumentoPermitido;
        final nuevoVolumenMaximo = volumenMaximo + aumento;
        await setMrPointsInMuscle(musculo, nuevoVolumenMaximo);
        currentMrPoints[musculo] = nuevoVolumenMaximo;
        Logger().i("Volumen máximo de $musculo actualizado $volumenMaximo > $nuevoVolumenMaximo");
      }
    }

    return currentMrPoints;
  }
}
