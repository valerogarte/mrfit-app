import 'package:logger/logger.dart';
import '../../data/database_helper.dart';
import 'ejercicio_personalizado.dart';
import '../ejercicio/ejercicio.dart';
import '../usuario/usuario.dart';
import '../../models/entrenamiento/entrenamiento.dart';

class Sesion {
  final int id;
  String titulo;
  int orden;
  List<EjercicioPersonalizado> ejerciciosPersonalizados = [];

  Sesion({
    required this.id,
    required this.titulo,
    required this.orden,
  });

  factory Sesion.fromJson(Map<String, dynamic> json) {
    return Sesion(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      orden: json['orden'],
    );
  }

  // Nuevo método estático para cargar una sesión por id
  static Future<Sesion?> loadById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'rutinas_sesion',
      columns: ['id', 'titulo', 'orden'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    final json = result.first;
    final sesion = Sesion(
      id: id,
      titulo: json['titulo'] as String,
      orden: json['orden'] as int,
    );
    await sesion.getEjercicios();
    return sesion;
  }

  // Nuevo método para serializar la instancia de Sesion
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'orden': orden,
      'ejerciciosPersonalizados': ejerciciosPersonalizados.map((e) => e.toJson()).toList(),
    };
  }

  // Nuevo método para renombrar la sesión en la base de datos local
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

  // Método para eliminar una sesión de la rutina usando la base de datos local
  Future<int> delete() async {
    final db = await DatabaseHelper.instance.database;
    return await db.delete(
      'rutinas_sesion',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // Método actualizado para recuperar e inicializar ejerciciosPersonalizados
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

  // Agregar método que retorna el número de ejercicios en formato string
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
      return _formatDuration(Duration(seconds: totalTiempo));
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

  // Inserta un ejercicio personalizado en la base de datos, asociado a esta sesión
  Future<int> insertarEjercicioPersonalizado(Ejercicio ejercicio) async {
    final db = await DatabaseHelper.instance.database;
    // Consulta el peso máximo actual y le suma 1
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

  // Método para comprobar si tiene un entrenamiento activo (sin fecha de fin)
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
        'fin': null,
        'sesion_id': id,
        'usuario_id': 1,
        'peso_usuario': pesoUsuario,
      },
    );

    if (ejerciciosPersonalizados.isEmpty) {
      await getEjercicios();
    }

    for (var ejercicioP in ejerciciosPersonalizados) {
      final ejercicioRealizadoId = await db.insert(
        'entrenamiento_ejerciciorealizado',
        {
          'ejercicio_id': ejercicioP.ejercicio.id,
          'entrenamiento_id': entrenamientoId,
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
    // Ordenar el resultado por porcentaje de mayor a menor
    result.sort((a, b) => double.parse(b['porcentaje']).compareTo(double.parse(a['porcentaje'])));
    return result;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      String hours = twoDigits(duration.inHours);
      return "$hours:$minutes:$seconds";
    } else {
      return "$minutes:$seconds";
    }
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
      // Si 'fin' es null, usamos el momento actual.
      final fin = row['fin'] != null ? DateTime.parse(row['fin'] as String) : DateTime.now();
      totalSeconds += fin.difference(inicio).inSeconds;
    }

    final tiempoTotal = _formatDuration(Duration(seconds: totalSeconds));

    final avgDuration = nSesions > 0 ? _formatDuration(Duration(seconds: totalSeconds ~/ nSesions)) : '00:00';

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
}
