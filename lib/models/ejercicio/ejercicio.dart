import '../../data/database_helper.dart';
import '../../utils/constants.dart';
import '../entrenamiento/serie_realizada.dart';

part 'ejercicio_query.dart';
part 'ejercicio_campos.dart';

class Ejercicio {
  final int id;
  final String nombre;
  final Categoria categoria;
  final String imagenUno;
  final String imagenDos;
  final String imagenMovimiento;
  final Equipamiento equipamiento;
  final bool realizarPorExtremidad;
  final List<MusculoInvolucrado> musculosInvolucrados;
  final List<Instruccion> instrucciones;
  final TipoFuerza tipoFuerza;
  final Dificultad dificultad;
  final Mecanica mecanica;
  final List<ErrorComun> erroresComunes;
  final List<TituloAdicional> titulosAdicionales;
  final double influenciaPesoCorporal;
  final String riesgoLesion;
  final Tiempos tiempos;

  Ejercicio({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.imagenUno,
    required this.imagenDos,
    required this.imagenMovimiento,
    required this.equipamiento,
    required this.realizarPorExtremidad,
    required this.musculosInvolucrados,
    required this.instrucciones,
    required this.tipoFuerza,
    required this.dificultad,
    required this.mecanica,
    required this.erroresComunes,
    required this.titulosAdicionales,
    required this.influenciaPesoCorporal,
    required this.riesgoLesion,
    required this.tiempos,
  });

