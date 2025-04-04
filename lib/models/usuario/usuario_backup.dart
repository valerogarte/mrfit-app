import 'package:logger/logger.dart';
import '../../data/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class UsuarioBackup {
  static Future<void> export() async {
    final logger = Logger(); // Added logger instance
    logger.i('Inicio de exportación'); // Debug: inicio

    // 1. Obtener la base de datos.
    logger.i('Obteniendo base de datos');
    final db = await DatabaseHelper.instance.database;
    logger.i('Base de datos obtenida');

    // 2. Recopilar datos de las tablas.
    // Modificado: Un solo INSERT INTO por tabla.
    final tables = [
      'auth_user',
      'auth_user_equipo_en_casa',
      'entrenamiento_ejerciciorealizado',
      'entrenamiento_entrenamiento',
      'entrenamiento_serierealizada',
      'rutinas_ejerciciopersonalizado',
      'rutinas_rutina',
      'rutinas_seriepersonalizada',
      'rutinas_sesion',
    ];
    final List<String> inserts = [];
    for (var table in tables) {
      logger.i('Exportando tabla: $table');
      final rows = await db.query(table);
      // Agrega TRUNCATE siempre, sin importar si hay filas o no.
      inserts.add("DELETE FROM $table;");
      inserts.add("DELETE FROM sqlite_sequence WHERE name='$table';");
      if (rows.isNotEmpty) {
        final columns = rows.first.keys.join(', ');
        final List<String> tuples = [];
        for (var row in rows) {
          final values = row.values
              .map((v) => v == null
                  ? 'NULL'
                  : v is String
                      ? "'$v'"
                      : '$v')
              .join(', ');
          tuples.add('($values)');
        }
        inserts.add("INSERT INTO $table ($columns) VALUES ${tuples.join(', ')};");
      }
    }
    final sqlScript = inserts.join('\n');
    logger.i('Script SQL generado');

    // 3. Tomar credenciales de sFTP y conectarse.
    logger.i('Recuperando credenciales SFTP');
    final prefs = await SharedPreferences.getInstance();
    final host = prefs.getString('ftp_host') ?? '';
    final port = int.tryParse(prefs.getString('ftp_port') ?? '22') ?? 22;
    final user = prefs.getString('ftp_user') ?? '';
    final pwd = prefs.getString('ftp_pwd') ?? '';
    logger.i('Credenciales recuperadas');

    // Recuperar remoteDirPath desde preferencias o usar valor por defecto.
    final remoteDirPath = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';

    // Generar nombre del archivo (YYYYmmdd-HHiiss-MrFit.sql)
    final now = DateTime.now();
    final fileName =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}-MrFit.sql';

    try {
      // 4. Subir el archivo .sql generado vía SFTP.
      logger.i('Conectando via SSH SFTP');
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();
      logger.i('Conexión SFTP establecida');

      // Added debug: imprimir el path remoto donde se buscan los ficheros
      logger.i('Buscando archivos en ruta: $remoteDirPath');

      // Listar archivos existentes y filtrar nombres "YYYYmmdd-MrFit.sql"
      final allFiles = await sftp.listdir(remoteDirPath);
      final backupFiles = allFiles.where((f) => RegExp(r'^\d{8}-MrFit\.sql$').hasMatch(f.filename)).toList();
      backupFiles.sort((a, b) => a.filename.compareTo(b.filename));
      logger.i('Archivos de backup listados: ${backupFiles.map((f) => f.filename).toList()}');

      // Borrar el más antiguo si hay 10 o más
      if (backupFiles.length >= 10) {
        final oldest = backupFiles.first;
        logger.i('Borrando backup mas antiguo: ${oldest.filename}');
        await sftp.remove(oldest.filename);
      }

      // Crear y escribir el nuevo archivo
      // Combine remoteDirPath and fileName into a full path.
      final remoteFilePath = '$remoteDirPath/$fileName';
      logger.i('Abriendo archivo remoto: $remoteFilePath');
      final remoteFile = await sftp.open(
        remoteFilePath,
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
      );
      logger.i('Archivo remoto abierto: $fileName');
      await remoteFile.write(Stream.value(utf8.encode(sqlScript)));
      await remoteFile.close();
      logger.i('Archivo escrito y cerrado');

      client.close();
      logger.i('Conexión SFTP cerrada');
    } catch (e, stackTrace) {
      logger.e('Error durante la exportación', error: e, stackTrace: stackTrace);
    }
  }

  // Nueva función para listar los archivos de respaldo disponibles desde SFTP
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
      final backupFiles = files.where((f) => RegExp(r'^\d{14}-MrFit\.sql$').hasMatch(f.filename)).toList();
      backupFiles.sort((a, b) => b.filename.compareTo(a.filename));

      client.close();
      return backupFiles.map((f) => f.filename).toList();
    } catch (e) {
      Logger().e('Error listando archivos SFTP', error: e);
      return [];
    }
  }

  // Nueva función para importar el respaldo desde un archivo seleccionado
  static Future<void> importSelectedBackup(BuildContext context, String selectedFile) async {
    final logger = Logger();
    logger.i('Importación desde archivo: $selectedFile');
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
      final contentBytes = rawChunks.expand((x) => x).toList();
      await remoteFile.close();
      final sqlScript = utf8.decode(contentBytes);
      logger.i('Archivo leído: $selectedFile');

      // Ejecutar cada sentencia SQL en la base de datos local
      final db = await DatabaseHelper.instance.database;
      final commands = sqlScript.split(';');
      for (var command in commands) {
        final cmd = command.trim();
        if (cmd.isNotEmpty) {
          await db.execute(cmd);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Importación completada.')));
      client.close();
    } catch (e, stackTrace) {
      Logger().e('Error durante la importación', error: e, stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error durante la importación.')));
    }
  }
}
