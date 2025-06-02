import 'dart:math';
import 'package:mrfit/data/database_helper.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/models/modelo_datos.dart';
import 'package:mrfit/models/usuario/usuario.dart';

class SerieRealizada {
  final int id;
  final int ejercicioRealizado;
  int repeticiones;
  int repeticionesObjetivo;
  double peso;
  double pesoObjetivo;
  final double velocidadRepeticion;
  int descanso;
  int rer;
  DateTime inicio;
  DateTime? fin;
  bool realizada;
  bool extra;
  bool deleted;
  int kcal;

  SerieRealizada({
    required this.id,
    required this.ejercicioRealizado,
    required this.repeticiones,
    required this.repeticionesObjetivo,
    required this.peso,
    required this.pesoObjetivo,
    required this.velocidadRepeticion,
    required this.descanso,
    required this.rer,
    required this.inicio,
    this.fin,
    required this.realizada,
    required this.extra,
    required this.deleted,
    this.kcal = 0,
  });

  factory SerieRealizada.fromJson(Map<String, dynamic> json) {
    return SerieRealizada(
      id: json['id'],
      ejercicioRealizado: json['ejercicio_realizado_id'],
      repeticiones: json['repeticiones'],
      repeticionesObjetivo: json['repeticiones_objetivo'] ?? json['repeticiones'],
      peso: (json['peso'] ?? 0).toDouble(),
      pesoObjetivo: (json['peso_objetivo'] ?? json['peso'] ?? 0).toDouble(),
      velocidadRepeticion: (json['velocidad_repeticion'] ?? 0).toDouble(),
      descanso: json['descanso'],
      rer: json['rer'],
      inicio: DateTime.parse(json['inicio']),
      fin: json['fin'] != null ? DateTime.parse(json['fin']) : null,
      realizada: json['realizada'] == 1,
      extra: json['extra'] == 1,
      deleted: json['deleted'] == 1,
      kcal: 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ejercicio_realizado_id': ejercicioRealizado,
      'repeticiones': repeticiones,
      'repeticiones_objetivo': repeticionesObjetivo,
      'peso': peso,
      'peso_objetivo': pesoObjetivo,
      'velocidad_repeticion': velocidadRepeticion,
      'descanso': descanso,
      'rer': rer,
      'inicio': inicio.toIso8601String(),
      'fin': fin?.toIso8601String(),
      'realizada': realizada,
      'extra': extra,
      'deleted': deleted,
      'kcal': kcal,
    };
  }

  /// Calcula el volumen de esta serie
  Future<double> calcularMrPoints(Ejercicio ej, Usuario usuario) async {
    // Reps
    final double reps = repeticiones.toDouble();

    // Ajuste de peso (por si es peso corporal)
    double pesoFinal = peso;
    final double pctUsoPesoCorporal = (ej.influenciaPesoCorporal >= 0.1) ? (ej.influenciaPesoCorporal - 0.1) : ej.influenciaPesoCorporal;
    final double userWeight = await usuario.getCurrentWeight();
    pesoFinal = (userWeight * pctUsoPesoCorporal) + pesoFinal;

    // Esfuerzo extra si la serie es 'extra'
    double esfuerzoExtra = (!extra) ? 1.0 : 1.2;

    // Dificultad
    int dificultadInt = 1;
    if (ej.dificultad.titulo.isNotEmpty) {
      dificultadInt = int.tryParse(ej.dificultad.titulo) ?? 1;
    }

    // Si el usuario apenas descansa, lo tengo en cuenta
    double multiplierDescanso = 0;
    if (descanso >= 60) {
      multiplierDescanso = 1.0;
    } else {
      final double k = 0.69314718 / 30; // log(2)/30
      multiplierDescanso = 0.5 * ((exp(-k * descanso) - exp(-k * 60)) / (1 - exp(-k * 60)));
    }

    // Edad del usuario
    // final int edad = DateTime.now().year - usuario.fechaNacimiento.year;

    var totalVolumen = reps * (pesoFinal + 1.0) * (dificultadInt * 0.1 + 1) * esfuerzoExtra * multiplierDescanso + (rer * 0);
    totalVolumen = double.parse(totalVolumen.toStringAsFixed(2));

    // final logger = Logger();
    // logger.i('($reps reps) * ($pesoFinal peso) * ($dificultadInt dificultad) * ($esfuerzoExtra esfuerzoExtra) * ($multiplierDescanso descanso) * ($rer rer) = $totalVolumen kg');

    return totalVolumen;
  }

  double calcularDuracionEjercicioSerie() {
    double duracion = (velocidadRepeticion * repeticiones);
    return duracion;
  }

  double calcularKcal(double pesoUsuario) {
    if (realizada == false) return 0;
    if (rer == 0) rer = 3;
    // MET = Metabolic Equivalent of Task
    // Kcal = MET × peso (kg) × duración (h)
    final duracion = calcularDuracionEjercicioSerie();
    final opcion = ModeloDatos.getDifficultyOptions(value: rer);
    final metEntrenando = opcion != null ? opcion['met'] : 3.0;
    final duracionHorasEntrenando = duracion / 3600;
    double kcalEntrenando = metEntrenando * pesoUsuario * duracionHorasEntrenando;

    // El MET de descanso es el mayor entre (metEntrenando * 0.5) y 1.5.
    final metDescanso = (metEntrenando * 0.5) > 1.5 ? (metEntrenando * 0.5) : 1.5;
    final duracionHorasDescanso = descanso / 3600;
    final double kcalDescanso = metDescanso * pesoUsuario * duracionHorasDescanso;

    double kcal = kcalEntrenando + kcalDescanso;

    kcal = double.parse(kcal.toStringAsFixed(2));
    return kcal;
  }

  Future<void> delete() async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'entrenamiento_serierealizada',
      {'deleted': '1'},
      where: 'id = ?',
      whereArgs: [id],
    );
    deleted = true;
  }

  Future<void> save() async {
    final db = await DatabaseHelper.instance.database;
    final data = {
      'repeticiones': repeticiones,
      'peso': peso,
      'descanso': descanso,
      'rer': rer,
      'fin': fin?.toIso8601String(),
      'realizada': realizada,
      'extra': extra,
      'deleted': deleted,
    };
    await db.update(
      'entrenamiento_serierealizada',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setInicio() async {
    inicio = DateTime.now();
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'entrenamiento_serierealizada',
      {
        'inicio': inicio.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setRealizada() async {
    realizada = true;
    fin = DateTime.now();
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'entrenamiento_serierealizada',
      {
        'realizada': 1,
        'fin': fin!.toIso8601String(),
        'repeticiones': repeticiones,
        'peso': peso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setRer(int repsEnReserva) async {
    rer = repsEnReserva;
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'entrenamiento_serierealizada',
      {
        'rer': repsEnReserva,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateRepesPeso() async {
    realizada = true;
    fin = DateTime.now();
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'entrenamiento_serierealizada',
      {
        'repeticiones': repeticiones,
        'peso': peso,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
