import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:logger/logger.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:convert';
import 'package:mrfit/models/usuario/usuario_backup.dart';

class ConfiguracionApp {
  static Future<void> openFTPConfig(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FTPConfigScreen(prefs: prefs),
        fullscreenDialog: true,
      ),
    );
  }

  static Future<void> selectFileFromServer(BuildContext context) async {
    // Usar el contexto del Root Navigator para mostrar diálogos modales correctamente.
    final rootCtx = Navigator.of(context, rootNavigator: true).context;

    showDialog(
      context: rootCtx,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.accentColor),
            ),
            const SizedBox(height: 10),
            Text(
              "Cargando archivos de respaldo...",
              style: TextStyle(color: AppColors.textNormal),
            ),
          ],
        ),
      ),
    );

    final backupFiles = await UsuarioBackup.listarBackups();

    Navigator.of(rootCtx).pop();

    if (backupFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontraron archivos de respaldo.')),
      );
      return;
    }

    final deleting = <String, bool>{};

    final selectedFile = await showDialog<String>(
      context: rootCtx,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx2, setState) {
            return SimpleDialog(
              backgroundColor: AppColors.cardBackground,
              title: Text(
                'Archivos de respaldo',
                style: TextStyle(color: AppColors.textNormal),
              ),
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
                                  context: ctx2,
                                  builder: (_) => AlertDialog(
                                    backgroundColor: AppColors.cardBackground,
                                    title: Text('Confirmar borrado', style: TextStyle(color: AppColors.textNormal)),
                                    content: Text('¿Borrar $fileName?', style: TextStyle(color: AppColors.textNormal)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx2).pop(false),
                                        child: Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedRed),
                                        onPressed: () => Navigator.of(ctx2).pop(true),
                                        child: const Text('Borrar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                                setState(() => deleting[fileName] = true);
                                final ok = await UsuarioBackup.borrarBackup(fileName);
                                setState(() => deleting[fileName] = false);
                                if (ok) {
                                  setState(() => backupFiles.remove(fileName));
                                } else {
                                  showDialog(
                                    context: ctx2,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: AppColors.cardBackground,
                                      title: Text('Error', style: TextStyle(color: AppColors.textNormal)),
                                      content: Text('No se pudo borrar $fileName', style: TextStyle(color: AppColors.textNormal)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx2).pop(),
                                          child: const Text('Ok'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.upload_file, color: AppColors.accentColor),
                              onPressed: () {
                                Navigator.of(dialogContext).pop(fileName);
                              },
                            ),
                          ],
                        ),
                );
              }).toList(),
            );
          },
        );
      },
    );

    if (selectedFile == null) {
      return;
    }

    final confirmImport = await showDialog<bool>(
      context: rootCtx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Confirmación', style: TextStyle(color: AppColors.textNormal)),
        content: Text(
          '¿Estás seguro de restaurar los datos desde $selectedFile?',
          style: TextStyle(color: AppColors.textNormal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(rootCtx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedRed),
            onPressed: () => Navigator.of(rootCtx).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmImport != true) {
      return;
    }

    showDialog(
      context: rootCtx,
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

    final exito = await UsuarioBackup.importarBackupSeleccionado(context, selectedFile);

    Navigator.of(rootCtx).pop();

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Importación completada.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error durante la importación.')),
      );
    }
  }
}

class _FTPConfigScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const _FTPConfigScreen({Key? key, required this.prefs}) : super(key: key);

  @override
  State<_FTPConfigScreen> createState() => _FTPConfigScreenState();
}

