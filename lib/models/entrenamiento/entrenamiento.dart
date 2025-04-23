import 'dart:math' as math;
import 'package:logger/logger.dart';
import 'package:health/health.dart';
import 'package:mrfit/data/database_helper.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'ejercicio_realizado.dart';
import 'serie_realizada.dart';
import 'package:mrfit/models/usuario/usuario.dart';

class Entrenamiento {
  final int id;
  final String titulo;
  final DateTime inicio;
  DateTime? fin;
  final double pesoUsuario;
  final int sesion;
  final List<EjercicioRealizado> ejercicios;
  double factorRec = 0.0;
  double entrenamientoVolumen = 0.0;
  double entrenamientoVolumenActual = 0.0;
  bool _recoveryCalculated = false;
  int sensacion;
  int kcalConsumidas;
  String? idHealthConnect;

  Entrenamiento({
    required this.id,
    required this.titulo,
    required this.inicio,
    this.fin,
    required this.pesoUsuario,
    required this.sesion,
    required this.ejercicios,
    this.factorRec = 0.0,
    this.entrenamientoVolumen = 0.0,
    this.entrenamientoVolumenActual = 0.0,
    this.sensacion = 0,
    this.kcalConsumidas = 0,
    this.idHealthConnect,
  });

  factory Entrenamiento.fromJson(Map<String, dynamic> json) {
    return Entrenamiento(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      inicio: DateTime.parse(json['inicio']),
      fin: json['fin'] != null ? DateTime.parse(json['fin']) : null,
      pesoUsuario: json['pesoUsuario'],
      sesion: json['sesion'],
      ejercicios: (json['ejercicios'] as List).map((e) => EjercicioRealizado.fromJson(e)).toList(),
      factorRec: json['factorRec'] ?? 0.0,
      entrenamientoVolumen: json['entrenamientoVolumen'] ?? 0.0,
      entrenamientoVolumenActual: json['entrenamientoVolumenActual'] ?? 0.0,
      kcalConsumidas: json['kcal_consumidas'] ?? 0,
      idHealthConnect: json['id_health_connect'],
    );
  }

