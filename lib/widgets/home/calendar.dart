import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mrfit/widgets/chart/triple_ring_loader.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'dart:convert';
import 'package:mrfit/models/cache/custom_cache.dart';
import 'package:mrfit/channel/channel_healtconnect.dart';

// ---------------------------------------------
// Extensions
// ---------------------------------------------
extension DateTimeUtils on DateTime {
  bool get isToday => year == DateTime.now().year && month == DateTime.now().month && day == DateTime.now().day;

  bool get isYesterday => year == DateTime.now().subtract(const Duration(days: 1)).year && month == DateTime.now().subtract(const Duration(days: 1)).month && day == DateTime.now().subtract(const Duration(days: 1)).day;

  DateTime get startOfWeek => subtract(Duration(days: weekday - DateTime.monday));

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
  const CustomPageScrollPhysics({ScrollPhysics? parent, this.dragThreshold = 80}) : super(parent: parent);

  @override
  double get dragStartDistanceMotionThreshold => dragThreshold;

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) => CustomPageScrollPhysics(parent: buildParent(ancestor), dragThreshold: dragThreshold);
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
    super.key,
    required this.selectedDate,
    required this.calendarKey,
    required this.onDateChanged,
  });

  bool get _showGoToToday => !selectedDate.isToday && !CalendarWidget.isDateInCurrentWeek(selectedDate);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              selectedDate.formattedCalendarHeader('es'),
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_showGoToToday)
            TextButton(
              onPressed: () {
                CalendarWidget.jumpToToday(calendarKey);
                onDateChanged(DateTime.now());
              },
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
}

