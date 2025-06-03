import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:mrfit/data/database_helper.dart';
import 'dart:convert';

class UsuarioBackup {
  static Future<void> exportar() async {
    final logger = Logger();
    logger.i('Inicio de exportación');

    final db = await DatabaseHelper.instance.database;
    logger.i('Base de datos lista');

    final tablas = <String>[
      'auth_user',
      'accounts_historiallesiones',
      'accounts_volumenmaximo',
      'auth_user_equipo_en_casa',
      'custom_cache_cacheentry',
      'entrenamiento_entrenamiento',
      'entrenamiento_ejerciciorealizado',
      'entrenamiento_serierealizada',
      'nutricion_diferenciacalorica',
      'rutinas_rutina',
      'rutinas_sesion',
      'rutinas_ejerciciopersonalizado',
      'rutinas_seriepersonalizada',
    ];

    final sqls = <String>[];
    final rutinaIds = <int>[];
    final sesionIds = <int>[];
    final ejercPersIds = <int>[];

    for (var tabla in tablas) {
      List<Map<String, dynamic>> filas = [];
      switch (tabla) {
        case 'rutinas_rutina':
          filas = await db.query(tabla, where: 'grupo_id IN (?, ?)', whereArgs: [1, 2]);
          rutinaIds.addAll(filas.map((r) => r['id'] as int));
          sqls.add("DELETE FROM \"$tabla\" WHERE grupo_id IN (1, 2);");
          break;
        case 'rutinas_sesion':
          if (rutinaIds.isNotEmpty) {
            final ph = List.filled(rutinaIds.length, '?').join(',');
            filas = await db.query(tabla, where: 'rutina_id IN ($ph)', whereArgs: rutinaIds);
            sesionIds.addAll(filas.map((r) => r['id'] as int));
            sqls.add("DELETE FROM \"$tabla\" WHERE rutina_id IN (${rutinaIds.join(',')});");
          }
          break;
        case 'rutinas_ejerciciopersonalizado':
          if (sesionIds.isNotEmpty) {
            final ph = List.filled(sesionIds.length, '?').join(',');
            filas = await db.query(tabla, where: 'sesion_id IN ($ph)', whereArgs: sesionIds);
            ejercPersIds.addAll(filas.map((r) => r['id'] as int));
            sqls.add("DELETE FROM \"$tabla\" WHERE sesion_id IN (${sesionIds.join(',')});");
          }
          break;
        case 'rutinas_seriepersonalizada':
          if (ejercPersIds.isNotEmpty) {
            final ph = List.filled(ejercPersIds.length, '?').join(',');
            filas = await db.query(tabla, where: 'ejercicio_personalizado_id IN ($ph)', whereArgs: ejercPersIds);
            sqls.add("DELETE FROM \"$tabla\" WHERE ejercicio_personalizado_id IN (${ejercPersIds.join(',')});");
          }
          break;
        default:
          filas = await db.query(tabla);
          sqls.add("DELETE FROM \"$tabla\";");
      }

      sqls.add("DELETE FROM sqlite_sequence WHERE name='$tabla';");

      if (filas.isNotEmpty) {
        final columnas = filas.first.keys.join(', ');
        final valores = filas.map((fila) {
          final v = fila.values.map((valor) {
            if (valor == null) return 'NULL';
            if (valor is String) return "'${valor.replaceAll("'", "''")}'";
            return valor.toString();
          }).join(', ');
          return '($v)';
        }).join(', ');
        sqls.add("INSERT INTO $tabla ($columnas) VALUES $valores;");
      }
    }

    sqls.insertAll(0, ['PRAGMA foreign_keys=OFF;', 'BEGIN TRANSACTION;']);
    sqls.addAll(['COMMIT;', 'PRAGMA foreign_keys=ON;']);

    final script = sqls.join('\n');
    logger.i('Script SQL generado');

    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ftp_host') ?? '';
    final port = int.tryParse(prefs.getString('ftp_port') ?? '22') ?? 22;
    final user = prefs.getString('ftp_user') ?? '';
    final pwd = prefs.getString('ftp_pwd') ?? '';
    final remoteDir = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';

    final ahora = DateTime.now();
    final fileName =
        '${ahora.year.toString().padLeft(4, '0')}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}${ahora.hour.toString().padLeft(2, '0')}${ahora.minute.toString().padLeft(2, '0')}${ahora.second.toString().padLeft(2, '0')}-MrFit.sql';

    try {
      logger.i('Conectando SFTP');
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();

      final archivos = await sftp.listdir(remoteDir);
      final backups = archivos.where((f) => RegExp(r'^\d{14}-MrFit\.sql$').hasMatch(f.filename)).toList()..sort((a, b) => a.filename.compareTo(b.filename));

      if (backups.length >= 10) {
        final antiguo = backups.first;
        logger.i('Borrando backup más antiguo: ${antiguo.filename}');
        await sftp.remove('$remoteDir/${antiguo.filename}');
      }

      final rutaRemota = '$remoteDir/$fileName';
      logger.i('Subiendo $fileName');
      final remoto = await sftp.open(
        rutaRemota,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      await remoto.write(Stream.value(utf8.encode(script)));
      await remoto.close();
      client.close();
      logger.i('Exportación completada');
    } catch (e, s) {
      logger.e('Error exportación', error: e, stackTrace: s);
      rethrow;
    }
  }

  static Future<List<String>> listarBackups() async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ftp_host') ?? '';
    final port = int.tryParse(prefs.getString('ftp_port') ?? '22') ?? 22;
    final user = prefs.getString('ftp_user') ?? '';
    final pwd = prefs.getString('ftp_pwd') ?? '';
    final remoteDir = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';

    try {
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();

      final archivos = await sftp.listdir(remoteDir);
      final backups = archivos.where((f) => RegExp(r'^\d{14}-MrFit\.sql$').hasMatch(f.filename)).toList()..sort((a, b) => b.filename.compareTo(a.filename));

      client.close();
      return backups.map((f) => f.filename).toList();
    } catch (e) {
      Logger().e('Error listando backups: $e');
      return [];
    }
  }

