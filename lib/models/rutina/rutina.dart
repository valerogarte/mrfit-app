import 'package:mrfit/data/database_helper.dart';
import 'package:sqflite/sqflite.dart'; // <-- agregada
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'imagen': imagen,
      'fecha_creacion': fechaCreacion?.toIso8601String(),
      'usuario_id': usuarioId,
      'grupo_id': grupoId,
      'peso': peso,
      'dificultad': dificultad,
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

  // NUEVO: Archivar la rutina (grupo_id = 2)
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

  // Insertar una sesión en la rutina usando la base de datos local
  Future<Sesion> insertarSesion(String titulo) async {
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
    });
    return Sesion(id: newId, titulo: titulo, orden: newOrder);
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
}