class _FTPConfigScreenState extends State<_FTPConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostC, _portC, _userC, _pwdC, _remoteDirC;
  bool _probandoConex = false;

  final List<String> _frecuencias = ['Cada 12 horas', 'Diaria', 'Días Alternos', 'Semanal'];
  late String _freqSeleccionada;

  @override
  void initState() {
    super.initState();
    _hostC = TextEditingController(text: widget.prefs.getString('ftp_host') ?? '');
    _portC = TextEditingController(text: widget.prefs.getString('ftp_port') ?? '');
    _userC = TextEditingController(text: widget.prefs.getString('ftp_user') ?? '');
    _pwdC = TextEditingController(text: widget.prefs.getString('ftp_pwd') ?? '');
    _remoteDirC = TextEditingController(
      text: widget.prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit',
    );
    _freqSeleccionada = widget.prefs.getString('ftp_frequency') ?? _frecuencias[0];
    if (!_frecuencias.contains(_freqSeleccionada)) {
      _freqSeleccionada = _frecuencias[0];
    }
  }

  @override
  void dispose() {
    _hostC.dispose();
    _portC.dispose();
    _userC.dispose();
    _pwdC.dispose();
    _remoteDirC.dispose();
    super.dispose();
  }

  Future<void> _guardarConfiguracion() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.prefs.setString('ftp_host', _hostC.text.trim());
    await widget.prefs.setString('ftp_port', _portC.text.trim());
    await widget.prefs.setString('ftp_user', _userC.text.trim());
    await widget.prefs.setString('ftp_pwd', _pwdC.text.trim());
    await widget.prefs.setString('ftp_frequency', _freqSeleccionada);
    await widget.prefs.setString('sftp_remoteDirPath', _remoteDirC.text.trim());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _testearConex() async {
    if (_hostC.text.isEmpty || _portC.text.isEmpty || _userC.text.isEmpty || _pwdC.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos antes de testear.')),
      );
      return;
    }
    setState(() => _probandoConex = true);
    try {
      final socket = await SSHSocket.connect(
        _hostC.text.trim(),
        int.parse(_portC.text.trim()),
      );
      final client = SSHClient(
        socket,
        username: _userC.text.trim(),
        onPasswordRequest: () => _pwdC.text,
      );
      final sftp = await client.sftp();

      final remoteDir = widget.prefs.getString('sftp_remoteDirPath') ?? '/home/Documentos/MrFit';
      final testPath = '$remoteDir/write_test.txt';
      try {
        final f = await sftp.open(
          testPath,
          mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.truncate,
        );
        await f.write(Stream.value(utf8.encode('test')));
        await f.close();
        await sftp.remove(testPath);
      } on Exception catch (e) {
        client.close();
        final mensaje = e.toString().contains('No such file') ? 'La carpeta remota no existe.' : 'Sin permisos sobre la carpeta remota.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
        }
        return;
      }

      final res = await client.run('echo connected');
      final ok = utf8.decode(res).trim() == 'connected';
      client.close();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'Conexión exitosa.' : 'Error de conexión.')),
        );
      }
    } catch (e) {
      Logger().e('Error Test SFTP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _probandoConex = false);
      }
    }
  }

  Future<void> _exportarAhora() async {
    try {
      await UsuarioBackup.exportar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exportación realizada.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error durante la exportación.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldo sFTP'),
        backgroundColor: AppColors.background,
      ),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _campoTexto('Host', _hostC),
                const SizedBox(height: 12),
                _campoTexto('Puerto', _portC, tipo: TextInputType.number),
                const SizedBox(height: 12),
                _campoTexto('Usuario', _userC),
                const SizedBox(height: 12),
                _campoTexto('Password', _pwdC, oculto: true),
                const SizedBox(height: 12),
                _campoTexto('Directorio remoto', _remoteDirC),
                // const SizedBox(height: 12),
                // DropdownButtonFormField<String>(
                //   value: _freqSeleccionada,
                //   decoration: const InputDecoration(labelText: 'Frecuencia'),
                //   items: _frecuencias
                //       .map(
                //         (f) => DropdownMenuItem(
                //           value: f,
                //           child: Text(
                //             f,
                //             style: const TextStyle(color: AppColors.textNormal),
                //           ),
                //         ),
                //       )
                //       .toList(),
                //   onChanged: (v) {
                //     if (v != null) setState(() => _freqSeleccionada = v);
                //   },
                //   dropdownColor: AppColors.cardBackground,
                // ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.mutedAdvertencia),
                        onPressed: _probandoConex ? null : _testearConex,
                        child: _probandoConex
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Center(
                                child: Text(
                                  'Test',
                                  style: TextStyle(color: AppColors.background),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _exportarAhora,
                        child: const Text('Exportar ahora'),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancelar', style: TextStyle(color: AppColors.textNormal)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _guardarConfiguracion,
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
  }

  Widget _campoTexto(String label, TextEditingController controller, {TextInputType tipo = TextInputType.text, bool oculto = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: tipo,
      obscureText: oculto,
      validator: (v) => (v == null || v.isEmpty) ? 'Ingrese $label' : null,
    );
  }
}
