import '../ejercicio/ejercicio.dart';
import 'serie_realizada.dart';
import '../usuario/usuario.dart';
import '../../data/database_helper.dart';

class EjercicioRealizado {
  final int id;
  final Ejercicio ejercicio;
  final List<SerieRealizada> series;
  int pesoOrden = 0;
  Map<String, dynamic> volumenPorMusculo = {};
  double volumenTotal = 0.0;
  double volumenTotalActual = 0.0;
  bool deleted;

  EjercicioRealizado({required this.id, required this.ejercicio, required this.series, required this.pesoOrden, this.volumenPorMusculo = const {}, this.volumenTotal = 0.0, this.volumenTotalActual = 0.0, this.deleted = false});

  factory EjercicioRealizado.fromJson(Map<String, dynamic> json) {
    return EjercicioRealizado(
      id: json['id'],
      ejercicio: Ejercicio.fromJson(json['ejercicio']),
      series: (json['series'] as List).map((item) => SerieRealizada.fromJson(item)).toList(),
      pesoOrden: json['pesoOrden'] ?? 0,
      volumenPorMusculo: json['volumenPorMusculo'] ?? {},
      volumenTotal: (json['volumenTotal'] ?? 0.0).toDouble(),
      volumenTotalActual: (json['volumenTotalActual'] ?? 0.0).toDouble(),
      deleted: (json['deleted'] == 'true'),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'ejercicio': ejercicio.toJson(), 'series': series.map((s) => s.toJson()).toList(), 'peso_orden': pesoOrden, 'volumenPorMusculo': volumenPorMusculo, 'deleted': deleted.toString()};
  }

