import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../utils/colors.dart';
import '../../models/usuario/usuario.dart';
import '../../providers/usuario_provider.dart';

/// Física personalizada que aumenta el dragStartDistanceMotionThreshold.
/// Al subir 'dragThreshold', hay que arrastrar más para que la página cambie.
class CustomPageScrollPhysics extends PageScrollPhysics {
  final double dragThreshold;
  const CustomPageScrollPhysics({
    ScrollPhysics? parent,
    this.dragThreshold = 80.0, // Ajusta aquí
  }) : super(parent: parent);

  @override
  double get dragStartDistanceMotionThreshold => dragThreshold;

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomPageScrollPhysics(
      parent: buildParent(ancestor),
      dragThreshold: dragThreshold,
    );
  }
}

/// Widget para mostrar el encabezado del calendario con la fecha seleccionada y el botón "Ir a hoy"
class CalendarHeaderWidget extends StatelessWidget {
  final DateTime selectedDate;
  final GlobalKey<State<CalendarWidget>> calendarKey;
  final Function(DateTime) onDateChanged;

  const CalendarHeaderWidget({
    Key? key,
    required this.selectedDate,
    required this.calendarKey,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if selected date is in the current week
    final isInDifferentWeek = !CalendarWidget.isDateInCurrentWeek(selectedDate);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _formatDate(selectedDate),
              style: const TextStyle(color: AppColors.textColor, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
          if (isInDifferentWeek)
            TextButton(
              onPressed: () {
                CalendarWidget.jumpToToday(calendarKey);
                onDateChanged(DateTime.now());
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, // Elimina el padding
                minimumSize: Size.zero, // Elimina el tamaño mínimo
                tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduce el área de toque
              ),
              child: const Text(
                "Ir a hoy",
                style: TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  // Format the date as "Hoy", "Ayer", or the formatted date
  String _formatDate(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Hoy';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Ayer';
    } else {
      return DateFormat('EEEE, d \'de\' MMMM', 'es').format(date).replaceFirstMapped(RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase());
    }
  }
}

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

  // Static method to jump to today without requiring state access
  static void jumpToToday(GlobalKey<State<CalendarWidget>> key) {
    final state = key.currentState as _CalendarWidgetState?;
    if (state != null) {
      state.jumpToToday();
    }
  }

  // Add static method to check if a date is in the current week
  static bool isDateInCurrentWeek(DateTime date) {
    final today = DateTime.now();
    final startOfCurrentWeek = DateTime(today.year, today.month, today.day).subtract(Duration(days: today.weekday - 1));
    final endOfCurrentWeek = startOfCurrentWeek.add(const Duration(days: 6));

    return !(date.isBefore(startOfCurrentWeek) || date.isAfter(endOfCurrentWeek));
  }

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  int _stepsByDay = 0;
  Map<DateTime, double> _kcalBurned = {};
  int _targetSteps = 0;
  int _targetKcalBurned = 0;
  bool _hasStepsPermission = false;
  bool _hasKcalPermission = false;

  static const int _basePage = 10000;
  int _currentPage = _basePage; // inicializamos _currentPage aquí
  late DateTime _baseDate;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _baseDate = _getStartOfWeek(widget.selectedDate);
    // _currentPage ya fue inicializado, no es necesaria asignación adicional
    _pageController = PageController(initialPage: _basePage);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _getStartOfWeek(DateTime date) => date.subtract(Duration(days: date.weekday - 1));

  // Improved method to jump to today's week
  void jumpToToday() {
    final today = DateTime.now();
    setState(() {
      _baseDate = _getStartOfWeek(today);
      _currentPage = _basePage;
    });

    // Use animateToPage instead of jumpToPage for smoother transition
    _pageController.animateToPage(
      _basePage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    _loadData(_baseDate);
  }

  Future<void> _loadData([DateTime? weekStart]) async {
    final effectiveWeek = weekStart ?? _baseDate;
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

    _targetSteps = usuario.getTargetSteps();
    _targetKcalBurned = usuario.getTargetKcalBurned();

    if (stepsPermission) {
      final listStepsByDay = await usuario.getTotalSteps(startDate: effectiveWeek, nDays: 7);
      setState(() {
        _stepsByDay = listStepsByDay;
      });
    }

    if (kcalPermission) {
      final listKcalBurnedByDay = await usuario.getTotalCaloriesBurned(startDate: effectiveWeek, nDays: 7);
      setState(() {
        _kcalBurned = listKcalBurnedByDay;
      });
    }
  }

  double _getStepsProgress(DateTime date) {
    if (!_hasStepsPermission || _targetSteps == 0) return 0;
    final steps = _stepsByDay;
    double progress = steps / _targetSteps;
    return progress.clamp(0.0, 1.0);
  }

  double _getKcalProgress(DateTime date) {
    if (!_hasKcalPermission || _targetKcalBurned == 0) return 0;
    final dateKey = DateTime.parse(DateFormat('yyyy-MM-dd').format(date));
    final kcal = _kcalBurned[dateKey] ?? 0;
    double progress = kcal / _targetKcalBurned;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return SizedBox(
      height: 100,
      child: PageView.builder(
        controller: _pageController,
        // Aquí aplicamos la física personalizada
        physics: const CustomPageScrollPhysics(dragThreshold: 80.0),
        // Manejo de gestos: ignoramos la pulsación vertical
        dragStartBehavior: DragStartBehavior.down,
        onPageChanged: (page) {
          final diff = page - _currentPage;
          setState(() {
            _baseDate = _baseDate.add(Duration(days: diff * 7));
            _currentPage = page;
          });
          _loadData(_baseDate); // Carga los datos correspondientes a la nueva semana
        },
        itemBuilder: (context, index) {
          final diff = index - _currentPage;
          final weekStart = _baseDate.add(Duration(days: diff * 7));
          final weekDates = List.generate(7, (i) => weekStart.add(Duration(days: i)));

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weekDates.map((date) {
              final isToday = date.day == today.day && date.month == today.month && date.year == today.year;
              final isSelected = date.day == widget.selectedDate.day && date.month == widget.selectedDate.month && date.year == widget.selectedDate.year;
              final hasTrained = widget.diasEntrenados.any(
                (d) => d.day == date.day && d.month == date.month && d.year == date.year,
              );
              final isFuture = date.isAfter(today);

              return Expanded(
                // wrap each child in Expanded to prevent overflow
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () {
                      widget.onDateSelected(date);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Text(
                            // Ej: "Lun", "Mar", ...
                            DateFormat.E('es').format(date)[0].toUpperCase() + DateFormat.E('es').format(date).substring(1),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? isFuture
                                      ? AppColors.accentColor.withAlpha((0.8 * 255).toInt())
                                      : isToday
                                          ? AppColors.mutedAdvertencia
                                          : (hasTrained ? AppColors.accentColor : AppColors.textColor)
                                  : isFuture
                                      ? AppColors.appBarBackground.withAlpha((0.5 * 255).toInt())
                                      : isToday
                                          ? AppColors.mutedAdvertencia
                                          : (hasTrained ? AppColors.appBarBackground : AppColors.appBarBackground.withAlpha((0.5 * 255).toInt())),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 43,
                                height: 43,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.mutedAdvertencia
                                      : isToday
                                          ? AppColors.mutedAdvertencia
                                          : isFuture
                                              ? AppColors.cardBackground
                                              : (hasTrained ? AppColors.appBarBackground : AppColors.appBarBackground.withAlpha((0.5 * 255).toInt())),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: isFuture
                                    ? const SizedBox.shrink()
                                    : Icon(
                                        hasTrained
                                            ? Icons.check
                                            : isToday
                                                ? Icons.question_mark
                                                : Icons.close,
                                        color: hasTrained || (isToday && hasTrained)
                                            ? AppColors.whiteText
                                            : isToday
                                                ? AppColors.background
                                                : AppColors.mutedRed,
                                        size: 16,
                                      ),
                              ),
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
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              (isToday || isSelected) ? AppColors.background : AppColors.accentColor,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
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
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              (isToday || isSelected) ? AppColors.background : AppColors.advertencia,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat.d().format(date),
                            style: TextStyle(
                              fontSize: 14,
                              color: isToday ? AppColors.advertencia : AppColors.textColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
