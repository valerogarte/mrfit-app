import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'configuracion/config_app.dart';
import 'configuracion/config_personal.dart';
import 'configuracion/config_creditos.dart';
import 'configuracion/config_objetivos.dart';
import 'configuracion/config_entrenador.dart';
import 'package:mrfit/widgets/custom_bottom_sheet.dart';
import 'package:intl/intl.dart';

class UsuarioConfigPage extends ConsumerStatefulWidget {
  const UsuarioConfigPage({super.key});

  @override
  ConsumerState<UsuarioConfigPage> createState() => _UsuarioConfigPageState();
}

class _UsuarioConfigPageState extends ConsumerState<UsuarioConfigPage> {
  // static const List<String> semana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  bool _isHealthConnctLinked = false;

  @override
  void initState() {
    super.initState();
    ref.read(usuarioProvider).checkPermissions().then((granted) {
      setState(() => _isHealthConnctLinked = granted);
    });
  }

  int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    var age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
    return age;
  }

  Future<void> _showConfigDialog(String campo, String title, Widget content) async {
    if (campo == 'Hora de acostarse' || campo == 'Hora de levantarse') {
      final user = ref.read(usuarioProvider);
      final initialTime = (campo == 'Hora de acostarse' ? user.horaInicioSueno : user.horaFinSueno) ?? TimeOfDay.now();

      final time = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );

      if (time != null) {
        final success = campo == 'Hora de acostarse' ? await user.setHoraInicioSueno(time) : await user.setHoraFinSueno(time);
        if (success) setState(() => ref.refresh(usuarioProvider));
      }
      return;
    }

    final newValue = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 1.0,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => ConfigBottomSheet(
          title: title,
          child: SingleChildScrollView(
            controller: controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                content,
              ],
            ),
          ),
        ),
      ),
    );
    if (newValue != null) setState(() => ref.refresh(usuarioProvider));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(usuarioProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          // Datos Personales
          const SectionHeader('Datos Personales'),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.cake, color: AppColors.accentColor),
            title: Text('${calculateAge(user.fechaNacimiento)} años', style: TextStyle(color: AppColors.textMedium)),
            onTap: () => ConfiguracionPersonalDialog.selectBirthDate(context, ref),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.height, color: AppColors.accentColor),
            title: FutureBuilder<int>(
              future: user.getCurrentHeight(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return Text('...', style: TextStyle(color: AppColors.textMedium));
                if (snap.hasError) return Text('Sin acceso a Health Connect.', style: TextStyle(color: AppColors.textMedium));
                return Text('${snap.data} cm', style: TextStyle(color: AppColors.textMedium));
              },
            ),
            onTap: () => _showConfigDialog('Altura', 'Editar Altura', ConfiguracionPersonalDialog(campo: 'Altura')),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.transgender, color: AppColors.accentColor),
            title: Text(user.genero.isNotEmpty ? user.genero : 'Género', style: TextStyle(color: AppColors.textMedium)),
            onTap: () => _showConfigDialog('Género', 'Editar Género', ConfiguracionPersonalDialog(campo: 'Género')),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.star, color: AppColors.accentColor),
            title: Text(user.experiencia.isNotEmpty ? user.experiencia : 'Experiencia', style: TextStyle(color: AppColors.textMedium)),
            onTap: () => _showConfigDialog('Experiencia', 'Editar Experiencia', ConfiguracionPersonalDialog(campo: 'Experiencia')),
          ),
          // ListTile(
          //   tileColor: AppColors.cardBackground,
          //   leading: Icon(Icons.trending_up, color: AppColors.accentColor),
          //   title: Text('Volumen Máximo', style: TextStyle(color: AppColors.textMedium)),
          //   onTap: () => _showConfigDialog('Volumen Máximo', 'Volumen Máximo', ConfiguracionPersonalDialog(campo: 'Volumen Máximo')),
          // ),

          // Objetivos
          const SectionHeader('Objetivos'),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.directions_walk, color: AppColors.accentColor),
            title: Text(
              user.objetivoPasosDiarios > 0 ? '${NumberFormat.decimalPattern('es').format(user.objetivoPasosDiarios)} pasos diarios' : 'Objetivo Pasos',
              style: TextStyle(color: AppColors.textMedium),
            ),
            onTap: () => _showConfigDialog('Objetivo Pasos', 'Editar Objetivo Pasos', ConfiguracionObjetivosPage(campo: 'Objetivo Pasos')),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.accessibility_new, color: AppColors.accentColor),
            title: Text(user.objetivoTiempoEntrenamiento > 0 ? '${user.objetivoTiempoEntrenamiento} m entrenamiento diario' : 'Objetivo Actividad', style: TextStyle(color: AppColors.textMedium)),
            onTap: () => _showConfigDialog('Objetivo Actividad', 'Editar Objetivo Actividad', ConfiguracionObjetivosPage(campo: 'Objetivo Actividad')),
          ),
          // Campo para Objetivo Tiempo Activo
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.timelapse, color: AppColors.accentColor),
            title: Text(
              user.objetivoTiempoActivo > 0 ? '${user.objetivoTiempoActivo} horas activas diarias' : 'Horas Activo',
              style: TextStyle(color: AppColors.textMedium),
            ),
            onTap: () => _showConfigDialog('Objetivo Tiempo Activo', 'Editar Objetivo Tiempo Activo', ConfiguracionObjetivosPage(campo: 'Objetivo Tiempo Activo')),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.calendar_view_week, color: AppColors.accentColor),
            title: Text(user.objetivoEntrenamientoSemanal > 0 ? '${user.objetivoEntrenamientoSemanal} entrenamientos semanales' : 'Objetivo Entrenamiento Semanal', style: TextStyle(color: AppColors.textMedium)),
            onTap: () => _showConfigDialog('Objetivo Entrenamiento Semanal', 'Editar Objetivo Entrenamiento Semanal', ConfiguracionObjetivosPage(campo: 'Objetivo Entrenamiento Semanal')),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.bedtime, color: AppColors.accentColor),
            title: Text(
              user.horaInicioSueno != null ? 'Hora de acostarse: ${user.horaInicioSueno!.format(context)}' : 'Hora de acostarse',
              style: TextStyle(color: AppColors.textMedium),
            ),
            onTap: () => _showConfigDialog('Hora de acostarse', 'Editar Hora de acostarse', ConfiguracionObjetivosPage(campo: 'Hora de acostarse')),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.bedtime_outlined, color: AppColors.accentColor),
            title: Text(
              user.horaFinSueno != null ? 'Hora de levantarse: ${user.horaFinSueno!.format(context)}' : 'Hora de levantarse',
              style: TextStyle(color: AppColors.textMedium),
            ),
            onTap: () => _showConfigDialog('Hora de levantarse', 'Editar Hora de levantarse', ConfiguracionObjetivosPage(campo: 'Hora de levantarse')),
          ),

          // Unidades
          // const SectionHeader('Unidades'),
          // ListTile(
          //   tileColor: AppColors.cardBackground,
          //   leading: Icon(Icons.straighten, color: AppColors.accentColor),
          //   title: Text(user.unidadDistancia == 'km' ? 'Kilómetros' : 'Millas', style: TextStyle(color: AppColors.textMedium)),
          //   onTap: () => _showConfigDialog('Unidad Distancia', 'Editar Unidad Distancia', ConfiguracionUnidadesPage(campo: 'Unidad Distancia')),
          // ),
          // ListTile(
          //   tileColor: AppColors.cardBackground,
          //   leading: Icon(Icons.aspect_ratio, color: AppColors.accentColor),
          //   title: Text(user.unidadTamano == 'cm' ? 'Centímetros' : 'Pulgadas', style: TextStyle(color: AppColors.textMedium)),
          //   onTap: () => _showConfigDialog('Unidad Tamaño', 'Editar Unidad Tamaño', ConfiguracionUnidadesPage(campo: 'Unidad Tamaño')),
          // ),
          // ListTile(
          //   tileColor: AppColors.cardBackground,
          //   leading: Icon(Icons.fitness_center, color: AppColors.accentColor),
          //   title: Text(user.unidadesPeso == 'metrico' ? 'Métrico (kg)' : 'Imperial (lb)', style: TextStyle(color: AppColors.textMedium)),
          //   onTap: () => _showConfigDialog('Unidades Peso', 'Editar Unidades Peso', ConfiguracionUnidadesPage(campo: 'Unidades Peso')),
          // ),
          // ListTile(
          //   tileColor: AppColors.cardBackground,
          //   leading: Icon(Icons.calendar_today, color: AppColors.accentColor),
          //   title: Text('La semana empieza el ${semana[user.primerDiaSemana]}', style: TextStyle(color: AppColors.textMedium)),
          //   onTap: () => _showConfigDialog('Primer Día Semana', 'Editar Primer Día Semana', ConfiguracionUnidadesPage(campo: 'Primer Día Semana')),
          // ),

          // Entrenador
          const SectionHeader('Entrenador'),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.fitness_center, color: AppColors.accentColor),
            title: const Text('Entrenador Activo', style: TextStyle(color: AppColors.textMedium)),
            trailing: Switch(
              value: user.entrenadorActivo,
              activeColor: AppColors.mutedAdvertencia,
              activeTrackColor: AppColors.background,
              inactiveTrackColor: AppColors.background,
              inactiveThumbColor: AppColors.cardBackground,
              onChanged: (value) async {
                final success = await user.setEntrenadorActivo(value);
                if (success) setState(() {});
              },
            ),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.record_voice_over, color: AppColors.accentColor),
            title: Text(
              'Voz del Entrenador',
              style: TextStyle(
                color: user.entrenadorActivo ? AppColors.textMedium : AppColors.textMedium.withAlpha(100),
              ),
            ),
            enabled: user.entrenadorActivo,
            onTap: user.entrenadorActivo ? () => _showConfigDialog('Voz del Entrenador', 'Editar Voz del Entrenador', ConfiguracionEntrenadorPage(campo: 'Voz del Entrenador')) : null,
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.volume_up, color: AppColors.accentColor),
            title: Text(
              'Volumen del Entrenador',
              style: TextStyle(
                color: user.entrenadorActivo ? AppColors.textMedium : AppColors.textMedium.withAlpha(100),
              ),
            ),
            enabled: user.entrenadorActivo,
            onTap: user.entrenadorActivo ? () => _showConfigDialog('Volumen del Entrenador', 'Editar Volumen del Entrenador', ConfiguracionEntrenadorPage(campo: 'Volumen del Entrenador')) : null,
          ),

          // Avisos
          const SectionHeader('Avisos'),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.timer, color: AppColors.accentColor),
            title: const Text('Aviso 10 Segundos', style: TextStyle(color: AppColors.textMedium)),
            trailing: Switch(
              value: user.aviso10Segundos,
              activeColor: AppColors.mutedAdvertencia,
              activeTrackColor: AppColors.background,
              inactiveTrackColor: AppColors.background,
              inactiveThumbColor: AppColors.cardBackground,
              onChanged: (value) async {
                final success = await user.setAviso10Segundos(value);
                if (success) setState(() {});
              },
            ),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.timer_off, color: AppColors.accentColor),
            title: const Text('Aviso Cuenta Atrás', style: TextStyle(color: AppColors.textMedium)),
            trailing: Switch(
              value: user.avisoCuentaAtras,
              activeColor: AppColors.mutedAdvertencia,
              activeTrackColor: AppColors.background,
              inactiveTrackColor: AppColors.background,
              inactiveThumbColor: AppColors.cardBackground,
              onChanged: (value) async {
                final success = await user.setAvisoCuentaAtras(value);
                if (success) setState(() {});
              },
            ),
          ),

          // Datos y respaldos
          const SectionHeader('Datos'),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.restore, color: AppColors.accentColor),
            title: Text('Restaurar Datos', style: TextStyle(color: AppColors.textMedium)),
            onTap: () => ConfiguracionApp.selectFileFromServer(context),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.cloud_upload, color: AppColors.accentColor),
            title: Text('Respaldo sFTP', style: TextStyle(color: AppColors.textMedium)),
            onTap: () => ConfiguracionApp.openFTPConfig(context),
          ),

          // Integraciones
          const SectionHeader('Integraciones'),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.watch, color: AppColors.accentColor),
            title: Text('Smartwatch', style: TextStyle(color: AppColors.textMedium)),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vinculación con Smartwatch aún no disponible'))),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.memory, color: AppColors.accentColor),
            title: Text('Inteligencia Artificial', style: TextStyle(color: AppColors.textMedium)),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Integración aún no disponible'))),
          ),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.favorite, color: AppColors.accentColor),
            title: Text(_isHealthConnctLinked ? 'Health Connect vinculado' : 'Vincular con Health Connect', style: TextStyle(color: AppColors.textMedium)),
            onTap: () async {
              if (!_isHealthConnctLinked) {
                final granted = await ref.read(usuarioProvider).requestPermissions();
                setState(() => _isHealthConnctLinked = granted);
              }
            },
          ),

          // Créditos
          const SectionHeader('Créditos'),
          ListTile(
            tileColor: AppColors.cardBackground,
            leading: Icon(Icons.code, color: AppColors.accentColor),
            title: Text('Información del desarrollador', style: TextStyle(color: AppColors.textMedium)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionCreditosPage())),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(text, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textMedium)),
      );
}