  int get duracion {
    if (fin == null) return 0;
    return fin!.difference(inicio).inMinutes;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'inicio': inicio.toIso8601String(),
      'fin': fin?.toIso8601String(),
      'pesoUsuario': pesoUsuario,
      'sesion': sesion,
      'ejercicios': ejercicios.map((e) => e.toJson()).toList(),
      'factorRec': factorRec,
      'entrenamientoVolumen': entrenamientoVolumen,
      'entrenamientoVolumenActual': entrenamientoVolumenActual,
      'kcal_consumidas': kcalConsumidas,
      'id_health_connect': idHealthConnect,
    };
  }

  double getDiasMaximoParaRecuperacionMuscular() {
    return 5.0;
  }

  double getDiasParaRecuperacionMuscular() {
    return 3.0;
  }

  void calcularFactorRecuperacion() {
    if (fin == null) {
      factorRec = 0.0;
      return;
    }
    final now = DateTime.now();
    final int horasDesdeFin = fin!.difference(now).inHours * -1;
    final double dias = horasDesdeFin / 24.0;
    final double maximoTiempoRecuperacion = getDiasMaximoParaRecuperacionMuscular();
    final double d = math.max(0.0, math.min(dias, maximoTiempoRecuperacion));
    const double kDecay = 1.0;
    final double tiempoRecuperacion = getDiasParaRecuperacionMuscular();
    final double dExp = math.min(d, tiempoRecuperacion);
    final double factorExpo = math.exp(-kDecay * dExp);
    final double r = math.max(0.0, math.min((d - 3.0) / 2.0, 1.0));
    factorRec = factorExpo * (1 - r);
  }

  Future<int> setSensacion(int sensacionId) async {
    sensacion = sensacionId;
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'entrenamiento_entrenamiento',
      {
        'sensacion': sensacionId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return sensacion;
  }

  Future<int> calcularKcal() async {
    double kcal = 0;
    for (final ejercicioRealizado in ejercicios) {
      for (final serie in ejercicioRealizado.series) {
        final kcalSerie = serie.calcularKcal(pesoUsuario);
        kcal += kcalSerie;
      }
    }
    return kcal.toInt();
  }

  String formatTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(inicio);
    final years = (difference.inDays / 365).floor();
    final months = (difference.inDays / 30).floor();
    final days = difference.inDays;
    final hours = difference.inHours;
    if (years > 0) {
      return 'Hace $years ${years == 1 ? 'año' : 'años'}';
    } else if (months > 0) {
      return 'Hace $months ${months == 1 ? 'mes' : 'meses'}';
    } else if (days > 1) {
      return 'Hace $days días';
    } else if (days == 1 || (now.day != inicio.day && hours < 24)) {
      return 'Ayer';
    } else if (hours < 1) {
      return 'Recientemente';
    } else {
      return 'Hace $hours ${hours == 1 ? 'hora' : 'horas'}';
    }
  }

  Future<void> calcularRecuperacion(Usuario usuario) async {
    if (_recoveryCalculated) return;
    _recoveryCalculated = true;
    calcularFactorRecuperacion();
    final usuario = await Usuario.load();
    for (final ejercicioRealizado in ejercicios) {
      final ejercicioVolumen = await ejercicioRealizado.calcularMrPointsTotal(usuario);
      entrenamientoVolumen = entrenamientoVolumen + ejercicioVolumen;
      await ejercicioRealizado.calcularRecuperacionSerie(factorRec, usuario);
    }
    entrenamientoVolumenActual = entrenamientoVolumen * factorRec;
  }

  List<Map<String, dynamic>> getVolumenPorMusculoPorcentaje() {
    final Map<String, double> totalVolumenPorMusculo = {};
    for (final ejercicioRealizado in ejercicios) {
      for (final entry in ejercicioRealizado.volumenPorMusculo.entries) {
        final musculo = entry.key;
        final vol = entry.value['gastoDelMusculoPorcentaje'];
        totalVolumenPorMusculo[musculo] = (totalVolumenPorMusculo[musculo] ?? 0) + vol;
      }
    }
    return totalVolumenPorMusculo.entries.map((entry) {
      return {entry.key: entry.value};
    }).toList();
  }

  List<Map<String, dynamic>> getVolumenActualPorMusculoPorcentaje() {
    final Map<String, double> totalVolumenPorMusculo = {};
    for (final ejercicioRealizado in ejercicios) {
      for (final entry in ejercicioRealizado.volumenPorMusculo.entries) {
        final musculo = entry.key;
        final vol = entry.value['gastoDelMusculoPorcentajeActual'];
        totalVolumenPorMusculo[musculo] = (totalVolumenPorMusculo[musculo] ?? 0) + vol;
      }
    }
    return totalVolumenPorMusculo.entries.map((entry) {
      return {entry.key: entry.value};
    }).toList();
  }

  List<Map<String, dynamic>> getVolumenActualPorMusculo() {
    final Map<String, double> totalVolumenPorMusculo = {};
    for (final ejercicioRealizado in ejercicios) {
      for (final entry in ejercicioRealizado.volumenPorMusculo.entries) {
        final musculo = entry.key;
        final vol = entry.value['volumenMusculoEnEjercicio'];
        totalVolumenPorMusculo[musculo] = (totalVolumenPorMusculo[musculo] ?? 0) + vol;
      }
    }
    return totalVolumenPorMusculo.entries.map((entry) {
      return {entry.key: entry.value};
    }).toList();
  }

  int countEjercicios() {
    return ejercicios.length;
  }

  int countEjerciciosWithUnlessOneSerieRealizada() {
    return ejercicios.where((e) => e.countSeriesRealizadas() > 0).length;
  }

  int countSeriesRealizadas() {
    return ejercicios.fold(0, (prev, e) => prev + e.countSeriesRealizadas());
  }

  int countRepeticionesRealizadas() {
    int totalRepeticiones = 0;
    for (final ejercicioRealizado in ejercicios) {
      for (final serie in ejercicioRealizado.series) {
        if (serie.realizada && !serie.deleted) {
          totalRepeticiones += serie.repeticiones;
        }
      }
    }
    return totalRepeticiones;
  }

  int getDificultadMedia() {
    final int dificultadMedia = 0;
    return dificultadMedia;
  }

  static Future<Entrenamiento?> loadByUuid(String idHealthConnect) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.query('entrenamiento_entrenamiento', where: 'id_health_connect = ?', whereArgs: [idHealthConnect], limit: 1);
      if (res.isEmpty) return null;
      final row = res.first;
      final idRow = (row["id"] as num).toInt();
      return loadById(idRow);
    } catch (e, st) {
      final logger = Logger();
      logger.e('Error loading entrenamiento by UUID $idHealthConnect: $e');
      logger.e('Stack trace: $st');
      return null;
    }
  }

  static Future<Entrenamiento?> loadById(int id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final res = await db.query('entrenamiento_entrenamiento', where: 'id = ?', whereArgs: [id], limit: 1);
      if (res.isEmpty) return null;
      final row = res.first;
      final inicio = row['inicio'] != null ? DateTime.parse(row['inicio'] as String) : DateTime.now();
      final fin = row['fin'] != null ? DateTime.parse(row['fin'] as String) : DateTime.now();
      final sesionId = row['sesion_id'];
      final sesionData = await db.query('rutinas_sesion', where: 'id = ?', whereArgs: [sesionId], limit: 1);
      final String sesionNombre = sesionData.first["titulo"] as String? ?? '';
      // Updated to handle null or zero
      final double pesoUsuario = (row['peso_usuario'] != null && (row['peso_usuario'] as num) != 0) ? (row['peso_usuario'] as num).toDouble() : 72.0;
      final ejerciciosData = await db.query(
        'entrenamiento_ejerciciorealizado',
        where: 'entrenamiento_id = ?',
        whereArgs: [id],
        orderBy: 'peso_orden ASC',
      );
      final List<EjercicioRealizado> ejerciciosRealizados = [];
      for (final eRow in ejerciciosData) {
        final int ejercicioId = eRow['ejercicio_id'] as int;
        final ejercicio = await Ejercicio.loadById(ejercicioId);
        final seriesData = await db.query(
          'entrenamiento_serierealizada',
          where: 'ejercicio_realizado_id = ?',
          whereArgs: [eRow['id']],
        );
        final List<SerieRealizada> series = seriesData.map((sRow) {
          return SerieRealizada.fromJson({
            'id': sRow['id'],
            'ejercicio_realizado_id': sRow['ejercicio_realizado_id'],
            'repeticiones': sRow['repeticiones'],
            'peso': sRow['peso'],
            'velocidad_repeticion': sRow['velocidad_repeticion'],
            'descanso': sRow['descanso'],
            'rer': sRow['rer'],
            'inicio': sRow['inicio'],
            'fin': sRow['fin'],
            'realizada': sRow['realizada'],
            'extra': sRow['extra'],
            'deleted': sRow['deleted'],
          });
        }).toList();
        ejerciciosRealizados.add(
          EjercicioRealizado(
            id: eRow['id'] as int,
            ejercicio: ejercicio,
            series: series,
            pesoOrden: eRow['peso_orden'] as int,
          ),
        );
      }
      return Entrenamiento(
        id: (row['id'] as num).toInt(),
        titulo: sesionNombre,
        inicio: inicio,
        fin: fin,
        pesoUsuario: pesoUsuario,
        sesion: (sesionId as num).toInt(),
        ejercicios: ejerciciosRealizados,
        sensacion: row['sensacion'] != null ? (row['sensacion'] as num).toInt() : 0,
        kcalConsumidas: row['kcal_consumidas'] != null ? (row['kcal_consumidas'] as num).toInt() : 0,
        idHealthConnect: row['id_health_connect'] != null ? (row['id_health_connect'] as String?) : null,
      );
    } catch (e, st) {
      final logger = Logger();
      logger.e('Error loading entrenamiento by ID $id: $e');
      logger.e('Stack trace: $st');
      return null;
    }
  }

  Future<void> finalizar(Usuario usuario) async {
    fin = DateTime.now();
    try {
      kcalConsumidas = await calcularKcal();
      String idHealthConnect = await usuario.healthconnectRegistrarEntrenamiento(
        titulo,
        inicio,
        fin ?? DateTime.now(),
        kcalConsumidas,
      );

      final db = await DatabaseHelper.instance.database;
      await db.update(
        'entrenamiento_entrenamiento',
        {
          'fin': fin!.toIso8601String(),
          'kcal_consumidas': kcalConsumidas,
          'id_health_connect': idHealthConnect,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      final logger = Logger();
      logger.e('Error al finalizar entrenamiento $id: $e');
      logger.e('Stack trace: $st');
    }
  }

  Future<void> delete() async {
    // Borrar registro en Health Connect si existe
    if (idHealthConnect != null && idHealthConnect != "0") {
      try {
        final success = await Health().deleteByUUID(uuid: idHealthConnect!, type: HealthDataType.WORKOUT);
        if (!success) {
          final logger = Logger();
          logger.e('Error deleting Health Connect record $idHealthConnect: Record not found or already deleted.');
        } else {
          final logger = Logger();
          logger.i('Health Connect record $idHealthConnect deleted successfully.');
        }
      } catch (e, st) {
        final logger = Logger();
        logger.e('Error deleting Health Connect record $idHealthConnect: $e');
        logger.e('Stack trace: $st');
      }
    }

    final db = await DatabaseHelper.instance.database;

    // Borrar las series de cada ejercicio realizado del entrenamiento
    final List<int> ejercicioIds = ejercicios.map((e) => e.id).toList();
    if (ejercicioIds.isNotEmpty) {
      final placeholders = List.filled(ejercicioIds.length, '?').join(',');
      await db.delete(
        'entrenamiento_serierealizada',
        where: 'ejercicio_realizado_id IN ($placeholders)',
        whereArgs: ejercicioIds,
      );
    }

    // Borrar los ejercicios realizados asociados al entrenamiento
    await db.delete(
      'entrenamiento_ejerciciorealizado',
      where: 'entrenamiento_id = ?',
      whereArgs: [id],
    );

    // Borrar el entrenamiento
    await db.delete(
      'entrenamiento_entrenamiento',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
