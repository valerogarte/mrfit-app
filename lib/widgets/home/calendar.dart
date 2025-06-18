import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/widgets/chart/triple_ring_loader.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/models/cache/custom_cache.dart';
import 'package:mrfit/widgets/chart/resumen_semanal_entrenamiento.dart';
import 'package:mrfit/models/health/health.dart';

class CalendarWidget extends ConsumerStatefulWidget {
  final Usuario usuario;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final Map<String, bool> grantedPermissions;

  const CalendarWidget({
    super.key,
    required this.usuario,
    required this.selectedDate,
    required this.onDateSelected,
    required this.grantedPermissions,
  });

  static void jumpToToday(GlobalKey key) => (key.currentState as _CalendarWidgetState?)?.jumpToToday();

  static bool isDateInCurrentWeek(DateTime date) {
    final start = DateTime.now().startOfWeek;
    final end = start.add(const Duration(days: 6));
    return !date.isBefore(start) && !date.isAfter(end);
  }

  @override
  CalendarWidgetStateBase createState() => _CalendarWidgetState();
}

// Clase base pública para exponer solo la API necesaria del estado.
abstract class CalendarWidgetStateBase extends ConsumerState<CalendarWidget> {
  void reloadCurrentWeek();
  void jumpToToday();
}

class _CalendarWidgetState extends CalendarWidgetStateBase {
  static const int _basePage = 10000;

  final PageController _pageController = PageController(initialPage: _basePage);
  DateTime _baseDate = DateTime.now().startOfWeek;
  int _currentPage = _basePage;

  Map<String, Map<String, dynamic>> _daysValues = {};

