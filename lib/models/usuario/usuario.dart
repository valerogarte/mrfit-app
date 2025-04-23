import 'package:mrfit/models/modelo_datos.dart';
import 'dart:io' show Platform;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'usuario_backup.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart';

import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/data/database_helper.dart';
import 'package:mrfit/models/rutina/rutina.dart';
import 'package:mrfit/models/entrenamiento/entrenamiento.dart';
import 'package:mrfit/utils/usage_stats_helper.dart';

part 'usuario_health.dart';
part 'usuario_google.dart';
part 'usuario_query.dart';
part 'usuario_mrpoints.dart';
part 'usuario_health/usuario_health_activity.dart';
part 'usuario_health/usuario_health_corporal.dart';
part 'usuario_health/usuario_health_sleep.dart';
part 'usuario_health/usuario_health_nutrition.dart';

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
  List<dynamic> historiaLesiones;
  List<Equipamiento> equipoEnCasa;
  String experiencia;
  String unidades;
  String sonido;
  int tiempoDescanso;
  double weight;
  int? rutinaActualId;
  Map<String, double>? _cachedMrPoints;
  final Health _health = Health();

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
    required this.fechaNacimiento,
    required this.genero,
    required this.historiaLesiones,
    required this.equipoEnCasa,
    required this.experiencia,
    required this.unidades,
    required this.sonido,
    required this.tiempoDescanso,
    this.weight = 0.0,
    this.rutinaActualId, // Incluir el nuevo campo en el constructor
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
      historiaLesiones: json['historia_lesiones'] ?? [],
      equipoEnCasa: (json['equipo_en_casa'] as List?)?.map((e) => Equipamiento.fromJson(e)).toList() ?? [],
      experiencia: json['experiencia'] ?? '',
      unidades: json['unidades'] ?? '',
      sonido: json['sonido'] ?? '',
      tiempoDescanso: json['tiempo_descanso'] ?? 0,
      rutinaActualId: json['rutina_actual_id'], // Mapear el nuevo campo
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
      'historia_lesiones': historiaLesiones,
      'equipo_en_casa': equipoEnCasa.map((e) => e.toJson()).toList(),
      'experiencia': experiencia,
      'unidades': unidades,
      'sonido': sonido,
      'tiempo_descanso': tiempoDescanso,
      'rutina_actual_id': rutinaActualId, // Incluir el nuevo campo en el JSON
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

  // Método para establecer la rutina actual
  Future<bool> setRutinaActual(int? rutinaId) async {
    try {
      final db = await DatabaseHelper.instance.database;
      int count = await db.update('auth_user', {'rutina_actual_id': rutinaId}, where: 'id = ?', whereArgs: [1]);

      if (count > 0) {
        this.rutinaActualId = rutinaId;
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
        fechaNacimiento: row['fecha_nacimiento'] != null ? DateTime.parse(row['fecha_nacimiento'].toString()) : DateTime.now().subtract(const Duration(days: 365 * 30)),
        genero: row['genero']?.toString() ?? '',
        historiaLesiones: historiaLesiones,
        equipoEnCasa: [], // default empty list
        experiencia: row['experiencia']?.toString() ?? '',
        unidades: row['unidades']?.toString() ?? '',
        sonido: row['sonido']?.toString() ?? '',
        tiempoDescanso: row['tiempo_descanso'] is int ? row['tiempo_descanso'] as int : (int.tryParse(row['tiempo_descanso']?.toString() ?? '') ?? 0),
        rutinaActualId: row['rutina_actual_id'] is int ? row['rutina_actual_id'] as int : (int.tryParse(row['rutina_actual_id']?.toString() ?? '') ?? null), // Cargar rutina_actual_id
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

  int getTargetSteps() {
    return 7500;
  }

  int getTargetMinActividad() {
    return 75;
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
