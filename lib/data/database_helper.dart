import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:mrfit/utils/mr_functions.dart';
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
    final newVersion = MrFunctions.versionToInt(AppConstants.version);
    final fileName = getDatabaseName();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    if (!await File(path).exists()) {
      await _copyDatabaseFromAssets(path);
    } else {
      // int currentUserVersion = await _getDatabaseVersion(path);
      // print("----------------------");
      // print(currentUserVersion);
      // print(newVersion);
      // if (currentUserVersion < newVersion) {
      //   Logger().w("Versión antigua ($currentUserVersion) detectada, eliminando base de datos antigua...");
      //   if (await File(path).exists()) {
      //     await File(path).delete();
      //     Logger().i("Archivo de base de datos eliminado.");
      //   }
      //   await _copyDatabaseFromAssets(path);
      // }
    }

    return await openDatabase(
      path,
      version: newVersion,
      onCreate: (db, version) async {
        Logger().i("Creando nueva base de datos versión $newVersion desde $path...");
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        Logger().i("Ejecutando migración de la base de datos de $oldVersion a $newVersion...");
      },
    );
  }

  /// Copia la base de datos desde assets si no existe.
  Future<void> _copyDatabaseFromAssets(String path) async {
    try {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load('assets/${getDatabaseName()}');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      Logger().i("Base de datos restaurada desde assets.");

      // Establece la versión de usuario después de copiar la base de datos.
      final newVersion = MrFunctions.versionToInt(AppConstants.version);
      final db = await openDatabase(path);
      try {
        await db.execute('PRAGMA user_version = $newVersion;');
        Logger().i("Versión de base de datos establecida a $newVersion tras restaurar desde assets.");
      } catch (e) {
        Logger().e("Error al establecer la versión de la base de datos: $e");
      } finally {
        await db.close();
      }
    } catch (e) {
      Logger().e("Error al copiar la base de datos desde assets: $e");
      rethrow;
    }
  }

  // Future<int> _getDatabaseVersion(String path) async {
  //   Database localDb = await openDatabase(path);
  //   try {
  //     List<Map<String, dynamic>> result = await localDb.rawQuery('PRAGMA user_version;');
  //     int version = result.first['user_version'] as int? ?? 0;
  //     return MrFunctions.versionToInt(version.toString());
  //   } catch (e) {
  //     Logger().e("Error obteniendo la versión de la base de datos: $e");
  //     return 0;
  //   } finally {
  //     await localDb.close();
  //   }
  // }
}
