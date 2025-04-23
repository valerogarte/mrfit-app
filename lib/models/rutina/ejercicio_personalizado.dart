import 'package:logger/logger.dart';
import 'package:mrfit/data/database_helper.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/models/rutina/serie_personalizada.dart';

class EjercicioPersonalizado {
  final int id;
  final Ejercicio ejercicio;
  final int sesion;
  double orden;
  List<SeriePersonalizada>? seriesPersonalizadas;

  EjercicioPersonalizado({required this.id, required this.ejercicio, required this.sesion, required this.orden});

  // Cambia el factory a async para esperar loadById
  static Future<EjercicioPersonalizado> fromJson(Map<String, dynamic> json) async {
    return EjercicioPersonalizado(
      id: json['id'],
      ejercicio: await Ejercicio.loadById(json['ejercicio_id']),
      sesion: (json['sesion_id'] ?? 0).toInt(),
      orden: (json['peso_orden'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    try {
      final data = {'id': id, 'ejercicio': ejercicio.toJson(), 'sesion': sesion, 'orden': orden};
      if (seriesPersonalizadas != null) {
        data['seriesPersonalizadas'] = seriesPersonalizadas!.map((serie) => serie.toJson()).toList();
      }
      return data;
    } catch (e) {
      Logger().i('Error converting to JSON: $e');
      return {};
    }
  }

  // Método que retorna las seriesPersonalizadas asociadas a este ejercicio personalizado.
  Future<List<SeriePersonalizada>> getSeriesPersonalizadas() async {
    // Si ya se inicializó, retorna directamente
    if (seriesPersonalizadas != null) return seriesPersonalizadas!;
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'rutinas_seriepersonalizada',
      where: 'ejercicio_personalizado_id = ?',
      whereArgs: [id],
    );
    seriesPersonalizadas = result.map((json) => SeriePersonalizada.fromJson(json)).toList();
    return seriesPersonalizadas!;
  }

  // Método para eliminar el ejercicio personalizado de la base de datos
  Future<void> delete() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'rutinas_ejerciciopersonalizado',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<SeriePersonalizada> insertSeriePersonalizada() async {
    // Aseguramos que seriesPersonalizadas esté cargada
    if (seriesPersonalizadas == null) {
      await getSeriesPersonalizadas();
    }
    SeriePersonalizada? baseSerie;
    if (seriesPersonalizadas != null && seriesPersonalizadas!.isNotEmpty) {
      baseSerie = seriesPersonalizadas!.reduce((a, b) => a.id > b.id ? a : b);
    }
    final db = await DatabaseHelper.instance.database;
    final data = {
      'repeticiones': baseSerie?.repeticiones ?? 10,
      'descanso': baseSerie?.descanso ?? 60,
      'rer': baseSerie?.rer ?? 2,
      'velocidad_repeticion': baseSerie?.velocidadRepeticion ?? 2,
      'peso': baseSerie?.peso ?? 0,
      'ejercicio_personalizado_id': id,
    };
    final insertedId = await db.insert('rutinas_seriepersonalizada', data);
    final nuevaSerie = SeriePersonalizada(
      id: insertedId,
      ejercicioRealizado: id,
      repeticiones: baseSerie?.repeticiones ?? 10,
      descanso: baseSerie?.descanso ?? 60,
      rer: baseSerie?.rer ?? 2,
      velocidadRepeticion: baseSerie?.velocidadRepeticion ?? 2,
      peso: baseSerie?.peso ?? 0,
    );
    seriesPersonalizadas ??= [];
    seriesPersonalizadas!.add(nuevaSerie);
    return nuevaSerie;
  }

  Future<void> setOrden(double nuevoOrden) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'rutinas_ejerciciopersonalizado',
      {'peso_orden': nuevoOrden},
      where: 'id = ?',
      whereArgs: [id],
    );
    orden = nuevoOrden;
  }

  int countSeriesPersonalizadas() {
    if (seriesPersonalizadas == null) return 0;
    return seriesPersonalizadas!.length;
  }

  Future<double> calcularVolumen() async {
    try {
      double totalVolumen = 0.0;

      final seriesP = await getSeriesPersonalizadas();

      for (var serieP in seriesP) {
        double tiempoSerieP = serieP.repeticiones * serieP.peso;
        totalVolumen += tiempoSerieP;
      }

      return totalVolumen;
    } catch (e, st) {
      Logger().i('Error al calcular volumen: $e');
      Logger().i('Stack trace: $st');
      return 0;
    }
  }

  // Nuevo método de nivel superior para calcular el tiempo de entrenamiento
  Future<int> calcularTiempo() async {
    try {
      int totalTiempo = 0;

      final seriesP = await getSeriesPersonalizadas();
      for (var serieP in seriesP) {
        int repeticiones = serieP.repeticiones;
        double velocidadRepeticion = serieP.velocidadRepeticion;
        int descanso = serieP.descanso;
        double tiempoSerieP = (repeticiones * 0.2) + (repeticiones * velocidadRepeticion) + descanso;
        if (ejercicio.realizarPorExtremidad) {
          tiempoSerieP *= 2;
        }
        totalTiempo += tiempoSerieP.toInt();
      }
      return totalTiempo;
    } catch (e, st) {
      Logger().i('Error al calcular tiempo: $e');
      Logger().i('Stack trace: $st');
      return 0;
    }
  }
}
