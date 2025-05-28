import 'package:mrfit/models/modelo_datos.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'usuario_backup.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart';
import 'package:flutter/material.dart';

import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/data/database_helper.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/channel/channel_inactividad.dart';
import 'package:mrfit/utils/constants.dart';
import 'package:mrfit/models/cache/custom_cache.dart';
import 'package:mrfit/models/health/health.dart';

part 'usuario_query.dart';
part 'usuario_mrpoints.dart';
part 'usuario_medals.dart';
part 'usuario_health.dart';
part 'usuario_health/usuario_health_activity.dart';
part 'usuario_health/usuario_health_corporal.dart';
part 'usuario_health/usuario_health_sleep.dart';
part 'usuario_health/usuario_health_nutrition.dart';

class Usuario {
  int id;
  String username;
  bool isStaff;
  bool isActive;
  DateTime dateJoined;
  DateTime? lastLogin;
  Map<String, double> volumenMaximo;
  int objetivoPasosDiarios;
  int objetivoEntrenamientoSemanal;
  int objetivoTiempoEntrenamiento;
  DateTime fechaNacimiento;
  String genero;
  List<dynamic> historiaLesiones;
  List<Equipamiento> equipoEnCasa;
  String experiencia;
  String unidades;
  int entrenadorVolumen;
  int tiempoDescanso;
  double weight;
  int? rutinaActualId;
  Map<String, double>? _cachedMrPoints;
  final Health _health = Health();
  int? altura;
  bool aviso10Segundos;
  bool avisoCuentaAtras;
  int objetivoKcal;
  int primerDiaSemana;
  String unidadDistancia;
  String unidadTamano;
  String unidadesPeso;
  String entrenadorVoz;
  bool entrenadorActivo;
  TimeOfDay? horaFinSueno;
  TimeOfDay? horaInicioSueno;
  bool isHealthConnectAvailable;

  final healthDataTypesString = ModeloDatos().healthDataTypesString;
  final healthDataPermissions = ModeloDatos().healthDataPermissions;

  static void saveUsuario(Usuario usuario) {}

  Usuario({
    required this.id,
    required this.username,
    required this.isStaff,
    required this.isActive,
    required this.dateJoined,
    this.lastLogin,
    this.volumenMaximo = const {},
    required this.objetivoPasosDiarios,
    required this.objetivoEntrenamientoSemanal,
    this.objetivoTiempoEntrenamiento = 0,
    required this.fechaNacimiento,
    required this.genero,
    required this.historiaLesiones,
    required this.equipoEnCasa,
    required this.experiencia,
    required this.unidades,
    required this.entrenadorVolumen,
    required this.tiempoDescanso,
    this.weight = 0.0,
    this.rutinaActualId,
    this.altura,
    this.aviso10Segundos = false,
    this.avisoCuentaAtras = false,
    this.objetivoKcal = 0,
    this.primerDiaSemana = 1,
    this.unidadDistancia = '',
    this.unidadTamano = '',
    this.unidadesPeso = '',
    this.entrenadorVoz = '',
    this.entrenadorActivo = false,
    this.horaFinSueno,
    this.horaInicioSueno,
    this.isHealthConnectAvailable = false,
  });

