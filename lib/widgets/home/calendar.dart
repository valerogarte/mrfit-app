import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../utils/colors.dart';
import '../../models/usuario/usuario.dart';
import '../../providers/usuario_provider.dart';

class CalendarWidget extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<DateTime> diasEntrenados;

  const CalendarWidget({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.diasEntrenados,
  }) : super(key: key);

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  Map<DateTime, int> _stepsByDay = {};
  Map<DateTime, double> _kcalBurned = {};
  int _targetSteps = 0;
  int _targetKcalBurned = 0;
  bool _hasStepsPermission = false;
  bool _hasKcalPermission = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Separa la carga de datos y la verificación de permisos
  Future<void> _loadData() async {
    final usuario = ref.read(usuarioProvider);

    final stepsPermission = await usuario.checkPermissionsFor("STEPS");
    final kcalPermission = await usuario.checkPermissionsFor("TOTAL_CALORIES_BURNED");

    setState(() {
      _hasStepsPermission = stepsPermission;
      _hasKcalPermission = kcalPermission;
    });

    if (!stepsPermission && !kcalPermission) {
      Logger().w('No se han concedido los permisos con Health Connect.');
      return;
    }

    // Obtener los targets para steps y kcal
    _targetSteps = usuario.getTargetSteps();
    _targetKcalBurned = usuario.getTargetKcalBurned();

    // Cargar datos de steps si se tiene permiso
    if (stepsPermission) {
      final listStepsByDay = await usuario.getReadSteps(7);
      setState(() {
        _stepsByDay = listStepsByDay;
      });
    }

    // Cargar datos de kcal si se tiene permiso
    if (kcalPermission) {
      final listKcalBurnedByDay = await usuario.getTotalCaloriesActivityBurned(7);
      setState(() {
        _kcalBurned = listKcalBurnedByDay;
      });
    }
  }

  // Calcula el progreso para steps
  double _getStepsProgress(DateTime date) {
    if (!_hasStepsPermission || _targetSteps == 0) return 0;
    final dateKey = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
    final steps = _stepsByDay[dateKey] ?? 0;
    double progress = steps / _targetSteps;
    return progress.clamp(0.0, 1.0);
  }

  // Calcula el progreso para kcal
  double _getKcalProgress(DateTime date) {
    if (!_hasKcalPermission || _targetKcalBurned == 0) return 0;
    final dateKey = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
    final kcal = _kcalBurned[dateKey] ?? 0;
    double progress = kcal / _targetKcalBurned;
    return progress.clamp(0.0, 1.0);
  }

  // Obtiene el inicio de la semana
  DateTime _getStartOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));

  // Genera la lista de fechas de la semana actual
  List<DateTime> _getCurrentWeekDates() {
    final today = DateTime.now();
    final startOfWeek = _getStartOfWeek(today);
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getCurrentWeekDates();
    final today = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDates.map((date) {
        final isToday = date.day == today.day && date.month == today.month && date.year == today.year;
        final isSelected = date.day == widget.selectedDate.day && date.month == widget.selectedDate.month && date.year == widget.selectedDate.year;
        final hasTrained = widget.diasEntrenados.any((d) => d.day == date.day && d.month == date.month && d.year == date.year);
        final isFuture = date.isAfter(today);

        return Expanded(
          child: GestureDetector(
            onTap: () => widget.onDateSelected(date),
            child: Column(
              children: [
                Text(
                  DateFormat.E('es').format(date)[0].toUpperCase() + DateFormat.E('es').format(date).substring(1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? isFuture
                            ? AppColors.accentColor.withAlpha((0.8 * 255).toInt())
                            : isToday
                                ? (hasTrained ? AppColors.accentColor : AppColors.appBarBackground.withAlpha((0.5 * 255).toInt()))
                                : (hasTrained ? AppColors.accentColor : AppColors.appBarBackground.withAlpha((0.5 * 255).toInt()))
                        : isFuture
                            ? AppColors.accentColor.withAlpha((0.8 * 255).toInt())
                            : isToday
                                ? (hasTrained ? AppColors.appBarBackground : AppColors.appBarBackground.withAlpha((0.5 * 255).toInt()))
                                : (hasTrained ? AppColors.appBarBackground : AppColors.appBarBackground.withAlpha((0.5 * 255).toInt())),
                  ),
                ),
                const SizedBox(height: 2),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Contenedor principal
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? isFuture
                                ? AppColors.accentColor.withAlpha((0.5 * 255).toInt())
                                : isToday
                                    ? (hasTrained ? AppColors.appBarBackground : AppColors.appBarBackground.withAlpha((0.5 * 255).toInt()))
                                    : (hasTrained ? AppColors.appBarBackground : AppColors.appBarBackground.withAlpha((0.5 * 255).toInt()))
                            : isFuture
                                ? AppColors.cardBackground
                                : isToday
                                    ? (hasTrained ? AppColors.appBarBackground : AppColors.appBarBackground.withAlpha((0.5 * 255).toInt()))
                                    : (hasTrained ? AppColors.appBarBackground : AppColors.appBarBackground.withAlpha((0.5 * 255).toInt())),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: isFuture
                          ? Text(
                              DateFormat.d().format(date),
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? AppColors.whiteText : AppColors.textColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            )
                          : Icon(
                              hasTrained
                                  ? Icons.check
                                  : isToday
                                      ? Icons.question_mark
                                      : Icons.close,
                              color: hasTrained || (isToday && hasTrained)
                                  ? AppColors.whiteText
                                  : isToday
                                      ? AppColors.advertencia
                                      : AppColors.mutedRed,
                              size: 16,
                            ),
                    ),
                    // Loader para Steps
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: _hasStepsPermission
                            ? TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: _getStepsProgress(date)),
                                duration: const Duration(milliseconds: 800),
                                builder: (context, value, child) => CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 2,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentColor),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                    // Loader para Kcal
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: _hasKcalPermission
                            ? TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: _getKcalProgress(date)),
                                duration: const Duration(milliseconds: 800),
                                builder: (context, value, child) => CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 2,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.mutedAdvertencia),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