  Future<void> setPesoOrden(int peso) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'entrenamiento_ejerciciorealizado',
      {'peso_orden': peso},
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Actualizando el peso orden de $id a $peso');
    pesoOrden = peso;
  }

  int countSeries() {
    return series.length;
  }

  int countSeriesRealizadas() {
    return series.where((serie) => serie.realizada && !serie.deleted).length;
  }

  bool isAllSeriesRealizadas() {
    for (final serie in series) {
      if (!serie.deleted && !serie.realizada) {
        return false;
      }
    }
    return true;
  }

  List<SerieRealizada> getSeriesNoBorradas() {
    return series.where((serie) => !serie.deleted).toList();
  }

  bool hasSeriesNoRealizadas() {
    for (final serie in series) {
      if (!serie.deleted && !serie.realizada) {
        return true;
      }
    }
    return false;
  }

  /// Calcula el volumen total de este ejercicio (sumando el de todas sus series).
  Future<double> calcularMrPointsTotal(Usuario usuario) async {
    double volumenTotal = 0.0;
    for (final serie in series) {
      // Solo sumamos si no está borrada y está realizada
      if (!serie.deleted && serie.realizada) {
        volumenTotal += await serie.calcularMrPoints(ejercicio, usuario);
      }
    }
    this.volumenTotal = double.parse(volumenTotal.toStringAsFixed(2));
    return this.volumenTotal;
  }

  List<Map<String, dynamic>> calcularVolumenPorMusculo() {
    final List<Map<String, dynamic>> resultado = [];

    for (final m in ejercicio.musculosInvolucrados) {
      final nombreMusculo = m.musculo.titulo.toLowerCase().trim();
      final gastoActual = m.porcentajeImplicacion.toDouble();
      resultado.add({
        'musculo': nombreMusculo,
        'volumen': gastoActual,
      });
    }

    return resultado;
  }

  /*
  * Calcula el Volumen Total cogido el ejericio y lo reparte entre los músculos implicados.
  * Revisa el volumen máximo jamás cogido por el usuario y calcula el porcentaje.
  *
  */
  Future<void> calcularRecuperacionSerie(double factorRec, Usuario usuario) async {
    final volumenMaximoJamasCogido = await usuario.getCurrentMrPoints();

    // final nombre = ejercicio.nombre;
    // print('-- $nombre he cogido $volumenTotal kg');

    final implicacionMuscular = ejercicio.obtenerImplicacionMuscular();

    // Create a new modifiable map from the unmodifiable map
    volumenPorMusculo = Map<String, dynamic>.from(volumenPorMusculo);

    for (final entry in implicacionMuscular.entries) {
      var detallesPorMusculo = {};

      final String tituloMusculo = entry.key;
      final double implicacionMusculoEnEjercicio = entry.value;

      final musculoVolumen = volumenTotal * implicacionMusculoEnEjercicio;

      final volumenMaximoJamasCogidoEnMusculo = volumenMaximoJamasCogido[tituloMusculo] ?? 0;
      double volumenRecuperadoPorTiempo = musculoVolumen * factorRec;

      if (musculoVolumen == 0) {
        detallesPorMusculo['volumenMusculoEnEjercicio'] = 0.0;
        detallesPorMusculo['volumenActualMusculoEnEjercicio'] = 0.0;
        detallesPorMusculo['gastoDelMusculoPorcentaje'] = 0.0;
      } else {
        double pctVal = 100.00 - ((musculoVolumen / volumenMaximoJamasCogidoEnMusculo) * 100.0);
        if (pctVal < 1) pctVal = 1;
        detallesPorMusculo['volumenMusculoEnEjercicio'] = musculoVolumen;
        detallesPorMusculo['volumenActualMusculoEnEjercicio'] = volumenRecuperadoPorTiempo;
        detallesPorMusculo['gastoDelMusculoPorcentaje'] = (100 - pctVal);

        // print('---- $tituloMusculo al $implicacionMusculoEnEjercicio% implicación y al ${detallesPorMusculo["gastoDelMusculoPorcentaje"].toStringAsFixed(2)}%');
        // print('------ ${musculoVolumen.toStringAsFixed(2)} kg x$factorRec = ${volumenRecuperadoPorTiempo.toStringAsFixed(2)}');
        // print('------ ${volumenRecuperadoPorTiempo.toStringAsFixed(2)} kg movidos, el músculo aguanta ${volumenMaximoJamasCogidoEnMusculo.toStringAsFixed(2)} kg');
      }

      detallesPorMusculo['volumenMaximoJamasCogidoEnMusculo'] = volumenMaximoJamasCogidoEnMusculo;

      if (volumenRecuperadoPorTiempo == 0) {
        detallesPorMusculo['gastoDelMusculoPorcentajeActual'] = 0.0;
      } else {
        double pctVal = 100 - ((volumenRecuperadoPorTiempo / volumenMaximoJamasCogidoEnMusculo) * 100.0);
        if (pctVal < 1) pctVal = 1;
        detallesPorMusculo['gastoDelMusculoPorcentajeActual'] = (100 - pctVal);
      }

      volumenPorMusculo[tituloMusculo] = detallesPorMusculo;
    }
  }

  // Nuevo método para añadir una nueva SerieRealizada
  Future<SerieRealizada> insertSerieRealizada() async {
    final db = await DatabaseHelper.instance.database;
    final lastSerieRealizada = series.reversed.firstWhere((serie) => !serie.deleted, orElse: () => series.last);
    final data = {
      'repeticiones': lastSerieRealizada.repeticiones,
      'descanso': lastSerieRealizada.descanso,
      'inicio': DateTime.now().toIso8601String(),
      'rer': 0,
      'velocidad_repeticion': lastSerieRealizada.velocidadRepeticion,
      'peso': lastSerieRealizada.peso,
      'ejercicio_realizado_id': id,
      'extra': 1,
      'deleted': 0,
      'realizada': 0,
    };
    final insertedId = await db.insert('entrenamiento_serierealizada', data);
    // Crea una instancia de SeriePersonalizada con el ID insertado
    final nuevaSerie = SerieRealizada(
      id: insertedId,
      ejercicioRealizado: id,
      repeticiones: lastSerieRealizada.repeticiones,
      repeticionesObjetivo: lastSerieRealizada.repeticiones,
      peso: lastSerieRealizada.peso,
      pesoObjetivo: lastSerieRealizada.peso,
      descanso: lastSerieRealizada.descanso,
      rer: 0,
      velocidadRepeticion: lastSerieRealizada.velocidadRepeticion,
      inicio: DateTime.now(),
      fin: null,
      realizada: false,
      extra: true,
      deleted: false,
    );

    series.add(nuevaSerie);

    return nuevaSerie;
  }
}