  static final backup = UsuarioBackup();

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      isStaff: json['is_staff'] ?? false,
      isActive: json['is_active'] ?? false,
      dateJoined: DateTime.parse(json['date_joined']),
      lastLogin: json['last_login'] != null ? DateTime.parse(json['last_login']) : null,
      volumenMaximo: Map<String, double>.from(json['volumen_maximo'] ?? {}),
      objetivoPasosDiarios: json['objetivo_pasos_diarios'] ?? 0,
      objetivoTiempoEntrenamiento: json['objetivo_tiempo_entrenamiento'] ?? 0,
      objetivoKcal: json['objetivo_kcal'] ?? 0,
      objetivoEntrenamientoSemanal: json['objetivo_entrenamiento_semanal'] ?? 0,
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento']),
      genero: json['genero'] ?? '',
      historiaLesiones: json['historia_lesiones'] ?? [],
      equipoEnCasa: (json['equipo_en_casa'] as List?)?.map((e) => Equipamiento.fromJson(e)).toList() ?? [],
      experiencia: json['experiencia'] ?? '',
      unidades: json['unidades'] ?? '',
      entrenadorVolumen: json['entrenador_volumen'] ?? '',
      tiempoDescanso: json['tiempo_descanso'] ?? 0,
      rutinaActualId: json['rutina_actual_id'],
      altura: json['altura']?.toInt(),
      aviso10Segundos: json['aviso_10_segundos'] ?? false,
      avisoCuentaAtras: json['aviso_cuenta_atras'] ?? false,
      primerDiaSemana: json['primer_dia_semana'] ?? 1,
      unidadDistancia: json['unidad_distancia'] ?? '',
      unidadTamano: json['unidad_tamano'] ?? '',
      unidadesPeso: json['unidades_peso'] ?? '',
      entrenadorVoz: json['entrenador_voz']?.toString() ?? '',
      entrenadorActivo: json['entrenador_activo'] ?? false,
      horaFinSueno: json['hora_fin_sueno'] != null
          ? TimeOfDay(
              hour: int.parse((json['hora_fin_sueno'] as String).split(':')[0]),
              minute: int.parse((json['hora_fin_sueno'] as String).split(':')[1]),
            )
          : null,
      horaInicioSueno: json['hora_inicio_sueno'] != null
          ? TimeOfDay(
              hour: int.parse((json['hora_inicio_sueno'] as String).split(':')[0]),
              minute: int.parse((json['hora_inicio_sueno'] as String).split(':')[1]),
            )
          : null,
      isHealthConnectAvailable: json['is_health_connect_available'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'is_staff': isStaff,
      'is_active': isActive,
      'date_joined': dateJoined.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'volumen_maximo': volumenMaximo,
      'objetivo_pasos_diarios': objetivoPasosDiarios,
      'objetivo_entrenamiento_semanal': objetivoEntrenamientoSemanal,
      'objetivo_tiempo_entrenamiento': objetivoTiempoEntrenamiento,
      'fecha_nacimiento': fechaNacimiento.toIso8601String(),
      'genero': genero,
      'historia_lesiones': historiaLesiones,
      'equipo_en_casa': equipoEnCasa.map((e) => e.toJson()).toList(),
      'experiencia': experiencia,
      'unidades': unidades,
      'entrenador_volumen': entrenadorVolumen,
      'tiempo_descanso': tiempoDescanso,
      'rutina_actual_id': rutinaActualId, // Incluir el nuevo campo en el JSON
      'altura': altura,
      'aviso_10_segundos': aviso10Segundos,
      'aviso_cuenta_atras': avisoCuentaAtras,
      'objetivo_kcal': objetivoKcal,
      'primer_dia_semana': primerDiaSemana,
      'unidad_distancia': unidadDistancia,
      'unidad_tamano': unidadTamano,
      'unidades_peso': unidadesPeso,
      'entrenador_voz': entrenadorVoz,
      'entrenador_activo': entrenadorActivo,
      'hora_fin_sueno': horaFinSueno != null ? '${horaFinSueno!.hour.toString().padLeft(2, '0')}:${horaFinSueno!.minute.toString().padLeft(2, '0')}' : null,
      'hora_inicio_sueno': horaInicioSueno != null ? '${horaInicioSueno!.hour.toString().padLeft(2, '0')}:${horaInicioSueno!.minute.toString().padLeft(2, '0')}' : null,
      'is_health_connect_available': isHealthConnectAvailable,
    };
  }

  bool setHealthConnectAvaliable(hcAvaliable) {
    isHealthConnectAvailable = hcAvaliable;
    return isHealthConnectAvailable;
  }
  // Métodos set para actualizar campos en la tabla auth_user

  Future<bool> setAltura(int altura) async {
    this.altura = altura;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'altura': altura}, where: 'id = ?', whereArgs: [1]);
    // Lo meto en HC
    if (isHealthConnectAvailable) {
      if (await checkPermissionsFor("HEIGHT")) {
        bool success = await setHeight(altura);
        return count > 0 && success;
      }
    }
    return count > 0;
  }

  Future<bool> setAviso10Segundos(bool aviso10Segundos) async {
    this.aviso10Segundos = aviso10Segundos;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'aviso_10_segundos': aviso10Segundos ? 1 : 0}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setAvisoCuentaAtras(bool avisoCuentaAtras) async {
    this.avisoCuentaAtras = avisoCuentaAtras;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'aviso_cuenta_atras': avisoCuentaAtras ? 1 : 0}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setObjetivoKcal(int objetivoKcal) async {
    this.objetivoKcal = objetivoKcal;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'objetivo_kcal': objetivoKcal}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setPrimerDiaSemana(int primerDiaSemana) async {
    this.primerDiaSemana = primerDiaSemana;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'primer_dia_semana': primerDiaSemana}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setUnidadDistancia(String unidadDistancia) async {
    this.unidadDistancia = unidadDistancia;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'unidad_distancia': unidadDistancia}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setUnidadTamano(String unidadTamano) async {
    this.unidadTamano = unidadTamano;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'unidad_tamano': unidadTamano}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setUnidadesPeso(String unidadesPeso) async {
    this.unidadesPeso = unidadesPeso;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'unidades_peso': unidadesPeso}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setEntrenadorVoz(String entrenadorVoz) async {
    this.entrenadorVoz = entrenadorVoz;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'entrenador_voz': entrenadorVoz}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setEntrenadorActivo(bool entrenadorActivo) async {
    this.entrenadorActivo = entrenadorActivo;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'entrenador_activo': entrenadorActivo ? 1 : 0}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setUsername(String username) async {
    this.username = username;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'username': username}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setIsStaff(bool isStaff) async {
    this.isStaff = isStaff;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'is_staff': isStaff ? 1 : 0}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setIsActive(bool isActive) async {
    this.isActive = isActive;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'is_active': isActive ? 1 : 0}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setDateJoined(DateTime dateJoined) async {
    this.dateJoined = dateJoined;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'date_joined': dateJoined.toIso8601String()}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setLastLogin(DateTime? lastLogin) async {
    this.lastLogin = lastLogin;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'last_login': lastLogin?.toIso8601String()}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setExperiencia(String experiencia) async {
    this.experiencia = experiencia;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'experiencia': experiencia}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setFechaNacimiento(DateTime fechaNacimiento) async {
    this.fechaNacimiento = fechaNacimiento;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'fecha_nacimiento': fechaNacimiento.toIso8601String()}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setGenero(String genero) async {
    this.genero = genero;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'genero': genero}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setHistoriaLesiones(List<dynamic> historiaLesiones) async {
    this.historiaLesiones = historiaLesiones;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'historia_lesiones': historiaLesiones}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setObjetivoEntrenamientoSemanal(int objetivoEntrenamientoSemanal) async {
    this.objetivoEntrenamientoSemanal = objetivoEntrenamientoSemanal;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'objetivo_entrenamiento_semanal': objetivoEntrenamientoSemanal}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setObjetivoPasosDiarios(int objetivoPasosDiarios) async {
    this.objetivoPasosDiarios = objetivoPasosDiarios;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'objetivo_pasos_diarios': objetivoPasosDiarios}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setEntrenadorVolumen(int entrenadorVolumen) async {
    this.entrenadorVolumen = entrenadorVolumen;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'entrenador_volumen': entrenadorVolumen}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setTiempoDescanso(int tiempoDescanso) async {
    this.tiempoDescanso = tiempoDescanso;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'tiempo_descanso': tiempoDescanso}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setUnidades(String unidades) async {
    this.unidades = unidades;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'unidades': unidades}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  // Método para establecer la rutina actual
  Future<bool> setRutinaActual(int? rutinaId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      int count = await db.update('auth_user', {'rutina_actual_id': rutinaId}, where: 'id = ?', whereArgs: [1]);

      if (count > 0) {
        rutinaActualId = rutinaId;
        return true;
      }
      return false;
    } catch (e) {
      Logger().e('Error al establecer rutina actual: $e');
      return false;
    }
  }

  // Método para obtener la rutina actual
  Future<Rutina?> getRutinaActual() async {
    if (rutinaActualId == null) return null;

    try {
      return await Rutina.loadById(rutinaActualId!);
    } catch (e) {
      Logger().e('Error al obtener rutina actual: $e');
      return null;
    }
  }

  Future<bool> setObjetivoTiempoEntrenamiento(int objetivoTiempoEntrenamiento) async {
    this.objetivoTiempoEntrenamiento = objetivoTiempoEntrenamiento;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update(
      'auth_user',
      {'objetivo_tiempo_entrenamiento': objetivoTiempoEntrenamiento},
      where: 'id = ?',
      whereArgs: [1],
    );
    return count > 0;
  }

  static Future<Usuario> load() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.rawQuery('SELECT * FROM auth_user WHERE id = ?', [1]);
      if (results.isEmpty) throw Exception('User not found');
      final row = results.first;
      final historiaLesiones = row['historia_lesiones'] is String ? jsonDecode(row['historia_lesiones'].toString()) : (row['historia_lesiones'] ?? []);

      final usuario = Usuario(
        id: row['id'] is int ? row['id'] as int : (int.tryParse(row['id']?.toString() ?? '') ?? 0),
        username: row['username']?.toString() ?? '',
        isStaff: row['is_staff'] == 1,
        isActive: row['is_active'] == 1,
        dateJoined: DateTime.parse(row['date_joined'].toString()),
        lastLogin: row['last_login'] != null ? DateTime.parse(row['last_login'].toString()) : null,
        objetivoPasosDiarios: row['objetivo_pasos_diarios'] is int ? row['objetivo_pasos_diarios'] as int : (int.tryParse(row['objetivo_pasos_diarios']?.toString() ?? '') ?? 0),
        objetivoEntrenamientoSemanal: row['objetivo_entrenamiento_semanal'] is int ? row['objetivo_entrenamiento_semanal'] as int : (int.tryParse(row['objetivo_entrenamiento_semanal']?.toString() ?? '') ?? 0),
        objetivoTiempoEntrenamiento: row['objetivo_tiempo_entrenamiento'] is int ? row['objetivo_tiempo_entrenamiento'] as int : (int.tryParse(row['objetivo_tiempo_entrenamiento']?.toString() ?? '') ?? 0),
        fechaNacimiento: row['fecha_nacimiento'] != null ? DateTime.parse(row['fecha_nacimiento'].toString()) : DateTime.now().subtract(const Duration(days: 365 * 30)),
        genero: row['genero']?.toString() ?? '',
        historiaLesiones: historiaLesiones,
        equipoEnCasa: [], // default empty list
        experiencia: row['experiencia']?.toString() ?? '',
        unidades: row['unidades']?.toString() ?? '',
        entrenadorVolumen: row['entrenador_volumen'] is int ? row['entrenador_volumen'] as int : (int.tryParse(row['entrenador_volumen']?.toString() ?? '') ?? 0),
        tiempoDescanso: row['tiempo_descanso'] is int ? row['tiempo_descanso'] as int : (int.tryParse(row['tiempo_descanso']?.toString() ?? '') ?? 0),
        rutinaActualId: row['rutina_actual_id'] is int ? row['rutina_actual_id'] as int : (int.tryParse(row['rutina_actual_id']?.toString() ?? '')), // Cargar rutina_actual_id
        altura: row['altura'] != null ? (row['altura'] as num).toInt() : null,
        aviso10Segundos: row['aviso_10_segundos'] == 1,
        avisoCuentaAtras: row['aviso_cuenta_atras'] == 1,
        objetivoKcal: row['objetivo_kcal'] is int ? row['objetivo_kcal'] as int : 0,
        primerDiaSemana: row['primer_dia_semana'] is int ? row['primer_dia_semana'] as int : 1,
        unidadDistancia: row['unidad_distancia']?.toString() ?? '',
        unidadTamano: row['unidad_tamano']?.toString() ?? '',
        unidadesPeso: row['unidades_peso']?.toString() ?? '',
        entrenadorVoz: row['entrenador_voz']?.toString() ?? '',
        entrenadorActivo: row['entrenador_activo'] == 1,
        horaFinSueno: row['hora_fin_sueno'] != null
            ? TimeOfDay(
                hour: int.parse((row['hora_fin_sueno'] as String).split(':')[0]),
                minute: int.parse((row['hora_fin_sueno'] as String).split(':')[1]),
              )
            : null,
        horaInicioSueno: row['hora_inicio_sueno'] != null
            ? TimeOfDay(
                hour: int.parse((row['hora_inicio_sueno'] as String).split(':')[0]),
                minute: int.parse((row['hora_inicio_sueno'] as String).split(':')[1]),
              )
            : null,
      );

      // Consultar si Health Connect está disponible y lo seteo en el usuario
      await usuario.isHealthConnectAvailableUser();

      await usuario.getCurrentMrPoints();

      return usuario;
    } catch (e) {
      Logger().e('Error loading user: $e');
      rethrow;
    }
  }

  List<Map<String, String>> getTipoExperiencia() {
    return [
      {'title': 'Novato', 'desc': 'Sin rutina de entrenar.'},
      {'title': 'Aprendiz', 'desc': 'Actividad física esporádica y sin planificación.'},
      {'title': 'Intermedio', 'desc': 'Ejercita con cierta regularidad, 1-2 veces por semana.'},
      {'title': 'Competente', 'desc': 'Sigue una rutina establecida, combinando fuerza, cardio y flexibilidad.'},
      {'title': 'Avanzado', 'desc': 'Mantiene un alto nivel de exigencia física con sesiones diarias.'},
      {'title': 'Maestro', 'desc': 'Rendimiento de élite.'},
    ];
  }

  Future<Rutina> getCurrentRutina() async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.rawQuery('SELECT rutina_actual_id FROM auth_user WHERE id = ?', [1]);
    if (results.isEmpty) throw Exception('User not found');
    final idRutina = results.first["rutina_actual_id"] as int;

    final rutina = await Rutina.loadById(idRutina);
    if (rutina == null) {
      throw Exception('Rutina not found for id: $idRutina');
    }
    return rutina;
  }

  static double getDefaultWeight() {
    return 72;
  }

  Future<bool> setHoraInicioSueno(TimeOfDay time) async {
    horaInicioSueno = time;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update(
      'auth_user',
      {'hora_inicio_sueno': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'},
      where: 'id = ?',
      whereArgs: [1],
    );
    return count > 0;
  }

  Future<bool> setHoraFinSueno(TimeOfDay time) async {
    horaFinSueno = time;
    final db = await DatabaseHelper.instance.database;
    int count = await db.update(
      'auth_user',
      {'hora_fin_sueno': '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'},
      where: 'id = ?',
      whereArgs: [1],
    );
    return count > 0;
  }
}
