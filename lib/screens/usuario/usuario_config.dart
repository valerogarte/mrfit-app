import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'configuracion/config_app.dart';
import 'configuracion/config_personal.dart';
import 'configuracion/config_ajustes.dart';
import 'configuracion/config_creditos.dart';
import 'package:mrfit/widgets/custom_bottom_sheet.dart';
import 'package:mrfit/providers/usuario_provider.dart'; // added import

class UsuarioConfigPage extends ConsumerStatefulWidget {
  const UsuarioConfigPage({super.key});

  @override
  ConsumerState<UsuarioConfigPage> createState() => _UsuarioConfigPageState();
}

class _UsuarioConfigPageState extends ConsumerState<UsuarioConfigPage> {
  bool _isGoogleFitLinked = false;
  bool _isHealthConnctLinked = false;

  @override
  void initState() {
    super.initState();
    _checkGoogleSignIn();
    final usuario = ref.read(usuarioProvider);
    usuario.checkPermissions().then((granted) {
      setState(() {
        _isHealthConnctLinked = granted;
      });
    });
  }

  Future<void> _checkGoogleSignIn() async {
    final usuario = ref.read(usuarioProvider);
    final account = usuario.googleSignInSilently();
    setState(() {
      _isGoogleFitLinked = account != null;
    });
  }

  Future<void> _logout() async {
    Logger().i('Cerrando sesión...');
    final usuario = ref.read(usuarioProvider);
    await usuario.logout();
    setState(() {
      _isGoogleFitLinked = false;
    });
  }

  int calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _showConfigDialog(String campo, String title, Widget content) async {
    final newValue = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 1.0,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) {
          return ConfigBottomSheet(
            title: title,
            child: SingleChildScrollView(
              controller: scrollController,
              child: content,
            ),
          );
        },
      ),
    );
    if (newValue != null) {
      setState(() {
        ref.refresh(usuarioProvider);
      });
    }
  }

  Future<void> _showPersonalDialog(String campo, String title) async {
    await _showConfigDialog(campo, title, ConfiguracionPersonalDialog(campo: campo));
  }

  Future<void> _showAjustesDialog(String campo, String title) async {
    await _showConfigDialog(campo, title, ConfiguracionAjustesPage(campo: campo));
  }

  Future<void> _showCreditosDialog(String opcion, String title) async {
    await _showConfigDialog(opcion, title, ConfiguracionCreditosPage(opcion: opcion));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(usuarioProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          // Datos Personales
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Datos Personales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor)),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.person, color: AppColors.accentColor),
            title: Text(currentUser.username.isNotEmpty ? currentUser.username : 'Alias', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showPersonalDialog('Alias', 'Editar Alias'),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.cake, color: AppColors.accentColor),
            title: Text('${calculateAge(currentUser.fechaNacimiento)} años', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showPersonalDialog('Fecha de Nacimiento', 'Editar Fecha de Nacimiento'),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.height, color: AppColors.accentColor),
            title: FutureBuilder<int>(
              future: currentUser.getCurrentHeight(9999),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('...', style: TextStyle(color: AppColors.textColor));
                } else if (snapshot.hasError) {
                  return Text('Sin acceso a Health Connect.', style: TextStyle(color: AppColors.textColor));
                }
                final altura = snapshot.data;
                return Text(altura != null ? '$altura cm' : 'Altura', style: TextStyle(color: AppColors.textColor));
              },
            ),
            onTap: () => _showPersonalDialog('Altura', 'Editar Altura'),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.transgender, color: AppColors.accentColor),
            title: Text(currentUser.genero.isNotEmpty ? currentUser.genero : 'Género', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showPersonalDialog('Género', 'Editar Género'),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.star, color: AppColors.accentColor),
            title: Text(currentUser.experiencia.isNotEmpty ? currentUser.experiencia : 'Experiencia', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showPersonalDialog('Experiencia', 'Editar Experiencia'),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.trending_up, color: AppColors.accentColor),
            title: Text('Volumen Máximo', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showPersonalDialog('Volumen Máximo', 'Volumen Máximo'),
          ),
          // Ajustes de la App
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Ajustes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor)),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.speaker_notes, color: AppColors.accentColor),
            title: Text('Entrenador', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showAjustesDialog('Entrenador', 'Editar Entrenador'),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.record_voice_over, color: AppColors.accentColor),
            title: Text('Voz del Entrenador', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showAjustesDialog('Voz del Entrenador', 'Editar Voz del Entrenador'),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.volume_up, color: AppColors.accentColor),
            title: Text('Volumen del Entrenador', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showAjustesDialog('Volumen del Entrenador', 'Editar Volumen del Entrenador'),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.straighten, color: AppColors.accentColor),
            title: Text('Unidades', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showAjustesDialog('Unidades', 'Editar Unidades'),
          ),
          // Datos y respaldos
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Datos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor)),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.restore, color: AppColors.accentColor),
            title: Text('Restaurar Datos', style: TextStyle(color: AppColors.textColor)),
            onTap: () => ConfiguracionApp.selectFileFromServer(context),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.cloud_upload, color: AppColors.accentColor),
            title: Text('Respaldo sFTP', style: TextStyle(color: AppColors.textColor)),
            onTap: () => ConfiguracionApp.openFTPConfig(context),
          ),
          // Integraciones
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Integraciones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor)),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.watch, color: AppColors.accentColor),
            title: Text('Smartwatch', style: TextStyle(color: AppColors.textColor)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Vinculación con Smartwatch")));
            },
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.fitness_center, color: AppColors.accentColor),
            title: Text(
              _isGoogleFitLinked ? 'Desvincular Google Fit' : 'Vincular con Google Fit',
              style: TextStyle(color: AppColors.textColor),
            ),
            onTap: () {
              final usuario = ref.read(usuarioProvider);
              if (_isGoogleFitLinked) {
                ConfiguracionApp.confirmUnlink(context, _logout);
              } else {
                ConfiguracionApp.loginWithGoogle(
                  context,
                  usuario,
                  (status) {
                    setState(() {
                      _isGoogleFitLinked = status;
                    });
                  },
                );
              }
            },
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.favorite, color: AppColors.accentColor),
            title: Text(
              _isHealthConnctLinked ? 'Health Connect vinculado' : 'Vincular con Health Connect',
              style: TextStyle(color: AppColors.textColor),
            ),
            onTap: () async {
              if (!_isHealthConnctLinked) {
                final usuario = ref.read(usuarioProvider);
                final granted = await usuario.requestPermissions();
                setState(() {
                  _isHealthConnctLinked = granted;
                });
              }
            },
          ),
          // Créditos
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Créditos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColor)),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.code, color: AppColors.accentColor),
            title: Text('Mejoras en la app', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showCreditosDialog('Mejoras en la app', 'Mejoras en la app'),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.feed_rounded, color: AppColors.accentColor),
            title: Text('OpenSource', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showCreditosDialog('OpenSource', 'OpenSource'),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.info, color: AppColors.accentColor),
            title: Text('Daniel Valero González', style: TextStyle(color: AppColors.textColor)),
            onTap: () => _showCreditosDialog('Daniel Valero González', 'Acerca del desarrollador'),
          ),
          const SizedBox(height: 45, child: DecoratedBox(decoration: BoxDecoration(color: AppColors.cardBackground))),
        ],
      ),
    );
  }
}
