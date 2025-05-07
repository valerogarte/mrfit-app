import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:convert';
import 'package:mrfit/models/usuario/usuario_backup.dart';

class ConfiguracionApp {
  static Future<void> openFTPConfig(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    final hostController = TextEditingController();
    final portController = TextEditingController();
    final userController = TextEditingController();
    final pwdController = TextEditingController();
    final remoteDirController = TextEditingController();

    final List<String> frequencyOptions = ['Cada 12 horas', 'Diaria', 'Días Alternos', 'Semanal'];
    String selectedFrequency = frequencyOptions[0];

    final prefs = await SharedPreferences.getInstance();
    hostController.text = prefs.getString('ftp_host') ?? '';
    portController.text = prefs.getString('ftp_port') ?? '';
    userController.text = prefs.getString('ftp_user') ?? '';
    pwdController.text = prefs.getString('ftp_pwd') ?? '';
    selectedFrequency = prefs.getString('ftp_frequency') ?? frequencyOptions[0];
    if (!frequencyOptions.contains(selectedFrequency)) {
      selectedFrequency = frequencyOptions[0];
    }
    remoteDirController.text = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        bool doingTestConexion = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: AppColors.cardBackground,
              resizeToAvoidBottomInset: false,
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    top: 16,
                    left: 16,
                    right: 16,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 30),
                        Text(
                          'Respaldo sFTP',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textNormal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: hostController,
                          decoration: const InputDecoration(labelText: 'Host'),
                          validator: (v) => v == null || v.isEmpty ? 'Ingrese el host' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: portController,
                          decoration: const InputDecoration(labelText: 'Port'),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Ingrese el puerto' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: userController,
                          decoration: const InputDecoration(labelText: 'User'),
                          validator: (v) => v == null || v.isEmpty ? 'Ingrese el usuario' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: pwdController,
                          decoration: const InputDecoration(labelText: 'Password'),
                          obscureText: true,
                          validator: (v) => v == null || v.isEmpty ? 'Ingrese la contraseña' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: remoteDirController,
                          decoration: const InputDecoration(labelText: 'Directorio Remoto'),
                          validator: (v) => v == null || v.isEmpty ? 'Ingrese el directorio remoto' : null,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.background),
                          onPressed: doingTestConexion
                              ? null
                              : () async {
                                  setState(() => doingTestConexion = true);
                                  await ConfiguracionApp.testSFTPConnectivity(
                                    sheetContext,
                                    host: hostController.text,
                                    port: portController.text,
                                    user: userController.text,
                                    pwd: pwdController.text,
                                  );
                                  setState(() => doingTestConexion = false);
                                },
                          child: doingTestConexion
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textNormal,
                                  ),
                                )
                              : const Text('Test de conectividad'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              await UsuarioBackup.export();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Exportación realizada.')),
                              );
                            } catch (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error durante la exportación.')),
                              );
                            }
                          },
                          child: const Text('Exportar ahora'),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    await prefs.setString('ftp_host', hostController.text.trim());
                                    await prefs.setString('ftp_port', portController.text.trim());
                                    await prefs.setString('ftp_user', userController.text.trim());
                                    await prefs.setString('ftp_pwd', pwdController.text.trim());
                                    await prefs.setString('ftp_frequency', selectedFrequency);
                                    await prefs.setString('sftp_remoteDirPath', remoteDirController.text.trim());
                                    Navigator.pop(sheetContext);
                                  }
                                },
                                child: const Text('Guardar'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> testSFTPConnectivity(
    BuildContext context, {
    required String host,
    required String port,
    required String user,
    required String pwd,
  }) async {
    if (host.isEmpty || port.isEmpty || user.isEmpty || pwd.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, complete todos los campos antes de testear.')),
        );
      });
      return;
    }
    try {
      final socket = await SSHSocket.connect(host, int.parse(port));
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();
      final prefs = await SharedPreferences.getInstance();
      final remoteDirPath = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';
      final testPath = '$remoteDirPath/write_test.txt';
      try {
        final f = await sftp.open(
          testPath,
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
        );
        await f.write(Stream.value(utf8.encode('test')));
        await f.close();
        await sftp.remove(testPath);
      } catch (e) {
        client.close();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString().contains('No such file') ? 'La carpeta remota no existe.' : 'Sin permisos de escritura sobre la carpeta remota.',
              ),
            ),
          );
        });
        return;
      }
      final res = await client.run('echo connected');
      final ok = utf8.decode(res).trim() == 'connected';
      client.close();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Conexión exitosa.' : 'Error de conexión.')),
        );
      });
    } catch (e) {
      Logger().e('Test connectivity error: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión.')),
        );
      });
    }
  }

  static Future<void> selectFileFromServer(BuildContext context) async {
    // Loader inicial
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.accentColor)),
            const SizedBox(height: 10),
            Text("Cargando archivos de respaldo...", style: TextStyle(color: AppColors.textNormal)),
          ],
        ),
      ),
    );

    final backupFiles = await UsuarioBackup.listBackupFiles();
    Navigator.pop(context);

    if (backupFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron archivos de respaldo.')),
      );
      return;
    }

    final deleting = <String, bool>{};

    final selectedFile = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return SimpleDialog(
            backgroundColor: AppColors.cardBackground,
            title: Text('Archivos de respaldo', style: TextStyle(color: AppColors.textNormal)),
            children: backupFiles.map((fileName) {
              final isDeleting = deleting[fileName] == true;
              return ListTile(
                title: Text(fileName, style: TextStyle(color: AppColors.textNormal)),
                trailing: isDeleting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.accentColor),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete, color: AppColors.mutedRed),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: AppColors.cardBackground,
                                  title: Text('Confirmar borrado', style: TextStyle(color: AppColors.textNormal)),
                                  content: Text('¿Borrar $fileName?', style: TextStyle(color: AppColors.textNormal)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedRed),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text('Borrar'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm != true) return;
                              setState(() => deleting[fileName] = true);
                              final ok = await UsuarioBackup.deleteBackupFile(fileName);
                              setState(() => deleting[fileName] = false);
                              if (ok) {
                                setState(() => backupFiles.remove(fileName));
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: AppColors.cardBackground,
                                    title: Text('Error', style: TextStyle(color: AppColors.textNormal)),
                                    content: Text('No se pudo borrar $fileName', style: TextStyle(color: AppColors.textNormal)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context), child: Text('Ok')),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.upload_file, color: AppColors.accentColor),
                            onPressed: () => Navigator.pop(context, fileName),
                          ),
                        ],
                      ),
              );
            }).toList(),
          );
        },
      ),
    );

    if (selectedFile == null) return;

    // Confirmar importación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Confirmación', style: TextStyle(color: AppColors.textNormal)),
        content: Text('¿Estás seguro de restaurar los datos desde $selectedFile?', style: TextStyle(color: AppColors.textNormal)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar', style: TextStyle(color: AppColors.textNormal))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedRed),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Loader de importación
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.accentColor)),
            const SizedBox(height: 10),
            Text("Esto puede tardar unos instantes", style: TextStyle(color: AppColors.textNormal)),
          ],
        ),
      ),
    );

    await UsuarioBackup.importSelectedBackup(context, selectedFile);
    Navigator.pop(context);
  }
}
