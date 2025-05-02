import 'dart:io';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mrfit/utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  String getDatabaseName() {
    return 'mrfit.db';
  }

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final newVersion = int.parse(AppConstants.version.replaceAll('.', ''));
    final fileName = getDatabaseName();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    // Verifica la versión actual
    int currentUserVersion = await _getDatabaseVersion(path);
    if (currentUserVersion < newVersion) {
      Logger().w("Versión antigua detectada, eliminando base de datos antigua...");
      // Elimina el archivo completo para forzar la actualización
      if (await File(path).exists()) {
        await File(path).delete();
        Logger().i("Archivo de base de datos eliminado.");
      }
      await _copyDatabaseFromAssets(path);
    }

    return await openDatabase(
      path,
      version: newVersion,
      onCreate: (db, version) async {
        Logger().i("Creando nueva base de datos desde $path...");
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Opcional: manejar migraciones si es necesario
        Logger().i("Ejecutando migración de la base de datos de $oldVersion a $newVersion...");
      },
    );
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    try {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load('assets/${getDatabaseName()}');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      Logger().i("Base de datos restaurada desde assets.");
    } catch (e) {
      Logger().e("Error al copiar la base de datos desde assets: $e");
      rethrow;
    }
  }

  Future<int> _getDatabaseVersion(String path) async {
    try {
      Database db = await openDatabase(path);
      List<Map<String, dynamic>> result = await db.rawQuery('PRAGMA user_version;');
      int version = result.first['user_version'] as int? ?? 0;
      await db.close();
      return version;
    } catch (e) {
      Logger().e("Error obteniendo la versión de la base de datos: $e");
      return 0;
    }
  }
}