  static int _parseIntOrThrow(dynamic value, String fieldName) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    throw Exception("Invalid integer for $fieldName: $value");
  }

  static double _parseDoubleOrThrow(dynamic value, String fieldName) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    throw Exception("Invalid double for $fieldName: $value");
  }

  /// Carga el ejercicio completo a partir del id.
  static Future<Ejercicio> loadById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT ex.*,
             equip.titulo AS equip_titulo, equip.imagen AS equip_imagen,
             cat.id AS cat_id, cat.titulo AS cat_titulo, cat.imagen AS cat_imagen,
             dif.id AS dif_id, dif.titulo AS dif_titulo,
             mec.id AS mec_id, mec.titulo AS mec_titulo,
             tf.id AS tf_id, tf.titulo AS tf_titulo
      FROM ejercicios_ejercicio ex
      LEFT JOIN ejercicios_equipamiento equip ON ex.equipamiento_id = equip.id
      LEFT JOIN ejercicios_categoria cat ON ex.categoria_id = cat.id
      LEFT JOIN ejercicios_dificultad dif ON ex.dificultad_id = dif.id
      LEFT JOIN ejercicios_mecanica mec ON ex.mecanica_id = mec.id
      LEFT JOIN ejercicios_tipofuerza tf ON ex.tipo_fuerza_id = tf.id
      WHERE ex.id = ?
      ORDER BY ex.id ASC
    ''', [id]);

    if (result.isEmpty) {
      throw Exception("Ejercicio con id $id no encontrado");
    }
    final row = result.first;

    final muscRows = await db.rawQuery('''
      SELECT em.*, m.titulo AS musc_titulo, m.imagen AS musc_imagen
      FROM ejercicios_ejerciciomusculo em
      LEFT JOIN ejercicios_musculo m ON em.musculo_id = m.id
      WHERE em.ejercicio_id = ?
    ''', [id]);
    final musculosInvolucrados = muscRows
        .map((mr) => MusculoInvolucrado(
              id: mr['id'] as int,
              musculo: Musculo(
                id: mr['musculo_id'] as int? ?? 0,
                titulo: mr['musc_titulo'] as String? ?? '',
                imagen: mr['musc_imagen'] as String? ?? '',
              ),
              tipo: mr['tipo'] as String? ?? '',
              porcentajeImplicacion: mr['porcentaje_implicacion'] as int? ?? 0,
              descripcionImplicacion: mr['descripcion_implicacion'] as String? ?? '',
            ))
        .toList();

    final instrRows = await db.rawQuery('''
      SELECT i.*
      FROM ejercicios_instruccion i
      WHERE i.ejercicio_id = ?
    ''', [id]);
    final instrucciones = instrRows
        .map((ir) => Instruccion(
              id: ir['id'] as int,
              texto: ir['texto'] as String? ?? '',
            ))
        .toList();

    final errRows = await db.rawQuery('''
      SELECT e.*
      FROM ejercicios_errorcomun e
      WHERE e.ejercicio_id = ?
    ''', [id]);
    final erroresComunes = errRows
        .map((er) => ErrorComun(
              id: er['id'] as int,
              texto: er['texto'] as String? ?? '',
            ))
        .toList();

    final titRows = await db.rawQuery('''
      SELECT t.*
      FROM ejercicios_tituloadicional t
      WHERE t.ejercicio_id = ?
    ''', [id]);
    final titulosAdicionales = titRows
        .map((tr) => TituloAdicional(
              id: tr['id'] as int,
              titulo: tr['titulo'] as String? ?? '',
            ))
        .toList();

    final ejercicioReturn = Ejercicio(
      id: _parseIntOrThrow(row['id'], 'id'),
      nombre: row['nombre'] as String? ?? '',
      categoria: Categoria(
        id: _parseIntOrThrow(row['cat_id'], 'cat_id'),
        titulo: row['cat_titulo'] as String? ?? '',
        imagen: row['cat_imagen'] as String? ?? '',
      ),
      imagenUno: row['imagen_uno'] != null && !(row['imagen_uno'] as String).startsWith(AppConstants.hostImages) ? '${AppConstants.hostImages}${row['imagen_uno']}' : row['imagen_uno'] as String? ?? '',
      imagenDos: row['imagen_dos'] != null && !(row['imagen_dos'] as String).startsWith(AppConstants.hostImages) ? '${AppConstants.hostImages}${row['imagen_dos']}' : row['imagen_dos'] as String? ?? '',
      imagenMovimiento: row['imagen_movimiento'] != null && !(row['imagen_movimiento'] as String).startsWith(AppConstants.hostImages) ? '${AppConstants.hostImages}${row['imagen_movimiento']}' : row['imagen_movimiento'] as String? ?? '',
      equipamiento: row['equipamiento_id'] == null
          ? Equipamiento(id: 0, titulo: '', imagen: '')
          : Equipamiento(
              id: row['equipamiento_id'] as int,
              titulo: row['equip_titulo'] as String? ?? '',
              imagen: row['equip_imagen'] as String? ?? '',
            ),
      realizarPorExtremidad: (row['realizar_por_extremidad'] == 1 || row['realizar_por_extremidad'] == true) ? true : false,
      musculosInvolucrados: musculosInvolucrados,
      instrucciones: instrucciones,
      tipoFuerza: TipoFuerza(
        id: row['tf_id'] as int? ?? 0,
        titulo: row['tf_titulo'] as String? ?? '',
      ),
      dificultad: Dificultad(
        id: row['dif_id'] as int? ?? 0,
        titulo: row['dif_titulo'] as String? ?? '',
      ),
      mecanica: Mecanica(
        id: row['mec_id'] as int? ?? 0,
        titulo: row['mec_titulo'] as String? ?? '',
      ),
      erroresComunes: erroresComunes,
      titulosAdicionales: titulosAdicionales,
      influenciaPesoCorporal: _parseDoubleOrThrow(row['influencia_peso_corporal'], 'influencia_peso_corporal'),
      riesgoLesion: row['riesgo_lesion'] as String? ?? '',
      tiempos: Tiempos(
        faseConcentrica: (row['tiempo_fase_concentrica'] as double? ?? 0.0),
        faseExcentrica: (row['tiempo_fase_excentrica'] as double? ?? 0.0),
        faseIsometrica: (row['tiempo_fase_isometrica'] as double? ?? 0.0),
      ),
    );

    return ejercicioReturn;
  }

  factory Ejercicio.fromJson(Map<String, dynamic> json) {
    return Ejercicio(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      categoria: Categoria.fromJson(json['categoria'] ?? {}),
      imagenUno: json['imagen_uno'] != null && !(json['imagen_uno'] as String).startsWith(AppConstants.hostImages) ? '${AppConstants.hostImages}${json['imagen_uno']}' : json['imagen_uno'] ?? '',
      imagenDos: json['imagen_dos'] != null && !(json['imagen_dos'] as String).startsWith(AppConstants.hostImages) ? '${AppConstants.hostImages}${json['imagen_dos']}' : json['imagen_dos'] ?? '',
      imagenMovimiento: json['imagen_movimiento'] != null && !(json['imagen_movimiento'] as String).startsWith(AppConstants.hostImages) ? '${AppConstants.hostImages}${json['imagen_movimiento']}' : json['imagen_movimiento'] ?? '',
      equipamiento: Equipamiento.fromJson(json['equipamiento'] ?? {}),
      realizarPorExtremidad: json['realizar_por_extremidad'] is bool ? json['realizar_por_extremidad'] : ((json['realizar_por_extremidad']?.toString().toLowerCase() ?? 'false') == 'true'),
      musculosInvolucrados: (json['musculos_involucrados'] as List? ?? []).map((m) => MusculoInvolucrado.fromJson(m)).toList(),
      instrucciones: (json['instrucciones'] as List? ?? []).map((i) => Instruccion.fromJson(i)).toList(),
      tipoFuerza: TipoFuerza.fromJson(json['tipo_fuerza'] ?? {}),
      dificultad: Dificultad.fromJson(json['dificultad'] ?? {}),
      mecanica: Mecanica.fromJson(json['mecanica'] ?? {}),
      erroresComunes: (json['errores_comunes'] as List? ?? []).map((e) => ErrorComun.fromJson(e)).toList(),
      titulosAdicionales: (json['titulos_adicionales'] as List? ?? []).map((t) => TituloAdicional.fromJson(t)).toList(),
      influenciaPesoCorporal: (json['influencia_peso_corporal'] ?? 0.0).toDouble(),
      riesgoLesion: json['riesgo_lesion'] ?? '',
      tiempos: Tiempos.fromJson(json['tiempos'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria.toJson(),
      'imagen_uno': imagenUno.startsWith(AppConstants.hostImages) ? imagenUno : '${AppConstants.hostImages}$imagenUno',
      'imagen_dos': imagenDos.startsWith(AppConstants.hostImages) ? imagenDos : '${AppConstants.hostImages}$imagenDos',
      'imagen_movimiento': imagenMovimiento.startsWith(AppConstants.hostImages) ? imagenMovimiento : '${AppConstants.hostImages}$imagenMovimiento',
      'equipamiento': equipamiento.toJson(),
      'realizar_por_extremidad': realizarPorExtremidad,
      'musculos_involucrados': musculosInvolucrados.map((m) => m.toJson()).toList(),
      'instrucciones': instrucciones.map((i) => i.toJson()).toList(),
      'tipo_fuerza': tipoFuerza.toJson(),
      'dificultad': dificultad.toJson(),
      'mecanica': mecanica.toJson(),
      'errores_comunes': erroresComunes.map((e) => e.toJson()).toList(),
      'titulos_adicionales': titulosAdicionales.map((t) => t.toJson()).toList(),
      'influencia_peso_corporal': influenciaPesoCorporal,
      'riesgo_lesion': riesgoLesion,
      'tiempos': tiempos.toJson(),
    };
  }

  /// Devuelve un map con la implicación (en tanto por 1) de cada músculo.
  Map<String, double> obtenerImplicacionMuscular() {
    final Map<String, double> implicaciones = {};
    for (final m in musculosInvolucrados) {
      final String nombreMusculo = m.musculo.titulo.toLowerCase().trim();
      final double porcentaje = m.porcentajeImplicacion.toDouble() / 100.0;
      implicaciones[nombreMusculo] = porcentaje;
    }
    return implicaciones;
  }

  double sumaTiempos() {
    return tiempos.faseConcentrica + tiempos.faseExcentrica + tiempos.faseIsometrica;
  }

  // Optimizado: Reduce las peticiones a base de datos usando un JOIN
  Future<Map<String, dynamic>> getNumeroSeriesPromedioRealizadasPorEntrenamiento() async {
    final db = await DatabaseHelper.instance.database;
    // Consulta única que une ambos registros
    final rows = await db.rawQuery('''
      SELECT er.id as ejercicioRealizadoId, s.repeticiones, s.peso, s.descanso, s.rer, s.inicio, s.fin 
      FROM entrenamiento_ejerciciorealizado er 
      JOIN entrenamiento_serierealizada s ON er.id = s.ejercicio_realizado_id 
      WHERE er.ejercicio_id = ? 
      ORDER BY er.id ASC, s.id ASC
    ''', [id]);

    if (rows.isEmpty) return {'promedioSeries': 0.0, 'detallesSeries': []};

    // Agrupa los resultados por 'ejercicioRealizadoId'
    Map<dynamic, List<Map<String, dynamic>>> grouped = {};
    for (var row in rows) {
      var key = row['ejercicioRealizadoId'];
      grouped.putIfAbsent(key, () => []).add(row);
    }

    List<int> seriesPromedio = [];
    List<Map<String, dynamic>> seriesDetalles = [];

    for (int x = 0; x < grouped.values.length; x++) {
      final group = grouped.values.elementAt(x);
      seriesPromedio.add(group.length);
      for (int i = 0; i < group.length; i++) {
        if (seriesDetalles.length <= i) {
          seriesDetalles.add({'repeticiones': 0, 'peso': 0.0, 'descanso': 0, 'rer': 0, 'countRer': 0, 'count': 0});
        }
        seriesDetalles[i]['repeticiones'] += group[i]['repeticiones'] as int;
        seriesDetalles[i]['peso'] += (group[i]['peso'] as num).toDouble();
        seriesDetalles[i]['descanso'] += group[i]['descanso'];

        // Solo sumar el RER si es mayor que 0
        int rer = group[i]['rer'] as int;
        // La siguiente variable es un bool que confirma si este entrenamiento está entre los 3 últimos
        final bool isUltimosTresEntrenamiento = x >= grouped.values.length - 3;
        if (rer > 0 && isUltimosTresEntrenamiento) {
          seriesDetalles[i]['rer'] += rer;
          seriesDetalles[i]['countRer'] += 1;
        }

        seriesDetalles[i]['count'] += 1;
      }
    }

    final average = seriesPromedio.reduce((a, b) => a + b) / seriesPromedio.length;
    final rounded = (average * 10).round() / 10.0;

    for (var detalle in seriesDetalles) {
      detalle['repeticiones'] = (detalle['repeticiones'] / detalle['count']).round();
      detalle['peso'] = (detalle['peso'] / detalle['count'] * 10).round() / 10.0;
      detalle['descanso'] = (detalle['descanso'] / detalle['count']).round();

      // Dividir RER solo entre el conteo de RER mayores que 0
      if (detalle['countRer'] > 0) {
        detalle['rer'] = (detalle['rer'] / detalle['countRer']).round();
      } else {
        detalle['rer'] = 0;
      }

      detalle.remove('count');
      detalle.remove('countRer');
    }

    return {'promedioSeries': rounded, 'detallesSeries': seriesDetalles};
  }
}
