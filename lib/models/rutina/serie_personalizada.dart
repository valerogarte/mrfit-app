import 'package:mrfit/data/database_helper.dart';

class SeriePersonalizada {
  final int id;
  int ejercicioRealizado;
  int repeticiones;
  double peso;
  double velocidadRepeticion;
  int descanso;
  int rer;

  SeriePersonalizada({required this.id, required this.ejercicioRealizado, required this.repeticiones, required this.peso, required this.velocidadRepeticion, required this.descanso, required this.rer});

  factory SeriePersonalizada.fromJson(Map<String, dynamic> json) {
    return SeriePersonalizada(
      id: json['id'],
      ejercicioRealizado: json['ejercicio_realizado_id'] ?? 0,
      repeticiones: json['repeticiones'] ?? 0,
      peso: (json['peso'] ?? 0).toDouble(),
      velocidadRepeticion: (json['velocidad_repeticion'] ?? 0).toDouble(),
      descanso: json['descanso'] ?? 0,
      rer: json['rer'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ejercicio_realizado_id': ejercicioRealizado,
      'repeticiones': repeticiones,
      'peso': peso,
      'velocidad_repeticion': velocidadRepeticion,
      'descanso': descanso,
      'rer': rer,
    };
  }

  Future<void> save() async {
    final db = await DatabaseHelper.instance.database;
    final data = {
      'repeticiones': repeticiones,
      'peso': peso,
      'velocidad_repeticion': velocidadRepeticion,
      'descanso': descanso,
      'rer': rer,
    };
    await db.update(
      'rutinas_seriepersonalizada',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'rutinas_seriepersonalizada',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