  static Future<bool> borrarBackup(String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ftp_host') ?? '';
    final port = int.tryParse(prefs.getString('ftp_port') ?? '22') ?? 22;
    final user = prefs.getString('ftp_user') ?? '';
    final pwd = prefs.getString('ftp_pwd') ?? '';
    final remoteDir = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';

    try {
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();
      await sftp.remove('$remoteDir/$fileName');
      client.close();
      return true;
    } catch (e) {
      Logger().e('Error borrando $fileName: $e');
      return false;
    }
  }

  /// Devuelve `true` si pudo importar, `false` si hubo error.
  static Future<bool> importarBackupSeleccionado(BuildContext context, String seleccionado) async {
    final logger = Logger();
    logger.i('💡 Importando $seleccionado');

    try {
      final prefs = await SharedPreferences.getInstance();
      final host = prefs.getString('ftp_host') ?? '';
      final port = int.tryParse(prefs.getString('ftp_port') ?? '22') ?? 22;
      final user = prefs.getString('ftp_user') ?? '';
      final pwd = prefs.getString('ftp_pwd') ?? '';
      final remoteDir = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';

      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();

      final rutaRemota = '$remoteDir/$seleccionado';
      final remoto = await sftp.open(rutaRemota, mode: SftpFileOpenMode.read);
      final chunks = await remoto.read().toList();
      await remoto.close();
      final script = utf8.decode(chunks.expand((x) => x).toList());
      logger.i('💡 Archivo leído');

      final db = await DatabaseHelper.instance.database;
      for (var sql in script.split(';')) {
        final cmd = sql.trim();
        if (cmd.isNotEmpty) {
          await db.execute(cmd);
        }
      }

      client.close();
      return true;
    } catch (e, s) {
      logger.e('⛔ Error importación', error: e, stackTrace: s);
      return false;
    }
  }
}
