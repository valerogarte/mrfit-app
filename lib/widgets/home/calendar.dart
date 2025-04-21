import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import '../../utils/colors.dart';
import '../../models/usuario/usuario.dart';
import '../../providers/usuario_provider.dart';

// ---------------------------------------------
// Extensions
// ---------------------------------------------
extension DateTimeUtils on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }

  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - DateTime.monday));
  }

  String formattedCalendarHeader(String locale) {
    if (isToday) return 'Hoy';
    if (isYesterday) return 'Ayer';
    final formatted = DateFormat("EEEE, d 'de' MMMM", locale).format(this);
    return formatted.replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase());
  }
}

// ---------------------------------------------
// Custom Scroll Physics
// ---------------------------------------------
class CustomPageScrollPhysics extends PageScrollPhysics {
  final double dragThreshold;

  const CustomPageScrollPhysics({
    ScrollPhysics? parent,
    this.dragThreshold = 80.0,
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

// ---------------------------------------------
// Calendar Header
// ---------------------------------------------
typedef DateChangedCallback = void Function(DateTime);

class CalendarHeaderWidget extends StatelessWidget {
  final DateTime selectedDate;
  final GlobalKey<State<CalendarWidget>> calendarKey;
  final DateChangedCallback onDateChanged;

  const CalendarHeaderWidget({
    Key? key,
    required this.selectedDate,
    required this.calendarKey,
    required this.onDateChanged,
  }) : super(key: key);

  bool get _showGoToToday => !selectedDate.isToday && !CalendarWidget.isDateInCurrentWeek(selectedDate);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              selectedDate.formattedCalendarHeader('es'),
              style: const TextStyle(
                color: AppColors.textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_showGoToToday)
            TextButton(
              onPressed: _goToToday,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Ir a hoy',
                style: TextStyle(
                  color: AppColors.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _goToToday() {
    CalendarWidget.jumpToToday(calendarKey);
    onDateChanged(DateTime.now());
  }
}

// ---------------------------------------------
// Calendar Widget
// ---------------------------------------------
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

  static void jumpToToday(GlobalKey<State<CalendarWidget>> key) {
    final state = key.currentState as _CalendarWidgetState?;
    state?.jumpToToday();
  }

  static bool isDateInCurrentWeek(DateTime date) {
    final start = DateTime.now().startOfWeek;
    final end = start.add(const Duration(days: 6));
    return !date.isBefore(start) && !date.isAfter(end);
  }

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  static const int _basePage = 10000;

  late final PageController _pageController;
  late DateTime _baseDate;
  int _currentPage = _basePage;

  bool _hasStepsPermission = false;
  bool _hasKcalPermission = false;

  Map<DateTime, int> _stepsByDay = {};
  Map<DateTime, double> _kcalBurned = {};

  int _targetSteps = 0;
  int _targetKcal = 0;

  @override
  void initState() {
    super.initState();
    _baseDate = widget.selectedDate.startOfWeek;
    _pageController = PageController(initialPage: _basePage);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData([DateTime? weekStart]) async {
    final start = weekStart ?? _baseDate;
    final usuario = ref.read(usuarioProvider);

    final stepsPerm = await usuario.checkPermissionsFor('STEPS');
    final kcalPerm = await usuario.checkPermissionsFor('TOTAL_CALORIES_BURNED');

    if (!stepsPerm && !kcalPerm) {
      Logger().w('Permisos de Health Connect no concedidos.');
      setState(() => _hasStepsPermission = _hasKcalPermission = false);
      return;
    }

    setState(() {
      _hasStepsPermission = stepsPerm;
      _hasKcalPermission = kcalPerm;
    });

    _targetSteps = usuario.getTargetSteps();
    _targetKcal = usuario.getTargetKcalBurned();

    if (stepsPerm) {
      print("Cargando PASOS para la fecha: $start");
      final stepsMapString = await usuario.getStepsByDateMap(start.toIso8601String(), nDays: 7);
      final Map<DateTime, int> steps = {};
      stepsMapString.forEach((key, value) {
        steps[DateTime.parse(key)] = value;
      });
      setState(() => _stepsByDay = steps);
    }
    if (kcalPerm) {
      print("Cargando KCAL para la fecha: $start");
      final kcals = await usuario.getTotalCaloriesBurnedByDayMap(start.toIso8601String(), nDays: 7);
      final Map<DateTime, double> kcalsMap = {};
      kcals.forEach((key, value) {
        kcalsMap[DateTime.parse(key)] = value;
      });
      setState(() => _kcalBurned = kcalsMap);
    }
  }

  void jumpToToday() {
    final today = DateTime.now();
    setState(() {
      _baseDate = today.startOfWeek;
      _currentPage = _basePage;
    });
    _pageController.animateToPage(
      _basePage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _loadData(_baseDate);
  }

  double _progress(double value, int target) {
    if (target == 0) return 0.0;
    return (value / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: 100,
      child: PageView.builder(
        controller: _pageController,
        physics: const CustomPageScrollPhysics(),
        dragStartBehavior: DragStartBehavior.down,
        onPageChanged: (idx) {
          final diff = idx - _currentPage;
          setState(() {
            _baseDate = _baseDate.add(Duration(days: diff * 7));
            _currentPage = idx;
          });
          _loadData(_baseDate);
        },
        itemBuilder: (_, idx) {
          final weekStart = _baseDate.add(Duration(days: (idx - _currentPage) * 7));
          final days = List<DateTime>.generate(
            7,
            (i) => weekStart.add(Duration(days: i)),
          );
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: days.map((date) {
              final trained = widget.diasEntrenados.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
              return _DayCell(
                date: date,
                isSelected: date.year == widget.selectedDate.year && date.month == widget.selectedDate.month && date.day == widget.selectedDate.day,
                isToday: date.isToday,
                isFuture: date.isAfter(today),
                hasTrained: trained,
                stepsProgress: _hasStepsPermission ? _progress((_stepsByDay[DateTime(date.year, date.month, date.day)] ?? 0).toDouble(), _targetSteps) : 0,
                kcalProgress: _hasKcalPermission ? _progress(_kcalBurned[DateTime(date.year, date.month, date.day)] ?? 0, _targetKcal) : 0,
                onTap: () => widget.onDateSelected(date),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------
// Individual Day Cell
// ---------------------------------------------
class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final bool hasTrained;
  final double stepsProgress;
  final double kcalProgress;
  final VoidCallback onTap;

  const _DayCell({
    Key? key,
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.hasTrained,
    required this.stepsProgress,
    required this.kcalProgress,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat.E('es').format(date);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _labelColor(),
              ),
            ),
            const SizedBox(height: 4),
            Stack(
              alignment: Alignment.center,
              children: [
                _statusCircle(),
                if (!isFuture) _statusIcon(),
                if (_showProgress)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: stepsProgress,
                      strokeWidth: 2,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        isSelected || isToday ? AppColors.background : AppColors.accentColor,
                      ),
                    ),
                  ),
                if (_showProgress)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      value: kcalProgress,
                      strokeWidth: 2,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        isSelected || isToday ? AppColors.background : AppColors.advertencia,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isToday ? AppColors.advertencia : AppColors.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _showProgress => stepsProgress > 0 || kcalProgress > 0;

  Color _labelColor() {
    if (isSelected) {
      if (isFuture) return AppColors.accentColor.withOpacity(0.8);
      return isToday ? AppColors.mutedAdvertencia : (hasTrained ? AppColors.accentColor : AppColors.textColor);
    }
    if (isFuture) return AppColors.appBarBackground.withOpacity(0.5);
    if (isToday) return AppColors.mutedAdvertencia;
    return hasTrained ? AppColors.appBarBackground : AppColors.appBarBackground.withOpacity(0.5);
  }

  Widget _statusCircle() {
    final bgColor = isSelected || isToday
        ? AppColors.mutedAdvertencia
        : isFuture
            ? AppColors.cardBackground
            : (hasTrained ? AppColors.appBarBackground : AppColors.appBarBackground.withOpacity(0.5));
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _statusIcon() {
    IconData icon;
    Color color;
    if (hasTrained) {
      icon = Icons.check;
      color = AppColors.whiteText;
    } else if (isToday) {
      icon = Icons.question_mark;
      color = AppColors.background;
    } else {
      icon = Icons.close;
      color = AppColors.mutedRed;
    }
    return Icon(icon, size: 16, color: color);
  }
}
