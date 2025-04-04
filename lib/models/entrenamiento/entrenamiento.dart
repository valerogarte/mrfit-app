import 'dart:math' as math;
import 'package:logger/logger.dart';
import '../../data/database_helper.dart';
import '../ejercicio/ejercicio.dart';
import 'ejercicio_realizado.dart';
import 'serie_realizada.dart';
import '../usuario/usuario.dart';

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
  int kcal;

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
    this.kcal = 0,
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
    // Obtiene la fecha y hora actual
    final now = DateTime.now();
    // Calcula la diferencia en horas entre 'fin' y 'now', y la multiplica por -1 para obtener un valor positivo si 'fin' está en el pasado
    final int horasDesdeFin = fin!.difference(now).inHours * -1;
    // Convierte las horas en días
    final double dias = horasDesdeFin / 24.0;
    // Limita el valor de 'dias' entre 0 y 5
    final double maximoTiempoRecuperacion = getDiasMaximoParaRecuperacionMuscular();
    final double d = math.max(0.0, math.min(dias, maximoTiempoRecuperacion));
    // Constante de decaimiento, es la curva, cuanto más alta más rápido decae
    const double kDecay = 1.0;
    // Limita el valor de 'd' a un máximo de 3
    final double tiempoRecuperacion = getDiasParaRecuperacionMuscular();
    final double dExp = math.min(d, tiempoRecuperacion);
    // Calcula el factor exponencial usando la constante de decaimiento y 'dExp'
    final double factorExpo = math.exp(-kDecay * dExp);
    // Calcula 'r' limitando el valor entre 0 y 1
    final double r = math.max(0.0, math.min((d - 3.0) / 2.0, 1.0));
    // Calcula el factor de recuperación final
    factorRec = factorExpo * (1 - r);
  }

  static List<dynamic>? obtenerEjerciciosEntrenamiento(Map<String, dynamic> entrenamiento) {
    return entrenamiento['ejercicios'] as List<dynamic>?;
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

  int calcularKcal() {
    double kcal = 0;
    for (final ejercicioRealizado in ejercicios) {
      for (final serie in ejercicioRealizado.series) {
        final kcalSerie = serie.calcularKcal();
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

    // print('-Entrenamiento $fin. Peso usuario: $userWeight');

    for (final ejercicioRealizado in ejercicios) {
      final ejercicioVolumen = await ejercicioRealizado.calcularMrPointsTotal(usuario);
      entrenamientoVolumen = entrenamientoVolumen + ejercicioVolumen;
      await ejercicioRealizado.calcularRecuperacionSerie(factorRec, usuario);
    }

    entrenamientoVolumenActual = entrenamientoVolumen * factorRec;
  }

  List<Map<String, dynamic>> getVolumenPorMusculoPorcentaje() {
    final Map<String, double> totalVolumenPorMusculo = {};

    // Para cada ejercicio, usa su método propio
    for (final ejercicioRealizado in ejercicios) {
      for (final entry in ejercicioRealizado.volumenPorMusculo.entries) {
        final musculo = entry.key;
        final vol = entry.value['gastoDelMusculoPorcentaje'];
        totalVolumenPorMusculo[musculo] = (totalVolumenPorMusculo[musculo] ?? 0) + vol;
      }
    }

    return totalVolumenPorMusculo.entries.map((entry) {
      return {
        entry.key: entry.value,
      };
    }).toList();
  }

  List<Map<String, dynamic>> getVolumenActualPorMusculoPorcentaje() {
    final Map<String, double> totalVolumenPorMusculo = {};

    // Para cada ejercicio, usa su método propio
    for (final ejercicioRealizado in ejercicios) {
      for (final entry in ejercicioRealizado.volumenPorMusculo.entries) {
        final musculo = entry.key;
        final vol = entry.value['gastoDelMusculoPorcentajeActual'];
        totalVolumenPorMusculo[musculo] = (totalVolumenPorMusculo[musculo] ?? 0) + vol;
      }
    }

    return totalVolumenPorMusculo.entries.map((entry) {
      return {
        entry.key: entry.value,
      };
    }).toList();
  }

  List<Map<String, dynamic>> getVolumenActualPorMusculo() {
    final Map<String, double> totalVolumenPorMusculo = {};

    // Para cada ejercicio, usa su método propio
    for (final ejercicioRealizado in ejercicios) {
      for (final entry in ejercicioRealizado.volumenPorMusculo.entries) {
        final musculo = entry.key;
        final vol = entry.value['volumenMusculoEnEjercicio'];
        totalVolumenPorMusculo[musculo] = (totalVolumenPorMusculo[musculo] ?? 0) + vol;
      }
    }

    return totalVolumenPorMusculo.entries.map((entry) {
      return {
        entry.key: entry.value,
      };
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

  static Future<Entrenamiento?> loadById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('entrenamiento_entrenamiento', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;
    final row = res.first;

    // Use DateTime.now() as fallback when 'inicio' or 'fin' is null.
    final inicio = row['inicio'] != null ? DateTime.parse(row['inicio'] as String) : DateTime.now();
    final fin = row['fin'] != null ? DateTime.parse(row['fin'] as String) : DateTime.now();
    final sesionId = row['sesion_id'];

    // Cargar la sesion
    final sesionData = await db.query('rutinas_sesion', where: 'id = ?', whereArgs: [sesionId], limit: 1);
    // Updated the following line to provide a default empty string if 'titulo' is null.
    final String sesionNombre = sesionData.first["titulo"] as String? ?? '';

    // Add null check for peso_usuario
    final double pesoUsuario = (row['peso_usuario'] == null) ? 0.0 : (row['peso_usuario'] as num).toDouble();

    final ejerciciosData = await db.query(
      'entrenamiento_ejerciciorealizado',
      where: 'entrenamiento_id = ?',
      whereArgs: [id],
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
        ),
      );
    }

    return Entrenamiento(
      id: row['id'] as int,
      titulo: sesionNombre,
      inicio: inicio,
      fin: fin,
      pesoUsuario: pesoUsuario,
      sesion: sesionId as int,
      ejercicios: ejerciciosRealizados,
      sensacion: row['sensacion'] != null ? (row['sensacion'] as int) : 0,
    );
  }

  Future<void> finalizar() async {
    fin = DateTime.now();
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'entrenamiento_entrenamiento',
        {'fin': fin!.toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      final logger = Logger();
      logger.i('Error al finalizar entrenamiento $id: $e');
      logger.i('Stack trace: $st');
    }
  }

  Future<void> delete() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'entrenamiento_entrenamiento',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
