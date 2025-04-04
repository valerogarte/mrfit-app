import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../utils/colors.dart';
import '../models/usuario/usuario.dart';
import '../data/database_helper.dart';
import '../models/entrenamiento/entrenamiento.dart';
import '../widgets/home/calendar.dart';
import '../widgets/entrenamiento/entrenamiento_listado.dart';
import '../providers/usuario_provider.dart';

class InicioPage extends ConsumerStatefulWidget {
  const InicioPage({super.key});

  @override
  ConsumerState<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends ConsumerState<InicioPage> {
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _resumenEntrenamientos = [];
  Set<DateTime> _diasEntrenados = {};

  @override
  void initState() {
    super.initState();
    // Inicializa la base de datos si no existe
    DatabaseHelper.instance.database.then((db) {});
    initializeDateFormatting('es', null);
    _cargarResumenEntrenamientos();
  }

  void _cargarResumenEntrenamientos() async {
    final usuario = ref.read(usuarioProvider);
    await usuario.googleSignInSilently();

    final data = await usuario.getResumenEntrenamientos();
    List<dynamic> resumen = [];
    if (data != null) {
      resumen = data;
    }
    if (usuario.googleIsLoggedIn()) {
      final dataGoogleFit = await usuario.googleGetEntrenamientos30Dias();
      if (dataGoogleFit != null) {
        List<dynamic> googleTrainings = dataGoogleFit.map((session) {
          final startMillis = session['startTimeMillis'];
          final endMillis = session['endTimeMillis'];
          DateTime inicio = DateTime.fromMillisecondsSinceEpoch(int.parse(startMillis));
          DateTime fin = DateTime.fromMillisecondsSinceEpoch(int.parse(endMillis));
          Duration duracion = fin.difference(inicio);
          return {
            "id": session["id"],
            "titulo": (session["description"] != null && session["description"].isNotEmpty) ? session["description"] : usuario.getActivityTypeTitle(session["activityType"]),
            "inicio": inicio.toIso8601String(),
            "duracion": "${duracion.inMinutes} minutos",
            "isGoogleFit": true,
          };
        }).toList();
        resumen.addAll(googleTrainings);
      }
    }
    resumen.sort((a, b) => DateTime.parse(b['inicio']).compareTo(DateTime.parse(a['inicio'])));
    if (mounted) {
      setState(() {
        _resumenEntrenamientos = resumen;
        _diasEntrenados = _resumenEntrenamientos.where((entrenamiento) => entrenamiento['inicio'] != null).map((entrenamiento) {
          DateTime dateTime = DateTime.parse(entrenamiento['inicio']).toLocal();
          return DateTime(dateTime.year, dateTime.month, dateTime.day);
        }).toSet();
      });
    }
  }

  void _refreshCalendar() {
    setState(() {
      _cargarResumenEntrenamientos();
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime today = DateTime.now();
    int daysTrainedLast7Days = _diasEntrenados.where((date) => date.isAfter(today.subtract(Duration(days: 7)))).length;
    int daysTrainedLast30Days = _diasEntrenados.where((date) => date.isAfter(today.subtract(Duration(days: 30)))).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Se reemplaza la lógica del calendario por CalendarWidget
            CalendarWidget(
              selectedDate: _selectedDate,
              diasEntrenados: _diasEntrenados,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$daysTrainedLast30Days/30',
                        style: TextStyle(
                          fontSize: 40,
                          color: AppColors.accentColor,
                        ),
                      ),
                      Text(
                        'últimos 30 días.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.fitness_center,
                    color: AppColors.accentColor,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '$daysTrainedLast7Days/7',
                        style: TextStyle(
                          fontSize: 40,
                          color: AppColors.accentColor,
                        ),
                      ),
                      Text(
                        'últimos 7 días.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 2,
              child: ListadoEntrenamientos(
                resumenEntrenamientos: _resumenEntrenamientos,
                onDismissed: (context, index, removedTraining) async {
                  setState(() {
                    _resumenEntrenamientos.removeAt(index);
                  });
                  if (removedTraining['isGoogleFit'] != true) {
                    final entrenamientoObj = await Entrenamiento.loadById(removedTraining['id']);
                    if (entrenamientoObj != null) {
                      await entrenamientoObj.delete();
                    }
                  }
                  _refreshCalendar();
                },
                onTrainingDeleted: _refreshCalendar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
