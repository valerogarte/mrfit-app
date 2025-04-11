// usuario.dart

import 'package:flutter/material.dart';

import '../ejercicio/ejercicio.dart';
import '../../data/database_helper.dart';
import 'usuario_backup.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../rutina/rutina.dart';
import '../../models/entrenamiento/entrenamiento.dart';

part 'usuario_health.dart';
part 'usuario_google.dart';
part 'usuario_query.dart';
part 'usuario_mrpoints.dart';

class Usuario {
  final int id;
  final String username;
  final bool isStaff;
  final bool isActive;
  final DateTime dateJoined;
  final DateTime? lastLogin;
  Map<String, double> volumenMaximo;
  int objetivoPasosDiarios;
  int objetivoEntrenamientoSemanal;
  DateTime fechaNacimiento;
  String genero;
  List<dynamic> historialPesos;
  List<dynamic> historiaLesiones;
  List<Equipamiento> equipoEnCasa;
  String experiencia;
  String unidades;
  String sonido;
  int tiempoDescanso;
  double weight;
  Map<String, double>? _cachedMrPoints;
  final Health _health = Health();

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
    required this.fechaNacimiento,
    required this.genero,
    required this.historialPesos,
    required this.historiaLesiones,
    required this.equipoEnCasa,
    required this.experiencia,
    required this.unidades,
    required this.sonido,
    required this.tiempoDescanso,
    this.weight = 0.0,
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
      objetivoEntrenamientoSemanal: json['objetivo_entrenamiento_semanal'] ?? 0,
      fechaNacimiento: DateTime.parse(json['fecha_nacimiento']),
      genero: json['genero'] ?? '',
      historialPesos: json['historial_pesos'] ?? [],
      historiaLesiones: json['historia_lesiones'] ?? [],
      equipoEnCasa: (json['equipo_en_casa'] as List?)?.map((e) => Equipamiento.fromJson(e)).toList() ?? [],
      experiencia: json['experiencia'] ?? '',
      unidades: json['unidades'] ?? '',
      sonido: json['sonido'] ?? '',
      tiempoDescanso: json['tiempo_descanso'] ?? 0,
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
      'fecha_nacimiento': fechaNacimiento.toIso8601String(),
      'genero': genero,
      'historial_pesos': historialPesos,
      'historia_lesiones': historiaLesiones,
      'equipo_en_casa': equipoEnCasa.map((e) => e.toJson()).toList(),
      'experiencia': experiencia,
      'unidades': unidades,
      'sonido': sonido,
      'tiempo_descanso': tiempoDescanso,
    };
  }

  // Métodos set para actualizar campos en la tabla auth_user

  Future<bool> setUsername(String username) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'username': username}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setIsStaff(bool isStaff) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'is_staff': isStaff ? 1 : 0}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setIsActive(bool isActive) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'is_active': isActive ? 1 : 0}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setDateJoined(DateTime dateJoined) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'date_joined': dateJoined.toIso8601String()}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setLastLogin(DateTime? lastLogin) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'last_login': lastLogin?.toIso8601String()}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setExperiencia(String experiencia) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'experiencia': experiencia}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setFechaNacimiento(DateTime fechaNacimiento) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'fecha_nacimiento': fechaNacimiento.toIso8601String()}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setGenero(String genero) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'genero': genero}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setHistorialPesos(List<dynamic> historialPesos) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'historial_pesos': historialPesos}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setHistoriaLesiones(List<dynamic> historiaLesiones) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'historia_lesiones': historiaLesiones}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setObjetivoEntrenamientoSemanal(int objetivoEntrenamientoSemanal) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'objetivo_entrenamiento_semanal': objetivoEntrenamientoSemanal}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setObjetivoPasosDiarios(int objetivoPasosDiarios) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'objetivo_pasos_diarios': objetivoPasosDiarios}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setSonido(String sonido) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'sonido': sonido}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setTiempoDescanso(int tiempoDescanso) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'tiempo_descanso': tiempoDescanso}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  Future<bool> setUnidades(String unidades) async {
    final db = await DatabaseHelper.instance.database;
    int count = await db.update('auth_user', {'unidades': unidades}, where: 'id = ?', whereArgs: [1]);
    return count > 0;
  }

  static Future<Usuario> load() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.rawQuery('SELECT * FROM auth_user WHERE id = ?', [1]);
      if (results.isEmpty) throw Exception('User not found');
      final row = results.first;
      final historialPesos = row['historial_pesos'] is String ? jsonDecode(row['historial_pesos'].toString()) : (row['historial_pesos'] ?? []);
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
        fechaNacimiento: row['fecha_nacimiento'] != null ? DateTime.parse(row['fecha_nacimiento'].toString()) : DateTime.now().subtract(const Duration(days: 365 * 30)),
        genero: row['genero']?.toString() ?? '',
        historialPesos: historialPesos,
        historiaLesiones: historiaLesiones,
        equipoEnCasa: [], // default empty list
        experiencia: row['experiencia']?.toString() ?? '',
        unidades: row['unidades']?.toString() ?? '',
        sonido: row['sonido']?.toString() ?? '',
        tiempoDescanso: row['tiempo_descanso'] is int ? row['tiempo_descanso'] as int : (int.tryParse(row['tiempo_descanso']?.toString() ?? '') ?? 0),
      );

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

  int getTargetSteps() {
    return 7500;
  }

  int getTargetMinActividad() {
    return 60;
  }

  int getTargetKcalBurned() {
    return 2500;
  }

  int getTargetSleepMinutes() {
    return 480;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      "https://www.googleapis.com/auth/fitness.activity.read",
      "https://www.googleapis.com/auth/fitness.activity.write",
      "https://www.googleapis.com/auth/fitness.blood_glucose.read",
      "https://www.googleapis.com/auth/fitness.blood_glucose.write",
      "https://www.googleapis.com/auth/fitness.blood_pressure.read",
      "https://www.googleapis.com/auth/fitness.blood_pressure.write",
      "https://www.googleapis.com/auth/fitness.body.read",
      "https://www.googleapis.com/auth/fitness.body.write",
      "https://www.googleapis.com/auth/fitness.body_temperature.read",
      "https://www.googleapis.com/auth/fitness.body_temperature.write",
      "https://www.googleapis.com/auth/fitness.heart_rate.read",
      "https://www.googleapis.com/auth/fitness.heart_rate.write",
      "https://www.googleapis.com/auth/fitness.location.read",
      "https://www.googleapis.com/auth/fitness.location.write",
      "https://www.googleapis.com/auth/fitness.nutrition.read",
      "https://www.googleapis.com/auth/fitness.nutrition.write",
      "https://www.googleapis.com/auth/fitness.oxygen_saturation.read",
      "https://www.googleapis.com/auth/fitness.oxygen_saturation.write",
      "https://www.googleapis.com/auth/fitness.reproductive_health.read",
      "https://www.googleapis.com/auth/fitness.reproductive_health.write",
      "https://www.googleapis.com/auth/fitness.sleep.read",
      "https://www.googleapis.com/auth/fitness.sleep.write"
    ],
  );
}