// ---------------------------------------------
// Calendar Widget
// ---------------------------------------------
class CalendarWidget extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Set<DateTime> diasEntrenados;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.diasEntrenados,
  });

  static void jumpToToday(GlobalKey key) => (key.currentState as _CalendarWidgetState?)?.jumpToToday();

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

  final PageController _pageController = PageController(initialPage: _basePage);
  DateTime _baseDate = DateTime.now().startOfWeek;
  int _currentPage = _basePage;

  bool _hasStepsPermission = false;
  bool _hasKcalPermission = false;
  bool _hasActivityPermission = false;

  Map<DateTime, int> _stepsByDay = {};
  Map<DateTime, double> _kcalBurned = {};
  Map<DateTime, int> _activityMinutes = {};

  int _targetSteps = 0;
  int _targetKcal = 0;
  int _targetActivityMinutes = 0;

  @override
  void initState() {
    super.initState();
    _baseDate = widget.selectedDate.startOfWeek;
    _loadData();
  }

  Future<void> _loadData([DateTime? weekStart]) async {
    final start = weekStart ?? _baseDate;

    // Check if the week is more than a month prior to the current date
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    if (start.isBefore(oneMonthAgo)) {
      Logger().w("CalendarWidget: Checking Health Data History permission...");
      final hasHealthDataHistoryPermission = await HealthConnectHelper.requestHealthDataPermission();
      Logger().w("CalendarWidget: Health Data History permission granted: $hasHealthDataHistoryPermission");
      if (!hasHealthDataHistoryPermission) {
        Logger().w('Permiso de Health Data History no concedido.');
        setState(() {
          _hasStepsPermission = false;
          _hasKcalPermission = false;
          _hasActivityPermission = false;
        });
        return;
      }
    }

    final usuario = ref.read(usuarioProvider);

    final cacheKey = 'diario_${start.year}';
    final cachedData = await CustomCache.getByKey(cacheKey);
    Map<String, dynamic> jsonData = {};

    if (cachedData != null) {
      jsonData = jsonDecode(cachedData.value);
    }

    final stepsPerm = await usuario.checkPermissionsFor('STEPS');
    final kcalPerm = await usuario.checkPermissionsFor('TOTAL_CALORIES_BURNED');
    final activityPerm = await usuario.checkPermissionsFor('WORKOUT');

    if (!stepsPerm && !kcalPerm && !activityPerm) {
      setState(() {
        _hasStepsPermission = false;
        _hasKcalPermission = false;
        _hasActivityPermission = false;
      });
      return;
    }

    final today = DateTime.now();
    final Map<DateTime, int> stepsLocal = {};
    final Map<DateTime, double> kcalLocal = {};
    final Map<DateTime, int> activityLocal = {};
    final Map<String, Map<String, dynamic>> newCacheEntries = {};

    for (int i = 0; i < 7; i++) {
      final currentDate = start.add(Duration(days: i));
      final iso = currentDate.toIso8601String().split('T').first;
      if (jsonData.containsKey(iso)) {
        final data = jsonData[iso]!;
        stepsLocal[currentDate] = int.tryParse(data['steps'].toString()) ?? 0;
        kcalLocal[currentDate] = double.tryParse(data['kcal'].toString()) ?? 0.0;
        activityLocal[currentDate] = int.tryParse(data['minAct'].toString()) ?? 0;
      } else {
        if (stepsPerm) {
          stepsLocal[currentDate] = await usuario.getTotalStepsByDate(iso);
        }
        if (kcalPerm) {
          kcalLocal[currentDate] = await usuario.getTotalCaloriesBurnedByDay(iso);
        }
        if (activityPerm) {
          activityLocal[currentDate] = await usuario.getTimeActivityByDate(iso);
        }
        // No cachear el día de hoy
        if (currentDate.year == today.year && currentDate.month == today.month && currentDate.day == today.day) {
          continue;
        }
        // Solo cachear datos pasados y si alguno de los valores > 0
        if (currentDate.isBefore(today)) {
          if ((stepsLocal[currentDate] ?? 0) > 0 || (kcalLocal[currentDate] ?? 0) > 0 || (activityLocal[currentDate] ?? 0) > 0) {
            newCacheEntries[iso] = {
              'steps': stepsLocal[currentDate]!.toString(),
              'kcal': kcalLocal[currentDate]!.toString(),
              'minAct': activityLocal[currentDate]!.toString(),
            };
          }
        }
      }
    }

    if (newCacheEntries.isNotEmpty) {
      final updated = {...jsonData, ...newCacheEntries};
      await CustomCache.set(cacheKey, jsonEncode(updated));
    }

    setState(() {
      _hasStepsPermission = stepsPerm;
      _hasKcalPermission = kcalPerm;
      _hasActivityPermission = activityPerm;
      _targetSteps = usuario.objetivoPasosDiarios;
      _targetKcal = usuario.objetivoKcal;
      _targetActivityMinutes = usuario.objetivoTiempoEntrenamiento;
      _stepsByDay = stepsLocal;
      _kcalBurned = kcalLocal;
      _activityMinutes = activityLocal;
    });
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

  double _progress(double v, int t) => t == 0 ? 0 : (v / t).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double topPad = 0;
        final double cellWidth = constraints.maxWidth / 7;
        final double aditionalHeight = 26;
        final double computedHeight = cellWidth + aditionalHeight + topPad;
        const double maxHeight = 85;
        final double height = computedHeight > maxHeight ? maxHeight : computedHeight;
        final today = DateTime.now();

        return SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.only(top: topPad),
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
                final days = List<DateTime>.generate(7, (i) => weekStart.add(Duration(days: i)));

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
                      stepsProgress: _hasStepsPermission ? _progress((_stepsByDay[date] ?? 0).toDouble(), _targetSteps) : 0,
                      minutosPercent: _hasActivityPermission ? _progress((_activityMinutes[date] ?? 0).toDouble(), _targetActivityMinutes) : 0,
                      kcalProgress: _hasKcalPermission ? _progress(_kcalBurned[date] ?? 0, _targetKcal) : 0,
                      onTap: () => widget.onDateSelected(date),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        );
      },
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
  final double minutosPercent;
  final double kcalProgress;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.hasTrained,
    required this.stepsProgress,
    required this.minutosPercent,
    required this.kcalProgress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, c) => SizedBox(
                width: c.maxWidth,
                height: c.maxWidth,
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.95,
                    heightFactor: 0.95,
                    child: CustomPaint(
                      painter: TripleRingLoaderPainter(
                        pasosPercent: stepsProgress,
                        minutosPercent: minutosPercent,
                        kcalPercent: kcalProgress,
                        trainedToday: hasTrained,
                        backgroundColorRing: AppColors.appBarBackground.withAlpha(100),
                        showNumberLap: false,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: _labelColor(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _labelColor() {
    if (isFuture) return AppColors.appBarBackground.withOpacity(0.5);
    if (isSelected) return AppColors.mutedAdvertencia;
    return AppColors.appBarBackground;
  }
}
