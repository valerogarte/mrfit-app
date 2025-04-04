// rutina.dart
import '../../data/database_helper.dart';
import 'sesion.dart';

class Rutina {
  final int id;
  final String titulo;
  final String? imagen;

  Rutina({
    required this.id,
    required this.titulo,
    this.imagen,
  });

  factory Rutina.fromJson(Map<String, dynamic> json) {
    return Rutina(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      imagen: json['imagen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'imagen': imagen,
    };
  }

  // Nueva función para renombrar la rutina en la base de datos local
  Future<int> rename(String nuevoTitulo) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.update(
      'rutinas_rutina',
      {'titulo': nuevoTitulo},
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  // Método para eliminar una rutina de la base de datos local
  Future<bool> delete() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.delete(
      'rutinas_rutina',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result > 0;
  }

  // Método para insertar una sesión en la rutina usando la base de datos local
  Future<Sesion> insertarSesion(String titulo) async {
    final db = await DatabaseHelper.instance.database;
    // Consultar el valor máximo de "orden" para la rutina actual
    final result = await db.rawQuery(
      "SELECT MAX(orden) as maxOrden FROM rutinas_sesion WHERE rutina_id = ?",
      [id],
    );
    // Si no hay registros, se usa 0; de lo contrario se suma 1 al valor máximo
    final int currentMaxOrder = (result.first["maxOrden"] as int?) ?? 0;
    final int newOrder = currentMaxOrder + 1;

    final int newId = await db.insert('rutinas_sesion', {
      'titulo': titulo,
      'rutina_id': id,
      'orden': newOrder,
    });
    return Sesion(id: newId, titulo: titulo, orden: newOrder);
  }

  // Método para obtener las sesiones vinculadas a esta rutina usando la base de datos local
  Future<List<Sesion>> getSesiones() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT * FROM rutinas_sesion WHERE rutina_id = ? ORDER BY orden ASC",
      [id],
    );
    return result.map((json) => Sesion.fromJson(json)).toList();
  }
}