  int _targetSteps = 0;
  int _targetHorasActivo = 0;
  int _targetActivityMinutes = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_basePage);
      }
    });
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el día seleccionado cambia de semana, refresca la semana base y la página del calendario.
    if (!widget.selectedDate.startOfWeek.isAtSameMomentAs(_baseDate)) {
      _refresh(widget.selectedDate);
    }
    // Si los permisos han cambiado de vacío a no vacío, recarga los datos.
    else if (oldWidget.grantedPermissions.isEmpty && widget.grantedPermissions.isNotEmpty) {
      _loadData(_baseDate);
    }
  }

  /// Centraliza la lógica de refresco de semana y recarga de datos.
  void _refresh([DateTime? date]) {
    setState(() {
      if (date != null) _baseDate = date.startOfWeek;
      // Solo resetea la página si cambia la semana base.
      // No llama a jumpToPage si ya estamos en la página correcta.
      // _currentPage se actualiza en onPageChanged.
    });
    _loadData(_baseDate);
  }

  Future<void> _loadData([DateTime? weekStart]) async {
    final usuario = widget.usuario;

    if (!usuario.isHealthConnectAvailable) {
      return;
    }

    final stepsPerm = widget.grantedPermissions['STEPS'] ?? false;
    final activityPerm = widget.grantedPermissions['WORKOUT'] == true && widget.grantedPermissions['STEPS'] == true;

    if (!stepsPerm && !activityPerm) {
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
      int minEntrenando = 0;
      int horasAct = 0;

      if (cacheMap.containsKey(iso)) {
        final d = cacheMap[iso]!;
        steps = int.tryParse(d['steps'].toString()) ?? 0;
        minEntrenando = int.tryParse(d['minEntrenando'].toString()) ?? 0;
        horasAct = int.tryParse(d['horasAct'].toString()) ?? 0;
      } else {
        if (stepsPerm) {
          final healthDataType = usuario.healthDataTypesString['STEPS'];
          final workoutHC = usuario.healthDataTypesString['WORKOUT'];
          if (healthDataType != null && workoutHC != null) {
            // Rescato los STEPS
            final rawSteps = await usuario.readHealthDataByDate([healthDataType], date);
            final dataPointsSteps = HealthUtils.customRemoveDuplicates(rawSteps);
            // Rescato los WORKOUTS
            final dataPointsWorkout = await usuario.readHealthDataByDate([workoutHC], date);
            // Rescato los Entrenamientos MrFit
            final entrenamientosMrFit = await usuario.getActivityMrFit(date);

            steps = usuario.getTotalSteps(dataPointsSteps);

            minEntrenando = usuario.getTimeActivityByDateForCalendar(
              widget.grantedPermissions,
              dataPointsSteps,
              dataPointsWorkout,
              entrenamientosMrFit,
            );

            horasAct = usuario.getTotalHoursTimeUserActivity(
              steps: dataPointsSteps,
              entrenamientos: dataPointsWorkout,
              entrenamientosMrFit: entrenamientosMrFit,
            );
          }
        }

        // cacheo solo días pasados con datos
        if (!date.isToday && date.isBefore(today) && (steps > 0 || horasAct > 0 || minEntrenando > 0)) {
          cacheMap[iso] = {
            'steps': steps.toString(),
            'horasAct': horasAct.toString(),
            'minEntrenando': minEntrenando.toString(),
          };

          if (steps > 0) {
            await usuario.isRecord("STEPS", steps, date);
          }
          if (minEntrenando > 0) {
            await usuario.isRecord("WORKOUT", minEntrenando, date);
          }
          // Si el día es el de ayer
          if (date.isYesterday) {
            await usuario.fetchAndUpdateWeeklyStreaks();
          }
        }
      }

      daysValues[iso] = {
        'steps': steps,
        'horasAct': horasAct,
        'minEntrenando': minEntrenando,
      };
    }

    // 3) Actualizo cache si hay algo nuevo
    if (cacheMap.isNotEmpty) {
      await CustomCache.set(cacheKey, jsonEncode(cacheMap));
    }

    // 4) Guardo en el state
    setState(() {
      _targetSteps = usuario.objetivoPasosDiarios;
      _targetHorasActivo = usuario.objetivoTiempoActivo;
      _targetActivityMinutes = usuario.objetivoTiempoEntrenamiento;
      _daysValues = daysValues;
    });
  }

  @override
  void jumpToToday() {
    _refresh(DateTime.now());
  }

  @override
  void reloadCurrentWeek() {
    _refresh(_baseDate);
  }

  double _porcentajeAvance(double v, int t) => t == 0 ? 0 : (v / t).clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double topPad = 0;
        final double cellWidth = constraints.maxWidth / 7;
        const double aditionalHeight = 26;
        const double maxHeight = 85;
        final double computedHeight = cellWidth + aditionalHeight + topPad;
        final double height = computedHeight > maxHeight ? maxHeight : computedHeight;
        // Aplica tope al tamaño de la celda para el gráfico de rings
        final double cellSize = computedHeight > maxHeight ? maxHeight - aditionalHeight - topPad : cellWidth;
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
                if (diff != 0) {
                  final newBaseDate = _baseDate.add(Duration(days: diff * 7));
                  _currentPage = idx;
                  _refresh(newBaseDate);
                }
              },
              itemBuilder: (_, idx) {
                final weekStart = _baseDate.add(Duration(days: (idx - _currentPage) * 7));
                final days = List<DateTime>.generate(7, (i) => weekStart.add(Duration(days: i)));

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: days.map((date) {
                    final dateString = date.toIso8601String().split('T').first;
                    return RepaintBoundary(
                      child: SizedBox(
                        width: cellSize,
                        child: _DayCell(
                          date: date,
                          isSelected: date.year == widget.selectedDate.year && date.month == widget.selectedDate.month && date.day == widget.selectedDate.day,
                          isToday: date.isToday,
                          isFuture: date.isAfter(today),
                          hasTrained: false, // Siempre false, ya que se elimina la lógica de entrenamientos
                          stepsProgress: (widget.grantedPermissions['STEPS'] ?? false) ? _porcentajeAvance((_daysValues[dateString]?["steps"] as num? ?? 0).toDouble(), _targetSteps) : 0,
                          minutosEntrenandoPercent:
                              (widget.grantedPermissions['STEPS'] == true && widget.grantedPermissions['WORKOUT'] == true) ? _porcentajeAvance((_daysValues[dateString]?["minEntrenando"] as num? ?? 0).toDouble(), _targetActivityMinutes) : 0,
                          horasActivoPercent: (widget.grantedPermissions['STEPS'] == true && widget.grantedPermissions['WORKOUT'] == true) ? _porcentajeAvance((_daysValues[dateString]?["horasAct"] as num? ?? 0).toDouble(), _targetHorasActivo) : 0,
                          onTap: () {
                            if (!date.isAfter(DateTime.now())) {
                              widget.onDateSelected(date);
                            }
                          },
                          cellWidth: cellSize,
                        ),
                      ),
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
// Calendar Header
// ---------------------------------------------
typedef DateChangedCallback = void Function(DateTime);

class CalendarFooterWidget extends StatelessWidget {
  final Usuario usuario;
  final DateTime selectedDate;
  final DateChangedCallback onDateChanged;
  final Set<DateTime> diasEntrenados;
  final VoidCallback onJumpToToday;

  const CalendarFooterWidget({
    super.key,
    required this.usuario,
    required this.selectedDate,
    required this.onDateChanged,
    required this.diasEntrenados,
    required this.onJumpToToday,
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
              onPressed: onJumpToToday,
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
                    usuario: usuario,
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
                      '$_trainedLast7Days/7',
                      style: TextStyle(
                        color: _trainedLast7Days >= usuario.objetivoEntrenamientoSemanal ? AppColors.accentColor : AppColors.appBarBackground,
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
                      '$_trainedLast30Days/30',
                      style: TextStyle(
                        color: _trainedLast30Days >= ((usuario.objetivoEntrenamientoSemanal * 30) / 7).floor() ? AppColors.accentColor : AppColors.appBarBackground,
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
// Individual Day Cell
// ---------------------------------------------
class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final bool hasTrained;
  final double stepsProgress;
  final double minutosEntrenandoPercent;
  final double horasActivoPercent;
  final VoidCallback onTap;
  final double cellWidth;

  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.hasTrained,
    required this.stepsProgress,
    required this.minutosEntrenandoPercent,
    required this.horasActivoPercent,
    required this.onTap,
    required this.cellWidth,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: cellWidth,
            height: cellWidth,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: CustomPaint(
                painter: TripleRingLoaderPainter(
                  pasosPercent: stepsProgress,
                  minutosPercent: minutosEntrenandoPercent,
                  horasActivo: horasActivoPercent,
                  trainedToday: hasTrained,
                  backgroundColorRing: AppColors.cardBackground,
                  showNumberLap: false,
                ),
              ),
            ),
          ),
          Text(
            _getDayLabel(date),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: _labelColor(),
            ),
          ),
        ],
      ),
    );
  }

  /// Devuelve el número del día o las tres primeras letras del mes en español si es día 1.
  String _getDayLabel(DateTime date) {
    if (date.day == 1) {
      // Obtiene el nombre del mes en español y lo recorta a 3 letras.
      final mes = DateFormat.MMM('es').format(date);
      return mes.substring(0, 3).toLowerCase();
    }
    return '${date.day}';
  }

  Color _labelColor() {
    if (isFuture) return AppColors.appBarBackground.withAlpha(125);
    if (isSelected) return AppColors.mutedAdvertencia;
    return AppColors.appBarBackground;
  }
}

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

class CustomPageScrollPhysics extends PageScrollPhysics {
  final double dragThreshold;
  const CustomPageScrollPhysics({super.parent, this.dragThreshold = 80});

  @override
  double get dragStartDistanceMotionThreshold => dragThreshold;

  @override
  CustomPageScrollPhysics applyTo(ScrollPhysics? ancestor) => CustomPageScrollPhysics(parent: buildParent(ancestor), dragThreshold: dragThreshold);
}
