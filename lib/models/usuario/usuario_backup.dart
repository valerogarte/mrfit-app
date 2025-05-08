import 'package:logger/logger.dart';
import 'package:mrfit/data/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class UsuarioBackup {
  static Future<void> export() async {
    final logger = Logger();
    logger.i('Inicio de exportación');

    // 1. Obtener la base de datos.
    logger.i('Obteniendo base de datos');
    final db = await DatabaseHelper.instance.database;
    logger.i('Base de datos obtenida');

    // 2. Tablas a procesar.
    final tables = [
      'auth_user',
      'accounts_historiallesiones',
      'accounts_volumenmaximo',
      'auth_user_equipo_en_casa',
      'custom_cache_cacheentry',
      'entrenamiento_entrenamiento',
      'entrenamiento_ejerciciorealizado',
      'entrenamiento_serierealizada',
      'nutricion_diferenciacalorica',
      // Rutinas Personalizadas
      'rutinas_rutina',
      'rutinas_sesion',
      'rutinas_ejerciciopersonalizado',
      'rutinas_seriepersonalizada',
    ];

    final List<String> sqlToExecute = [];
    final List<int> rutinaIds = [];
    final List<int> sesionIds = [];
    final List<int> ejercicioPersIds = [];

    for (var table in tables) {
      logger.i('Procesando tabla: $table');
      List<Map<String, dynamic>> rows = [];

      if (table == 'rutinas_rutina') {
        rows = await db.query(
          table,
          where: 'grupo_id IN (?, ?)',
          whereArgs: [1, 2],
        );
        rutinaIds.addAll(rows.map((r) => r['id'] as int));
        sqlToExecute.add("DELETE FROM $table WHERE grupo_id IN (1, 2);");
      } else if (table == 'rutinas_sesion') {
        if (rutinaIds.isNotEmpty) {
          final ph = List.filled(rutinaIds.length, '?').join(',');
          rows = await db.query(
            table,
            where: 'rutina_id IN ($ph)',
            whereArgs: rutinaIds,
          );
          sesionIds.addAll(rows.map((r) => r['id'] as int));
          final idList = rutinaIds.join(',');
          sqlToExecute.add("DELETE FROM $table WHERE rutina_id IN ($idList);");
        }
      } else if (table == 'rutinas_ejerciciopersonalizado') {
        if (sesionIds.isNotEmpty) {
          final ph = List.filled(sesionIds.length, '?').join(',');
          rows = await db.query(
            table,
            where: 'sesion_id IN ($ph)',
            whereArgs: sesionIds,
          );
          ejercicioPersIds.addAll(rows.map((r) => r['id'] as int));
          final idList = sesionIds.join(',');
          sqlToExecute.add("DELETE FROM $table WHERE sesion_id IN ($idList);");
        }
      } else if (table == 'rutinas_seriepersonalizada') {
        if (ejercicioPersIds.isNotEmpty) {
          final ph = List.filled(ejercicioPersIds.length, '?').join(',');
          rows = await db.query(
            table,
            where: 'ejercicio_personalizado_id IN ($ph)',
            whereArgs: ejercicioPersIds,
          );
          final idList = ejercicioPersIds.join(',');
          sqlToExecute.add("DELETE FROM $table WHERE ejercicio_personalizado_id IN ($idList);");
        }
      } else {
        rows = await db.query(table);
        sqlToExecute.add("DELETE FROM $table;");
      }

      // Reset de secuencia
      sqlToExecute.add("DELETE FROM sqlite_sequence WHERE name='$table';");

      if (rows.isNotEmpty) {
        final columns = rows.first.keys.join(', ');
        final List<String> tuples = [];
        for (var row in rows) {
          final values = row.values
              .map((v) => v == null
                  ? 'NULL'
                  : v is String
                      ? "'${v.replaceAll("'", "''")}'"
                      : '$v')
              .join(', ');
          tuples.add('($values)');
        }
        sqlToExecute.add(
          "INSERT INTO $table ($columns) VALUES ${tuples.join(', ')};",
        );
      }
    }

    final sqlScript = sqlToExecute.join('\n');
    logger.i('Script SQL generado');

    // 3. Conexión SFTP y subida
    logger.i('Recuperando credenciales SFTP');
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ftp_host') ?? '';
    final port = int.tryParse(prefs.getString('ftp_port') ?? '22') ?? 22;
    final user = prefs.getString('ftp_user') ?? '';
    final pwd = prefs.getString('ftp_pwd') ?? '';
    final remoteDirPath = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';
    logger.i('Credenciales recuperadas');

    final now = DateTime.now();
    final fileName = '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}-MrFit.sql';

    try {
      logger.i('Conectando via SSH SFTP');
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();
      logger.i('Conexión SFTP establecida');

      logger.i('Listando backups en: $remoteDirPath');
      final allFiles = await sftp.listdir(remoteDirPath);
      final backupFiles = allFiles.where((f) => RegExp(r'^\d{14}-MrFit\.sql$').hasMatch(f.filename)).toList()..sort((a, b) => a.filename.compareTo(b.filename));
      if (backupFiles.length >= 10) {
        final oldest = backupFiles.first;
        logger.i('Borrando backup más antiguo: ${oldest.filename}');
        await sftp.remove('$remoteDirPath/${oldest.filename}');
      }

      final remoteFilePath = '$remoteDirPath/$fileName';
      logger.i('Subiendo $fileName');
      final remoteFile = await sftp.open(
        remoteFilePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      await remoteFile.write(Stream.value(utf8.encode(sqlScript)));
      await remoteFile.close();
      client.close();
      logger.i('Exportación completada');
    } catch (e, stack) {
      logger.e('Error durante la exportación', error: e, stackTrace: stack);
    }
  }

  static Future<List<String>> listBackupFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ftp_host') ?? '';
    final port = int.tryParse(prefs.getString('ftp_port') ?? '22') ?? 22;
    final user = prefs.getString('ftp_user') ?? '';
    final pwd = prefs.getString('ftp_pwd') ?? '';
    final remoteDirPath = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';

    try {
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();

      final files = await sftp.listdir(remoteDirPath);
      final backupFiles = files.where((f) => RegExp(r'^\d{14}-MrFit\.sql$').hasMatch(f.filename)).toList()..sort((a, b) => b.filename.compareTo(a.filename));

      client.close();
      return backupFiles.map((f) => f.filename).toList();
    } catch (e) {
      Logger().e('Error listando archivos SFTP', error: e);
      return [];
    }
  }

  static Future<void> importSelectedBackup(BuildContext context, String selectedFile) async {
    final logger = Logger();
    logger.i('Importando desde: $selectedFile');
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ftp_host') ?? '';
    final port = int.tryParse(prefs.getString('ftp_port') ?? '22') ?? 22;
    final user = prefs.getString('ftp_user') ?? '';
    final pwd = prefs.getString('ftp_pwd') ?? '';
    final remoteDirPath = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';

    try {
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();

      final remoteFilePath = '$remoteDirPath/$selectedFile';
      final remoteFile = await sftp.open(
        remoteFilePath,
        mode: SftpFileOpenMode.read,
      );
      final rawChunks = await remoteFile.read().toList();
      await remoteFile.close();
      final sqlScript = utf8.decode(rawChunks.expand((x) => x).toList());
      logger.i('Archivo leído correctamente');

      final db = await DatabaseHelper.instance.database;
      for (var cmd in sqlScript.split(';')) {
        final sql = cmd.trim();
        if (sql.isNotEmpty) await db.execute(sql);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importación completada.')),
      );
      client.close();
    } catch (e, stack) {
      logger.e('Error durante la importación', error: e, stackTrace: stack);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error durante la importación.')),
      );
    }
  }

  static Future<bool> deleteBackupFile(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ftp_host') ?? '';
    final port = int.tryParse(prefs.getString('ftp_port') ?? '22') ?? 22;
    final user = prefs.getString('ftp_user') ?? '';
    final pwd = prefs.getString('ftp_pwd') ?? '';
    final remoteDirPath = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';

    try {
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();
      await sftp.remove('$remoteDirPath/$fileName');
      client.close();
      return true;
    } catch (e) {
      Logger().e('Error borrando $fileName', error: e);
      return false;
    }
  }
}
