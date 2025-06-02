import 'package:logger/logger.dart';
import 'package:mrfit/data/database_helper.dart';
import 'ejercicio_personalizado.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/mr_functions.dart';

class Sesion {
  final int id;
  String titulo;
  int orden;
  int dificultad;
  List<EjercicioPersonalizado> ejerciciosPersonalizados = [];

  Sesion({
    required this.id,
    required this.titulo,
    required this.orden,
    this.dificultad = 1,
  });

  factory Sesion.fromJson(Map<String, dynamic> json) {
    return Sesion(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      orden: json['orden'],
      dificultad: json['dificultad'] ?? 1,
    );
  }

  static Future<Sesion?> loadById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'rutinas_sesion',
      columns: ['id', 'titulo', 'orden', 'dificultad'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    final json = result.first;
    final sesion = Sesion(
      id: id,
      titulo: json['titulo'] as String,
      orden: json['orden'] as int,
      dificultad: json['dificultad'] != null ? json['dificultad'] as int : 1,
    );
    await sesion.getEjercicios();
    return sesion;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'orden': orden,
      'dificultad': dificultad,
      'ejerciciosPersonalizados': ejerciciosPersonalizados.map((e) => e.toJson()).toList(),
    };
  }

  Future<int> rename(String nuevoTitulo) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.update(
      'rutinas_sesion',
      {'titulo': nuevoTitulo},
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<int> delete() async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'rutinas_sesion',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<List<EjercicioPersonalizado>> getEjercicios() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.query(
        'rutinas_ejerciciopersonalizado',
        where: 'sesion_id = ?',
        whereArgs: [id],
        orderBy: 'peso_orden ASC',
      );
      ejerciciosPersonalizados = await Future.wait(result.map((json) async => EjercicioPersonalizado.fromJson(json)).toList());
      for (final ejercicio in ejerciciosPersonalizados) {
        await ejercicio.getSeriesPersonalizadas();
      }
    } catch (e, st) {
      final logger = Logger();
      logger.i('Error al cargar ejercicios para sesión $id: $e');
      logger.i('Stack trace: $st');
    }
    return ejerciciosPersonalizados;
  }

  Future<int> getEjerciciosCount() async {
    if (ejerciciosPersonalizados.isEmpty) {
      await getEjercicios();
    }
    return ejerciciosPersonalizados.length;
  }

  Future<String> calcularTiempoEntrenamiento() async {
    try {
      if (ejerciciosPersonalizados.isEmpty) {
        await getEjercicios();
      }
      if (ejerciciosPersonalizados.isEmpty) {
        return "Sin tiempo.";
      }
      int totalTiempo = 0;
      const introduccion = 30;
      totalTiempo += introduccion;
      for (var ejercicioP in ejerciciosPersonalizados) {
        totalTiempo += (await ejercicioP.calcularTiempo());
      }
      return MrFunctions.formatDuration(Duration(seconds: totalTiempo));
    } catch (e, st) {
      final logger = Logger();
      logger.i('Error al calcular tiempo: $e');
      logger.i('Stack trace: $st');
      return "Error al calcular.";
    }
  }

  Future<int> updateOrden(int nuevoOrden) async {
    final db = await DatabaseHelper.instance.database;
    orden = nuevoOrden;
    final result = await db.update(
      'rutinas_sesion',
      {'orden': nuevoOrden},
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<int> setDificultad(int nuevaDificultad) async {
    final db = await DatabaseHelper.instance.database;
    dificultad = nuevaDificultad;
    final result = await db.update(
      'rutinas_sesion',
      {'dificultad': nuevaDificultad},
      where: 'id = ?',
      whereArgs: [id],
    );
    return result;
  }

  Future<int> insertarEjercicioPersonalizado(Ejercicio ejercicio) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(MAX(peso_orden), 0) as maxPeso FROM rutinas_ejerciciopersonalizado WHERE sesion_id = ?',
      [id],
    );
    final currentMax = result.first['maxPeso'] as num;
    final nuevoPesoOrden = currentMax + 1;
    return await db.insert(
      'rutinas_ejerciciopersonalizado',
      {
        'ejercicio_id': ejercicio.id,
        'sesion_id': id,
        'peso_orden': nuevoPesoOrden,
      },
    );
  }

  Future<int?> isEntrenandoAhora() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT id FROM entrenamiento_entrenamiento WHERE sesion_id = ? AND fin IS NULL",
      [id],
    );
    if (result.isNotEmpty) {
      return result.first["id"] as int;
    }
    return null;
  }

  Future<Entrenamiento?> empezarEntrenamiento(Usuario usuario) async {
    final db = await DatabaseHelper.instance.database;
    final nowStr = DateTime.now().toIso8601String();
    final pesoUsuario = await usuario.getCurrentWeight();
    final entrenamientoId = await db.insert(
      'entrenamiento_entrenamiento',
      {
        'inicio': nowStr,
        'titulo': titulo,
        'fin': null,
        'sesion_id': id,
        'usuario_id': 1,
        'peso_usuario': pesoUsuario,
      },
    );
    if (ejerciciosPersonalizados.isEmpty) {
      await getEjercicios();
    }
    int pesoOrden = 0;
    for (var ejercicioP in ejerciciosPersonalizados) {
      final ejercicioRealizadoId = await db.insert(
        'entrenamiento_ejerciciorealizado',
        {
          'ejercicio_id': ejercicioP.ejercicio.id,
          'entrenamiento_id': entrenamientoId,
          'peso_orden': pesoOrden,
        },
      );
      if (ejercicioP.seriesPersonalizadas == null || ejercicioP.seriesPersonalizadas!.isEmpty) {
        await ejercicioP.getSeriesPersonalizadas();
      }
      for (var serieP in ejercicioP.seriesPersonalizadas!) {
        await db.insert(
          'entrenamiento_serierealizada',
          {
            'peso': serieP.peso,
            'peso_objetivo': serieP.peso,
            'repeticiones': serieP.repeticiones,
            'repeticiones_objetivo': serieP.repeticiones,
            'descanso': serieP.descanso,
            'fin': null,
            'inicio': nowStr,
            'rer': 0,
            'velocidad_repeticion': serieP.velocidadRepeticion,
            'extra': 0,
            'realizada': 0,
            'deleted': 0,
            'ejercicio_realizado_id': ejercicioRealizadoId,
          },
        );
      }
      pesoOrden++;
    }
    return Entrenamiento.loadById(entrenamientoId);
  }

  Future<List<Map<String, dynamic>>> getMusculosInvoluracion() async {
    if (ejerciciosPersonalizados.isEmpty) {
      await getEjercicios();
    }
    final Map<String, int> muscleTotals = {};
    for (final ejercicioP in ejerciciosPersonalizados) {
      for (final mInvol in ejercicioP.ejercicio.musculosInvolucrados) {
        muscleTotals[mInvol.musculo.titulo] = (muscleTotals[mInvol.musculo.titulo] ?? 0) + mInvol.porcentajeImplicacion;
      }
    }
    final totalGlobal = muscleTotals.values.fold(0, (a, b) => a + b);
    if (totalGlobal == 0) {
      return [];
    }
    final List<Map<String, dynamic>> result = [];
    muscleTotals.forEach((muscle, value) {
      final porcentaje = (value / totalGlobal) * 100.0;
      result.add({
        'musculo': muscle,
        'porcentaje': porcentaje.toStringAsFixed(2),
      });
    });
    result.sort((a, b) => double.parse(b['porcentaje']).compareTo(double.parse(a['porcentaje'])));
    return result;
  }

  Future<List<Map<String, dynamic>>> getInfo() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'entrenamiento_entrenamiento',
      columns: ['id', 'inicio', 'fin'],
      where: 'sesion_id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return [];
    final nSesions = result.length;
    int totalSeconds = 0;
    for (final row in result) {
      final inicio = DateTime.parse(row['inicio'] as String);
      final fin = row['fin'] != null ? DateTime.parse(row['fin'] as String) : DateTime.now();
      totalSeconds += fin.difference(inicio).inSeconds;
    }
    final tiempoTotal = MrFunctions.formatDuration(Duration(seconds: totalSeconds));
    final avgDuration = nSesions > 0 ? MrFunctions.formatDuration(Duration(seconds: totalSeconds ~/ nSesions)) : '00:00';
    final setsResult = await db.rawQuery(
      '''
    SELECT COUNT(*) as totalSets FROM entrenamiento_serierealizada
    WHERE ejercicio_realizado_id IN (
      SELECT id FROM entrenamiento_ejerciciorealizado
      WHERE entrenamiento_id IN (
        SELECT id FROM entrenamiento_entrenamiento
        WHERE sesion_id = ?
      )
    )
    ''',
      [id],
    );
    final setsCompleted = setsResult.first['totalSets'] as int;
    return [
      {'numero_sesiones': nSesions.toString()},
      {'tiempo_total': tiempoTotal},
      {'duración_media': avgDuration},
      {'sets_completados': setsCompleted.toString()},
    ];
  }

  Future<Map<String, dynamic>> getVolumenEntrenamiento() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''
    SELECT et.inicio, SUM(ser.peso * ser.repeticiones) as volumen_total
    FROM entrenamiento_serierealizada ser
    JOIN entrenamiento_ejerciciorealizado er ON ser.ejercicio_realizado_id = er.id
    JOIN entrenamiento_entrenamiento et ON er.entrenamiento_id = et.id
    WHERE et.sesion_id = ?
    GROUP BY et.id
    ORDER BY et.inicio ASC
    ''',
      [id],
    );
    List<String> labels = [];
    List<double> values = [];
    for (final row in result) {
      final fecha = row['inicio'] as String;
      double volumen = 0;
      if (row['volumen_total'] is int) {
        volumen = (row['volumen_total'] as int).toDouble();
      } else if (row['volumen_total'] is double) {
        volumen = row['volumen_total'] as double;
      }
      labels.add(fecha);
      values.add(volumen);
    }
    return {
      'labels': labels,
      'values': values,
    };
  }

  Future<DateTime?> getTimeUltimoEntrenamiento() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'entrenamiento_entrenamiento',
      columns: ['fin'],
      where: 'sesion_id = ?',
      whereArgs: [id],
      orderBy: 'fin DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    final fin = result.first['fin'];
    if (fin == null) return null;
    return DateTime.tryParse(fin as String);
  }
}
