import 'package:mrfit/data/database_helper.dart';
import 'sesion.dart';

class Rutina {
  final int id;
  final String titulo;
  final String? imagen;
  final int? grupoId;
  final int? peso; // New field

  Rutina({
    required this.id,
    required this.titulo,
    this.imagen,
    this.grupoId,
    this.peso,
  });

  factory Rutina.fromJson(Map<String, dynamic> json) {
    return Rutina(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      imagen: json['imagen'],
      grupoId: json['grupo_id'],
      peso: json['peso'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
      'grupo_id': grupoId,
      'peso': peso,
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
}
