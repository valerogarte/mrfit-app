import 'package:mrfit/data/database_helper.dart';

class Grupo {
  final int id;
  final String titulo;
  final int? peso; // New field

  Grupo({
    required this.id,
    required this.titulo,
    this.peso,
  });

  factory Grupo.fromJson(Map<String, dynamic> json) {
    return Grupo(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      peso: json['peso'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'peso': peso,
    };
  }

  // Cargar Grupo by ID desde la base de datos local
  static Future<Grupo?> loadById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'rutinas_grupo',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Grupo.fromJson(result.first);
    }
    return null;
  }

  // Establecer el peso del grupo para ordenamiento
  Future<int> setPeso(int nuevoPeso) async {
    final db = await DatabaseHelper.instance.database;
    return await db.update(
      'rutinas_grupo',
      {'peso': nuevoPeso},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
