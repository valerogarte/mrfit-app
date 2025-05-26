import 'package:mrfit/data/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'sesion.dart';

class Rutina {
  int id;
  String titulo;
  String descripcion;
  String imagen;
  DateTime fechaCreacion;
  int usuarioId;
  int grupoId;
  int peso;
  int dificultad;
  int? rutinaPadreId;

  Rutina({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.fechaCreacion,
    required this.usuarioId,
    required this.grupoId,
    required this.peso,
    required this.dificultad,
    this.rutinaPadreId,
  });

  factory Rutina.fromJson(Map<String, dynamic> json) {
    return Rutina(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'],
      imagen: json['imagen'],
      fechaCreacion: json['fecha_creacion'] != null ? DateTime.tryParse(json['fecha_creacion'].toString()) ?? DateTime(1970, 1, 1) : DateTime(1970, 1, 1),
      usuarioId: json['usuario_id'],
      grupoId: json['grupo_id'],
      peso: json['peso'],
      dificultad: json['dificultad'],
      rutinaPadreId: json['rutina_padre_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'imagen': imagen,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'usuario_id': usuarioId,
      'grupo_id': grupoId,
      'peso': peso,
      'dificultad': dificultad,
      'rutina_padre_id': rutinaPadreId,
    };
  }

  // Método para cargar Rutina by ID desde la base de datos local
  static Future<Rutina?> loadById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'rutinas_rutina',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Rutina.fromJson(result.first);
    }
    return null;
  }

  // Renombrar la rutina en la base de datos local
  Future<int> rename(String nuevoTitulo) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'rutinas_rutina',
      {'titulo': nuevoTitulo},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Actualizar descripción de la rutina
  Future<int> setDescripcion(String descripcion) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'rutinas_rutina',
      {'descripcion': descripcion},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Actualizar dificultad de la rutina
  Future<int> setDificultad(int dificultad) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'rutinas_rutina',
      {'dificultad': dificultad},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Establecer el peso de la rutina para ordenamiento
  Future<int> setPeso(int nuevoPeso) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'rutinas_rutina',
      {'peso': nuevoPeso},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Eliminar una rutina de la base de datos local
  Future<bool> delete() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.delete(
      'rutinas_rutina',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  Future<void> archivar() async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'rutinas_rutina',
      {'grupo_id': 2},
      where: 'id = ?',
      whereArgs: [id],
    );
    grupoId = 2;
  }

  Future<void> restaurar() async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'rutinas_rutina',
      {'grupo_id': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    grupoId = 1;
  }

  /// Inserta una sesión en la rutina usando la base de datos local.
  /// [titulo]: Título de la sesión.
  /// [dificultad]: Dificultad de la sesión (1-5).
  ///
  /// Ejemplo de uso:
  ///   await rutina.insertarSesion('Día 1', 3);
  Future<Sesion> insertarSesion(String titulo, int dificultad) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT MAX(orden) as maxOrden FROM rutinas_sesion WHERE rutina_id = ?",
      [id],
    );
    final int currentMaxOrder = (result.first["maxOrden"] as int?) ?? 0;
    final int newOrder = currentMaxOrder + 1;

    final int newId = await db.insert('rutinas_sesion', {
      'titulo': titulo,
      'rutina_id': id,
      'orden': newOrder,
      'dificultad': dificultad,
    });
    return Sesion(id: newId, titulo: titulo, orden: newOrder, dificultad: dificultad);
  }

  // Obtener las sesiones vinculadas a esta rutina usando la base de datos local
  Future<List<Sesion>> getSesiones() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT * FROM rutinas_sesion WHERE rutina_id = ? ORDER BY orden ASC",
      [id],
    );
    return result.map((json) => Sesion.fromJson(json)).toList();
  }

  /// Total de entrenamientos realizados para esta rutina y desglose por sesión
  /// Devuelve: {'total': int, 'porSesion': [{'nombre': ..., 'cantidad': ...}, ...]}
  Future<Map<String, dynamic>> getTotalEntrenamientos() async {
    final db = await DatabaseHelper.instance.database;
    // Consulta única: desglose por sesión
    final porSesionRes = await db.rawQuery('''
      SELECT s.titulo AS nombre, COUNT(e.id) AS cantidad
        FROM entrenamiento_entrenamiento e
        JOIN rutinas_sesion s ON e.sesion_id = s.id
       WHERE s.rutina_id = ?
       GROUP BY s.id
       ORDER BY s.orden ASC
    ''', [id]);
    final porSesion = porSesionRes
        .map((row) => {
              'nombre': row['nombre'],
              'cantidad': row['cantidad'],
            })
        .toList();

    // Sumar cantidades para el total
    final total = porSesion.fold<int>(0, (sum, row) => sum + (row['cantidad'] as int? ?? 0));

    return {
      'total': total,
      'porSesion': porSesion,
    };
  }

  /// Suma de duración en segundos de todos los entrenamientos
  Future<int> getTiempoTotalSegundos() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT SUM(strftime('%s', e.fin) - strftime('%s', e.inicio)) AS secs
        FROM entrenamiento_entrenamiento e
        JOIN rutinas_sesion s ON e.sesion_id = s.id
       WHERE s.rutina_id = ?
    ''', [id]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// Duración media en segundos de todos los entrenamientos
  Future<double> getDuracionMediaSegundos() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT AVG(strftime('%s', e.fin) - strftime('%s', e.inicio)) AS avg_secs
        FROM entrenamiento_entrenamiento e
        JOIN rutinas_sesion s ON e.sesion_id = s.id
       WHERE s.rutina_id = ?
    ''', [id]);
    return (res.first['avg_secs'] as num?)?.toDouble() ?? 0.0;
  }

  /// Total de sets completados
  Future<int> getTotalSetsCompletados() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT COUNT(r.id) AS sets
        FROM entrenamiento_serierealizada r
        JOIN entrenamiento_ejerciciorealizado er ON r.ejercicio_realizado_id = er.id
        JOIN entrenamiento_entrenamiento e ON er.entrenamiento_id = e.id
        JOIN rutinas_sesion s ON e.sesion_id = s.id
       WHERE s.rutina_id = ? AND r.realizada = 1
    ''', [id]);
    return Sqflite.firstIntValue(res) ?? 0;
  }

  /// Datos para gráfico: conteo de entrenamientos por día
  Future<List<Map<String, Object?>>> getEntrenosPorDia() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT date(e.inicio) AS dia,
             COUNT(e.id)        AS cantidad
        FROM entrenamiento_entrenamiento e
        JOIN rutinas_sesion s ON e.sesion_id = s.id
       WHERE s.rutina_id = ?
       GROUP BY dia
       ORDER BY dia
    ''', [id]);
  }

  /// Datos para gráfico: total de volumen por entrenamiento
  Future<List<Map<String, Object?>>> getVolumenPorEntrenamiento() async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery('''
      SELECT e.inicio    AS inicio,
             SUM(r.peso * r.repeticiones) AS volumen_total
        FROM entrenamiento_serierealizada r
        JOIN entrenamiento_ejerciciorealizado er ON r.ejercicio_realizado_id = er.id
        JOIN entrenamiento_entrenamiento e ON er.entrenamiento_id = e.id
        JOIN rutinas_sesion s ON e.sesion_id = s.id
       WHERE s.rutina_id = ?
       GROUP BY e.id
       ORDER BY e.inicio ASC
    ''', [id]);
  }

  /// Duplica la rutina completa, incluyendo sesiones, ejercicios personalizados y series personalizadas.
  Future<Rutina> duplicar() async {
    final db = await DatabaseHelper.instance.database;

    // 1. Crear la nueva rutina (copia de los campos, rutinaPadreId apunta a la original)
    final nuevaRutinaId = await db.insert('rutinas_rutina', {
      'titulo': titulo,
      'descripcion': descripcion,
      'imagen': imagen,
      'fecha_creacion': DateTime.now().toIso8601String(),
      'usuario_id': usuarioId,
      'grupo_id': 1,
      'peso': peso,
      'dificultad': dificultad,
      'rutina_padre_id': id,
    });

    // 2. Copiar sesiones
    final sesiones = await db.query(
      'rutinas_sesion',
      where: 'rutina_id = ?',
      whereArgs: [id],
    );

    // Mapeo de id de sesión original a nueva sesión
    final Map<int, int> sesionIdMap = {};

    for (final sesion in sesiones) {
      final nuevaSesionId = await db.insert('rutinas_sesion', {
        'titulo': sesion['titulo'],
        'orden': sesion['orden'],
        'rutina_id': nuevaRutinaId,
        'dificultad': sesion['dificultad'],
      });
      sesionIdMap[sesion['id'] as int] = nuevaSesionId;
    }

    // 3. Copiar ejercicios personalizados y series personalizadas para cada sesión
    for (final sesion in sesiones) {
      final oldSesionId = sesion['id'] as int;
      final newSesionId = sesionIdMap[oldSesionId]!;

      // Copiar ejercicios personalizados
      final ejercicios = await db.query(
        'rutinas_ejerciciopersonalizado',
        where: 'sesion_id = ?',
        whereArgs: [oldSesionId],
      );

      // Mapeo de id de ejercicio personalizado original a nuevo
      final Map<int, int> ejercicioIdMap = {};

      for (final ejercicio in ejercicios) {
        final nuevoEjercicioId = await db.insert('rutinas_ejerciciopersonalizado', {
          'peso_orden': ejercicio['peso_orden'],
          'ejercicio_id': ejercicio['ejercicio_id'],
          'sesion_id': newSesionId,
        });
        ejercicioIdMap[ejercicio['id'] as int] = nuevoEjercicioId;
      }

      // Copiar series personalizadas asociadas a cada ejercicio personalizado
      for (final ejercicio in ejercicios) {
        final oldEjercicioId = ejercicio['id'] as int;
        final newEjercicioId = ejercicioIdMap[oldEjercicioId]!;

        final series = await db.query(
          'rutinas_seriepersonalizada',
          where: 'ejercicio_personalizado_id = ?',
          whereArgs: [oldEjercicioId],
        );

        for (final serie in series) {
          await db.insert('rutinas_seriepersonalizada', {
            'repeticiones': serie['repeticiones'],
            'peso': serie['peso'],
            'velocidad_repeticion': serie['velocidad_repeticion'],
            'descanso': serie['descanso'],
            'rer': serie['rer'],
            'ejercicio_personalizado_id': newEjercicioId,
          });
        }
      }
    }

    // 4. Devolver la nueva rutina como objeto
    final nuevaRutina = await Rutina.loadById(nuevaRutinaId);
    if (nuevaRutina == null) {
      throw Exception('Error al duplicar la rutina');
    }
    return nuevaRutina;
  }
}
