import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/data/database_helper.dart';
import 'package:mrfit/widgets/home/calendar.dart';
import 'package:mrfit/widgets/home/daily_steps_activity_kcal.dart';
import 'package:mrfit/widgets/home/daily_sleep.dart';
import 'package:mrfit/widgets/chart/resumen_semanal_entrenamiento.dart';
import 'package:mrfit/widgets/home/daily_trainings.dart';
import 'package:mrfit/widgets/home/daily_physical.dart';
import 'package:mrfit/widgets/home/daily_nutrition.dart';
import 'package:mrfit/widgets/home/daily_hearth.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/widgets/home/daily_statistics.dart';
import 'package:mrfit/widgets/home/daily_vitals.dart';

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

  @override
  void initState() {
    super.initState();
    DatabaseHelper.instance.database.then((db) {});
    initializeDateFormatting('es', null);
    _cargarResumenEntrenamientos();
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

    setState(() => _selectedDate = nextDate);
    _reloadCalendarIfInCurrentWeek(nextDate);
  }

  /// Actualiza el calendario si el día seleccionado está en la semana actual.
  void _reloadCalendarIfInCurrentWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - DateTime.monday));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    if (!date.isBefore(startOfWeek) && !date.isAfter(endOfWeek)) {
      (_calendarKey.currentState as dynamic)?.reloadCurrentWeek();
    }
  }

  /// Maneja la notificación de scroll y actualiza el calendario si corresponde.
  bool _onScrollNotification(ScrollNotification notification) {
    _reloadCalendarIfInCurrentWeek(_selectedDate);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days7 = _diasEntrenados.where((d) => d.isAfter(today.subtract(const Duration(days: 7)))).length;
    final days30 = _diasEntrenados.where((d) => d.isAfter(today.subtract(const Duration(days: 30)))).length;
    final usuario = ref.read(usuarioProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: CalendarWidget(
              key: _calendarKey,
              selectedDate: _selectedDate,
              diasEntrenados: _diasEntrenados,
              onDateSelected: (date) {
                if (date.isAfter(DateTime.now())) return;
                setState(() => _selectedDate = date);
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: CalendarHeaderWidget(
              selectedDate: _selectedDate,
              calendarKey: _calendarKey,
              onDateChanged: (date) => setState(() => _selectedDate = date),
              diasEntrenados: _diasEntrenados,
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
                      await _cargarResumenEntrenamientos();
                      setState(() {});
                    },
                    child: GestureDetector(
                      onHorizontalDragEnd: _onHorizontalDrag,
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onScrollNotification,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              dailyStatsWidget(day: _selectedDate, usuario: usuario),
                              const SizedBox(height: 15),
                              DailyTrainingsWidget(day: _selectedDate, usuario: usuario),
                              const SizedBox(height: 15),
                              dailySleepWidget(day: _selectedDate, usuario: usuario),
                              const SizedBox(height: 15),
                              DailyNutritionWidget(day: _selectedDate, usuario: usuario),
                              const SizedBox(height: 15),
                              dailyPhysicalWidget(),
                              const SizedBox(height: 15),
                              dailyHearthWidget(day: _selectedDate, usuario: usuario),
                              const SizedBox(height: 15),
                              dailyVitalsWidget(day: _selectedDate, usuario: usuario),
                              const SizedBox(height: 15),
                              StatisticsWidget(usuario: usuario),
                              const SizedBox(height: 30),
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
    );
  }
}
