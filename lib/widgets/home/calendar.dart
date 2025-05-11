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
import 'package:mrfit/widgets/chart/resumen_semanal_entrenamiento.dart';

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
  final Set<DateTime> diasEntrenados;

  const CalendarHeaderWidget({
    super.key,
    required this.selectedDate,
    required this.calendarKey,
    required this.onDateChanged,
    required this.diasEntrenados,
  });

  bool get _showGoToToday => !selectedDate.isToday;

  int get _trainedLast7Days {
    final today = DateTime.now();
    final from = today.subtract(const Duration(days: 6));
    return diasEntrenados.where((d) => !d.isAfter(today) && !d.isBefore(from)).length;
  }

  int get _trainedLast30Days {
    final today = DateTime.now();
    final from = today.subtract(const Duration(days: 29));
    return diasEntrenados.where((d) => !d.isAfter(today) && !d.isBefore(from)).length;
  }

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
            )
          else
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ResumenSemanalEntrenamientosWidget(
                    daysTrainedLast30Days: diasEntrenados.where((d) => !d.isAfter(DateTime.now()) && d.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length,
                    daysTrainedLast7Days: _trainedLast7Days,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    Text(
                      '${_trainedLast7Days}/7',
                      style: const TextStyle(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.fitness_center,
                      color: AppColors.mutedAdvertencia,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_trainedLast30Days}/30',
                      style: const TextStyle(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
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

  Map<String, Map<String, dynamic>> _daysValues = {};

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
    final usuario = ref.read(usuarioProvider);

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

    final start = weekStart ?? _baseDate;
    final today = DateTime.now();

    // 1) Cargo cache existente
    final cacheKey = 'diario_${start.year}';
    final raw = await CustomCache.getByKey(cacheKey);
    final Map<String, dynamic> cacheMap = raw != null ? jsonDecode(raw.value) as Map<String, dynamic> : {};

    // 2) Recojo datos día a día (cache o HealthConnect) y construyo daysValues
    final Map<String, Map<String, dynamic>> daysValues = {};
    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      // Si el día es futuro no devuelvo nada
      if (date.isAfter(today)) continue;
      final iso = date.toIso8601String().split('T').first;

      int steps = 0;
      double kcal = 0.0;
      int minAct = 0;

      if (cacheMap.containsKey(iso)) {
        print('Cache hit: $iso');
        final d = cacheMap[iso]!;
        steps = int.tryParse(d['steps'].toString()) ?? 0;
        kcal = double.tryParse(d['kcal'].toString()) ?? 0.0;
        minAct = int.tryParse(d['minAct'].toString()) ?? 0;
      } else {
        if (stepsPerm) steps = await usuario.getTotalStepsByDate(iso);
        if (kcalPerm) kcal = await usuario.getTotalCaloriesBurnedByDay(iso);
        if (activityPerm) minAct = await usuario.getTimeActivityByDate(iso);

        // cacheo solo días pasados con datos
        if (!date.isToday && date.isBefore(today) && (steps > 0 || kcal > 0 || minAct > 0)) {
          cacheMap[iso] = {
            'steps': steps.toString(),
            'kcal': kcal.toString(),
            'minAct': minAct.toString(),
          };
        }
      }

      daysValues[iso] = {
        'steps': steps,
        'kcal': kcal,
        'minAct': minAct,
      };
    }

    // 3) Actualizo cache si hay algo nuevo
    if (cacheMap.isNotEmpty) {
      await CustomCache.set(cacheKey, jsonEncode(cacheMap));
    }

    // 4) Guardo en el state
    setState(() {
      _hasStepsPermission = stepsPerm;
      _hasKcalPermission = kcalPerm;
      _hasActivityPermission = activityPerm;
      _targetSteps = usuario.objetivoPasosDiarios;
      _targetKcal = usuario.objetivoKcal;
      _targetActivityMinutes = usuario.objetivoTiempoEntrenamiento;
      _daysValues = daysValues;
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
                    final dateString = date.toIso8601String().split('T').first;
                    final trained = widget.diasEntrenados.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
                    return _DayCell(
                      date: date,
                      isSelected: date.year == widget.selectedDate.year && date.month == widget.selectedDate.month && date.day == widget.selectedDate.day,
                      isToday: date.isToday,
                      isFuture: date.isAfter(today),
                      hasTrained: trained,
                      stepsProgress: _hasStepsPermission ? _progress((_daysValues[dateString]?["steps"] as num? ?? 0).toDouble(), _targetSteps) : 0,
                      minutosPercent: _hasActivityPermission ? _progress((_daysValues[dateString]?["minAct"] as num? ?? 0).toDouble(), _targetActivityMinutes) : 0,
                      kcalProgress: _hasKcalPermission ? _progress((_daysValues[dateString]?["kcal"] as num? ?? 0).toDouble(), _targetKcal) : 0,
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
