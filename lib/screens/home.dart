import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:health/health.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/data/database_helper.dart';
import 'package:mrfit/models/health/health.dart';
import 'package:mrfit/models/cache/custom_cache.dart';
import 'package:mrfit/widgets/home/calendar.dart';
import 'package:mrfit/widgets/home/daily_hc_disable.dart';
import 'package:mrfit/widgets/home/daily_steps_activity_kcal.dart';
import 'package:mrfit/widgets/home/daily_sleep.dart';
import 'package:mrfit/widgets/home/daily_trainings.dart';
import 'package:mrfit/widgets/home/daily_physical.dart';
import 'package:mrfit/widgets/home/daily_nutrition.dart';
import 'package:mrfit/widgets/home/daily_hearth.dart';
import 'package:mrfit/widgets/home/daily_statistics.dart';
import 'package:mrfit/widgets/home/daily_vitals.dart';
import 'package:mrfit/services/step_counter_service.dart';
import 'package:mrfit/providers/walking_provider.dart';
import 'package:mrfit/screens/estadisticas/actividad_page.dart';

class InicioPage extends ConsumerStatefulWidget {
  const InicioPage({super.key});

  @override
  ConsumerState<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends ConsumerState<InicioPage> {
  DateTime _selectedDate = DateTime.now();
  Set<DateTime> _diasEntrenados = {};
  final GlobalKey<State<CalendarWidget>> _calendarKey = GlobalKey<State<CalendarWidget>>();
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey<RefreshIndicatorState>();
  bool _showHcWarning = true;
  int _refreshCounter = 0;
  StepCounterService? _stepCounterService;

  // Estados para los datos diarios
  Map<String, bool> _grantedPermissions = {};
  List<HealthDataPoint> _dataPointsSteps = [];
  List<HealthDataPoint> _dataPointsWorkout = [];
  List<Map<String, dynamic>> _entrenamientosMrFit = [];

  void _clearDailyStatsData() {
    _dataPointsSteps = [];
    _dataPointsWorkout = [];
    _entrenamientosMrFit = [];
  }

  // Obtiene y actualiza los datos necesarios para dailyStatsWidget según el día seleccionado.
  Future<void> _fetchAndSetDailyStatsData(Usuario usuario, DateTime day) async {
    final Map<String, bool> grantedPermissions = {};
    for (var key in usuario.healthDataTypesString.keys) {
      final bool permissionGranted = await usuario.checkPermissionsFor(key);
      grantedPermissions[key] = permissionGranted;
    }

    List<HealthDataPoint> dataPointsSteps = [];
    List<HealthDataPoint> dataPointsWorkout = [];
    List<Map<String, dynamic>> entrenamientosMrFit = [];

    final stepsHC = usuario.healthDataTypesString['STEPS'];
    final workoutHC = usuario.healthDataTypesString['WORKOUT'];

    final bool hasSteps = stepsHC != null && grantedPermissions['STEPS'] == true;
    final bool hasWorkout = workoutHC != null && grantedPermissions['WORKOUT'] == true;

    // Ejecuta las llamadas en paralelo para mejorar el rendimiento.
    final futures = <Future>[];

    if (hasSteps) {
      futures.add(
        usuario.readHealthDataByDate([stepsHC], day).then((rawSteps) {
          dataPointsSteps = HealthUtils.customRemoveDuplicates(rawSteps);
        }),
      );
    }
    if (hasWorkout) {
      futures.add(
        usuario.readHealthDataByDate([workoutHC], day).then((result) {
          dataPointsWorkout = result;
        }),
      );
    }
    futures.add(
      usuario.getActivityMrFit(day).then((result) {
        entrenamientosMrFit = result;
      }),
    );

    await Future.wait(futures);

    final bool permissionsChanged = !mapEquals(_grantedPermissions, grantedPermissions);
    final bool stepsChanged = !listEquals(_dataPointsSteps, dataPointsSteps);
    final bool workoutsChanged = !listEquals(_dataPointsWorkout, dataPointsWorkout);
    final bool entrenamientosChanged = !listEquals(_entrenamientosMrFit, entrenamientosMrFit);

    if (permissionsChanged || stepsChanged || workoutsChanged || entrenamientosChanged) {
      setState(() {
        _grantedPermissions = grantedPermissions;
        _dataPointsSteps = dataPointsSteps;
        _dataPointsWorkout = dataPointsWorkout;
        _entrenamientosMrFit = entrenamientosMrFit;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    DatabaseHelper.instance.database.then((db) {});
    initializeDateFormatting('es', null);
    _cargarResumenEntrenamientos();
    _checkHcWarning();
    final usuario = ref.read(usuarioProvider);
    _fetchAndSetDailyStatsData(usuario, _selectedDate);

    // Inicializa el servicio de conteo de pasos si está disponible
    if (!usuario.isActivityRecognitionAvailable) {
      usuario.requestActivityRecognitionPermission();
    } else {
      _stepCounterService = StepCounterService(
        usuario: usuario,
        // onError: (error) => print("Error en el podómetro: $error"),
        onStatusChanged: (walking) => ref.read(walkingProvider.notifier).state = walking,
      );
      Future.microtask(() => _stepCounterService!.start());
    }
  }

  @override
  void dispose() {
    _stepCounterService?.dispose();
    super.dispose();
  }

  Future<void> _checkHcWarning() async {
    final cache = await CustomCache.getByKey("warning_hc_disable");
    if (cache != null && cache.value == "0") {
      setState(() => _showHcWarning = false);
      return;
    }
    setState(() => _showHcWarning = true);
  }

  Future<void> _cargarResumenEntrenamientos() async {
    final usuario = ref.read(usuarioProvider);
    final data = await usuario.getResumenEntrenamientos();
    List<dynamic> resumen = [];
    if (data != null) resumen = data;
    resumen.sort((a, b) => DateTime.parse(b['inicio']).compareTo(DateTime.parse(a['inicio'])));
    if (!mounted) return;
    setState(() {
      _diasEntrenados = resumen.where((e) => e['inicio'] != null).map((e) {
        final dt = DateTime.parse(e['inicio']).toLocal();
        return DateTime(dt.year, dt.month, dt.day);
      }).toSet();
    });
  }

  /// Cambia el día seleccionado al hacer swipe y actualiza el calendario si es necesario.
  void _onHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    final isSwipeLeft = details.primaryVelocity! < 0;
    final isSwipeRight = details.primaryVelocity! > 0;

    DateTime nextDate = _selectedDate;
    if (isSwipeLeft) {
      nextDate = _selectedDate.add(const Duration(days: 1));
      if (nextDate.isAfter(DateTime.now())) return;
    } else if (isSwipeRight) {
      nextDate = _selectedDate.subtract(const Duration(days: 1));
    } else {
      return;
    }

    setState(() {
      _selectedDate = nextDate;
      _clearDailyStatsData();
    });
    final usuario = ref.read(usuarioProvider);
    _fetchAndSetDailyStatsData(usuario, nextDate);
    _reloadCalendarIfInCurrentWeek(nextDate);
  }

  /// Actualiza el calendario si el día seleccionado está en la semana actual.
  void _reloadCalendarIfInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - DateTime.monday));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    if (!date.isBefore(startOfWeek) && !date.isAfter(endOfWeek)) {
      final state = _calendarKey.currentState;
      if (state is CalendarWidgetStateBase) {
        state.reloadCurrentWeek();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.read(usuarioProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: CalendarWidget(
                key: _calendarKey,
                usuario: usuario,
                selectedDate: _selectedDate,
                grantedPermissions: _grantedPermissions,
                onDateSelected: (date) {
                  if (date.isAfter(DateTime.now()) || date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day) {
                    return;
                  }
                  setState(() {
                    _selectedDate = date;
                    _clearDailyStatsData();
                  });
                  final usuario = ref.read(usuarioProvider);
                  _fetchAndSetDailyStatsData(usuario, date);
                },
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: CalendarFooterWidget(
                usuario: usuario,
                selectedDate: _selectedDate,
                onDateChanged: (date) => setState(() => _selectedDate = date),
                diasEntrenados: _diasEntrenados,
                onJumpToToday: () {
                  final state = _calendarKey.currentState;
                  if (state is CalendarWidgetStateBase) {
                    state.jumpToToday();
                  }
                  final today = DateTime.now();
                  if (today.year == _selectedDate.year && today.month == _selectedDate.month && today.day == _selectedDate.day) {
                    return;
                  }
                  setState(() {
                    _selectedDate = today;
                    _clearDailyStatsData();
                  });
                  final usuario = ref.read(usuarioProvider);
                  _fetchAndSetDailyStatsData(usuario, _selectedDate);
                },
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: RefreshIndicator(
                      key: _refreshKey,
                      onRefresh: () async {
                        setState(() {
                          _refreshCounter++;
                          _clearDailyStatsData();
                        });
                        _reloadCalendarIfInCurrentWeek(_selectedDate);
                        await _cargarResumenEntrenamientos();
                        await _checkHcWarning();
                        final usuario = ref.read(usuarioProvider);
                        await _fetchAndSetDailyStatsData(usuario, _selectedDate);
                      },
                      child: GestureDetector(
                        onHorizontalDragEnd: _onHorizontalDrag,
                        child: NotificationListener<ScrollNotification>(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                            child: Column(
                              children: [
                                if (!usuario.isHealthConnectAvailable && _showHcWarning) ...[
                                  dailyHCDisableWidget(
                                    usuario: usuario,
                                    onInstallHealthConnect: () async {
                                      // Abre la ficha de Health Connect en Play Store
                                      const url = 'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata';
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    onClose: () async {
                                      setState(() => _showHcWarning = false);
                                    },
                                  ),
                                  const SizedBox(height: 15),
                                ],
                                if (usuario.isHealthConnectAvailable) ...[
                                  GestureDetector(
                                    onTap: () {
                                      // Navega a la página de actividad al pulsar el widget
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ActividadPage(
                                            selectedDate: _selectedDate,
                                            steps: _dataPointsSteps,
                                            entrenamientos: _dataPointsWorkout,
                                            entrenamientosMrFit: _entrenamientosMrFit,
                                          ),
                                        ),
                                      );
                                    },
                                    child: dailyStatsWidget(
                                      usuario: usuario,
                                      grantedPermissions: _grantedPermissions,
                                      dataPointsSteps: _dataPointsSteps,
                                      dataPointsWorkout: _dataPointsWorkout,
                                      entrenamientosMrFit: _entrenamientosMrFit,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                ],
                                DailyTrainingsWidget(
                                  day: _selectedDate,
                                  usuario: usuario,
                                  dataPointsSteps: _dataPointsSteps,
                                  dataPointsWorkout: _dataPointsWorkout,
                                  entrenamientosMrFit: _entrenamientosMrFit,
                                ),
                                const SizedBox(height: 15),
                                dailySleepWidget(
                                  day: _selectedDate,
                                  usuario: usuario,
                                  refreshKey: _refreshCounter,
                                ),
                                const SizedBox(height: 15),
                                DailyNutritionWidget(day: _selectedDate, usuario: usuario),
                                if (usuario.isHealthConnectAvailable) ...[
                                  const SizedBox(height: 15),
                                  dailyHearthWidget(
                                    day: _selectedDate,
                                    usuario: usuario,
                                    refreshKey: _refreshCounter,
                                  ),
                                  const SizedBox(height: 15),
                                  dailyVitalsWidget(
                                    day: _selectedDate,
                                    usuario: usuario,
                                    refreshKey: _refreshCounter,
                                  ),
                                  const SizedBox(height: 15),
                                  dailyPhysicalWidget(usuario: usuario),
                                  const SizedBox(height: 15),
                                  StatisticsWidget(usuario: usuario),
                                ],
                                SizedBox(height: 30 + MediaQuery.of(context).padding.bottom),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
