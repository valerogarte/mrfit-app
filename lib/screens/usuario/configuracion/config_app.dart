import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:convert';
import 'package:mrfit/models/usuario/usuario_backup.dart';

class ConfiguracionApp {
  static Future<void> loginWithGoogle(
    BuildContext context,
    Usuario usuario,
    Function(bool) onStatusChanged,
  ) async {
    try {
      await usuario.googleSignOut();
      final googleUser = await usuario.googleSignIn();
      if (googleUser != null) {
        onStatusChanged(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al iniciar sesión con Google')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al iniciar sesión con Google')));
    }
  }

  static Future<void> confirmUnlink(BuildContext context, Function() logoutCallback) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Confirmación',
            style: TextStyle(color: AppColors.textNormal),
          ),
          content: const Text(
            '¿Estás seguro de que quieres desvincular tu cuenta de Google Fit?',
            style: TextStyle(color: AppColors.textNormal),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedRed),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Desvincular'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      logoutCallback();
    }
  }

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
        return Builder(builder: (innerContext) {
          bool isTesting = false;
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
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textNormal),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: hostController,
                            decoration: const InputDecoration(labelText: 'Host'),
                            validator: (value) => value == null || value.isEmpty ? 'Ingrese el host' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: portController,
                            decoration: const InputDecoration(labelText: 'Port'),
                            keyboardType: TextInputType.number,
                            validator: (value) => value == null || value.isEmpty ? 'Ingrese el puerto' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: userController,
                            decoration: const InputDecoration(labelText: 'User'),
                            validator: (value) => value == null || value.isEmpty ? 'Ingrese el usuario' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: pwdController,
                            decoration: const InputDecoration(labelText: 'Password'),
                            obscureText: true,
                            validator: (value) => value == null || value.isEmpty ? 'Ingrese la contraseña' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: remoteDirController,
                            decoration: const InputDecoration(labelText: 'Directorio Remoto'),
                            validator: (value) => value == null || value.isEmpty ? 'Ingrese el directorio remoto' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedFrequency,
                            decoration: const InputDecoration(labelText: 'Frecuencia de sincronización'),
                            style: const TextStyle(color: AppColors.textNormal),
                            dropdownColor: AppColors.cardBackground,
                            items: frequencyOptions.map((freq) {
                              return DropdownMenuItem<String>(
                                value: freq,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(freq, style: const TextStyle(color: AppColors.textNormal)),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                selectedFrequency = value;
                              }
                            },
                            validator: (value) => value == null ? 'Seleccione una frecuencia' : null,
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.background),
                            onPressed: isTesting
                                ? null
                                : () async {
                                    setState(() {
                                      isTesting = true;
                                    });
                                    await ConfiguracionApp.testSFTPConnectivity(
                                      sheetContext,
                                      host: hostController.text,
                                      port: portController.text,
                                      user: userController.text,
                                      pwd: pwdController.text,
                                    );
                                    setState(() {
                                      isTesting = false;
                                    });
                                  },
                            child: isTesting
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textNormal),
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
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Error durante la exportación.')),
                                );
                              }
                            },
                            child: const Text('Exportar ahora'),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
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
        });
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
      final int portNumber = int.parse(port);
      final socket = await SSHSocket.connect(host, portNumber);
      final client = SSHClient(socket, username: user, onPasswordRequest: () => pwd);
      final sftp = await client.sftp();
      final prefs = await SharedPreferences.getInstance();
      final remoteDirPath = prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';
      final testFilePath = '$remoteDirPath/write_test.txt';
      try {
        final testFile = await sftp.open(
          testFilePath,
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
        );
        await testFile.write(Stream.value(utf8.encode('test')));
        await testFile.close();
        await sftp.remove(testFilePath);
      } catch (e) {
        if (e.toString().contains('No such file')) {
          client.close();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('La carpeta remota no existe.')),
            );
          });
        } else {
          client.close();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sin permisos de escritura sobre la carpeta remota.')),
            );
          });
        }
        return;
      }
      final result = await client.run('echo connected');
      final decodedResult = utf8.decode(result);
      if (decodedResult.trim() == 'connected') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conexión exitosa.')),
          );
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error de conexión.')),
          );
        });
      }
      client.close();
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
            Text("Cargando archivos de respaldo...", style: const TextStyle(color: AppColors.textNormal)),
          ],
        ),
      ),
    );

    final backupFiles = await UsuarioBackup.listBackupFiles();
    Navigator.pop(context);
    if (backupFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontraron archivos de respaldo.')));
      return;
    }
    final selectedFile = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Selecciona un archivo de respaldo', style: const TextStyle(color: AppColors.textNormal)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: backupFiles.map((fileName) {
                  if (fileName.toLowerCase().endsWith('.sql')) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ActionChip(
                        label: Text(
                          fileName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textNormal),
                        ),
                        backgroundColor: AppColors.background,
                        onPressed: () => Navigator.pop(context, fileName),
                      ),
                    );
                  }
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, fileName),
                      child: Text(fileName, style: const TextStyle(color: AppColors.textNormal)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.mutedRed)),
            ),
          ],
        );
      },
    );
    if (selectedFile == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text('Confirmación', style: const TextStyle(color: AppColors.textNormal)),
          content: Text('¿Estás seguro de restaurar los datos desde el archivo $selectedFile?', style: const TextStyle(color: AppColors.textNormal)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedRed),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;
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
            Text("Esto puede tardar unos instantes", style: const TextStyle(color: AppColors.textNormal)),
          ],
        ),
      ),
    );
    await UsuarioBackup.importSelectedBackup(context, selectedFile);
    Navigator.pop(context);
  }
}
