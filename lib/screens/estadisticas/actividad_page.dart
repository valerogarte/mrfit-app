import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/models/modelo_datos.dart';

class ActividadPage extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final bool showDataPoints;
  final List<HealthDataPoint> steps;
  final List<HealthDataPoint> entrenamientos;
  final List<Map<String, dynamic>> entrenamientosMrFit;

  const ActividadPage({
    super.key,
    required this.selectedDate,
    this.showDataPoints = true,
    required this.steps,
    required this.entrenamientos,
    required this.entrenamientosMrFit,
  });

  @override
  _ActividadPageState createState() => _ActividadPageState();
}

class _ActividadPageState extends ConsumerState<ActividadPage> {
  int? selectedHour;

  @override
  Widget build(BuildContext context) {
    // Formatea la fecha como "16 junio" en español para mayor claridad al usuario
    final formattedDate = DateFormat("d MMMM", "es_ES").format(widget.selectedDate);
    final usuario = ref.read(usuarioProvider); // Obtener usuario

    // Calcular horas activas usando la lógica de usuario
    final Map<DateTime, bool> horasActivas = usuario.getTimeUserActivity(
      steps: widget.steps,
      entrenamientos: widget.entrenamientos,
      entrenamientosMrFit: widget.entrenamientosMrFit,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Actividad del $formattedDate'),
        backgroundColor: AppColors.background,
      ),
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<List<HealthDataPoint>>>(
        future: Future.wait([
          Future.value(widget.steps),
          (() async {
            final start = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
            final end = start.add(const Duration(days: 1));
            final health = Health();
            final dataPoints = await health.getHealthDataFromTypes(
              startTime: start,
              endTime: end,
              types: [HealthDataType.STEPS],
            );
            final clean = health.removeDuplicates(dataPoints);
            clean.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
            return clean;
          })(),
        ]),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error al cargar los pasos',
                style: const TextStyle(color: AppColors.mutedRed),
              ),
            );
          }
          final original = snap.data![0];
          final raw = snap.data![1];

          if (raw.isEmpty) {
            return Center(
              child: Text(
                'No hay pasos registrados para el $formattedDate.',
                style: const TextStyle(color: AppColors.mutedSilver),
              ),
            );
          }

          // Filtrar solo los no “extra” (no borrados) para el gráfico
          final nonDeleted = raw.where((p) {
            return original.any((o) => o.dateFrom.millisecondsSinceEpoch == p.dateFrom.millisecondsSinceEpoch && o.dateTo.millisecondsSinceEpoch == p.dateTo.millisecondsSinceEpoch && o.value.toString() == p.value.toString());
          }).toList();

          // Calcula pasos válidos por hora (solo nonDeleted)
          final validHourlyCounts = List.generate(24, (_) => 0);
          for (var p in nonDeleted) {
            if (p.value is NumericHealthValue) {
              validHourlyCounts[p.dateFrom.hour] += (p.value as NumericHealthValue).numericValue.toInt();
            }
          }
          final maxValidSteps = validHourlyCounts.isNotEmpty ? validHourlyCounts.reduce((a, b) => a > b ? a : b) : 0;

          // 2) Filtra la vista detallada según hora
          final displaySteps = selectedHour == null ? raw : raw.where((p) => p.dateFrom.hour == selectedHour).toList();
          final displayEntrenamientos = selectedHour == null ? widget.entrenamientos : widget.entrenamientos.where((e) => e.dateFrom.hour == selectedHour).toList();
          final displayEntrenamientosMrFit = selectedHour == null ? widget.entrenamientosMrFit : widget.entrenamientosMrFit.where((e) => (e['start'] as DateTime).hour == selectedHour).toList();

          // Unifica todos los eventos para el listado
          final List<dynamic> display = [
            ...displaySteps.map((e) => {'type': 'step', 'data': e}),
            ...displayEntrenamientos.map((e) => {'type': 'entrenamiento', 'data': e}),
            ...displayEntrenamientosMrFit.map((e) => {'type': 'entrenamientoMrFit', 'data': e}),
          ];

          // Calcula pasos válidos en la hora seleccionada
          int validStepsInSelectedHour = 0;
          if (selectedHour != null) {
            validStepsInSelectedHour = nonDeleted.where((p) => p.dateFrom.hour == selectedHour).fold<int>(0, (sum, paso) => sum + ((paso.value is NumericHealthValue) ? (paso.value as NumericHealthValue).numericValue.toInt() : 0));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        enabled: widget.showDataPoints,
                        touchCallback: (e, resp) {
                          if (widget.showDataPoints && resp != null && resp.spot != null) {
                            setState(() => selectedHour = resp.spot!.touchedBarGroupIndex);
                          }
                        },
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final h = v.toInt();
                              if (h % 6 == 0 || h == 23) {
                                return Text(h.toString().padLeft(2, '0'));
                              }
                              return const SizedBox.shrink();
                            },
                            interval: 1,
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(24, (i) {
                        // Determina si la hora es activa según getTimeUserActivity
                        final hora = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day, i);
                        final isActive = horasActivas[hora] == true;
                        final normalized = maxValidSteps > 0 ? validHourlyCounts[i] / maxValidSteps * 100 : 0.0;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: normalized,
                              color: selectedHour != null && i == selectedHour ? AppColors.mutedAdvertencia : (isActive ? AppColors.mutedGreen : AppColors.cardBackground),
                              width: 14,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
              if (selectedHour != null && widget.showDataPoints)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        // Muestra solo pasos válidos en la hora seleccionada
                        'Pasos de ${selectedHour!.toString().padLeft(2, '0')}:00 a ${selectedHour!.toString().padLeft(2, '0')}:59 - $validStepsInSelectedHour',
                        style: const TextStyle(
                          color: AppColors.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => selectedHour = null),
                      child: const Text(
                        'Ver todas las horas',
                        style: TextStyle(color: AppColors.mutedAdvertencia),
                      ),
                    ),
                  ],
                ),
              if (widget.showDataPoints)
                Expanded(
                  child: ListView.builder(
                    itemCount: display.length,
                    itemBuilder: (ctx, i) {
                      final item = display[i];
                      if (item['type'] == 'step') {
                        final paso = item['data'] as HealthDataPoint;
                        final inicio = "${DateFormat('HH:mm:ss').format(paso.dateFrom)}.${paso.dateFrom.millisecond.toString().padLeft(3, '0')}";
                        final fin = "${DateFormat('HH:mm:ss').format(paso.dateTo)}.${paso.dateTo.millisecond.toString().padLeft(3, '0')}";
                        final cantidad = (paso.value is NumericHealthValue) ? (paso.value as NumericHealthValue).numericValue.toInt() : 0;
                        final src = paso.sourceName;

                        int total = 0, valido = 0, srcAcum = 0;
                        for (var j = 0; j <= i; j++) {
                          final pItem = display[j];
                          if (pItem['type'] != 'step') continue;
                          final p = pItem['data'] as HealthDataPoint;
                          final v = (p.value is NumericHealthValue) ? (p.value as NumericHealthValue).numericValue.toInt() : 0;
                          total += v;
                          final extra = !original.any((o) => o.dateFrom.millisecondsSinceEpoch == p.dateFrom.millisecondsSinceEpoch && o.dateTo.millisecondsSinceEpoch == p.dateTo.millisecondsSinceEpoch && o.value.toString() == p.value.toString());
                          if (!extra) valido += v;
                          if (p.sourceName == src) srcAcum += v;
                        }
                        final isExtra =
                            !original.any((o) => o.dateFrom.millisecondsSinceEpoch == paso.dateFrom.millisecondsSinceEpoch && o.dateTo.millisecondsSinceEpoch == paso.dateTo.millisecondsSinceEpoch && o.value.toString() == paso.value.toString());

                        final bg = src == "es.mrfit.app" ? AppColors.mutedGreen.withAlpha(100) : AppColors.cardBackground;

                        return Card(
                          color: bg,
                          shape: RoundedRectangleBorder(
                            side: isExtra ? const BorderSide(color: AppColors.mutedRed, width: 2) : BorderSide.none,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: Icon(Icons.directions_walk, color: AppColors.accentColor),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(inicio, style: const TextStyle(color: AppColors.textNormal, fontWeight: FontWeight.bold)),
                                Text(fin, style: const TextStyle(color: AppColors.textNormal, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pasos: $cantidad', style: const TextStyle(color: AppColors.mutedGreen)),
                                Text(src, style: const TextStyle(color: AppColors.mutedSilver)),
                              ],
                            ),
                            trailing: FittedBox(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Acum. Total', style: TextStyle(fontSize: 11, color: AppColors.mutedSilver)),
                                  Text('$total', style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  const Text('Acum. Válido', style: TextStyle(fontSize: 11, color: AppColors.mutedSilver)),
                                  Text('$valido', style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('Acum. $src', style: const TextStyle(fontSize: 11, color: AppColors.mutedSilver)),
                                  Text('$srcAcum', style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else if (item['type'] == 'entrenamiento') {
                        final entrenamiento = item['data'] as HealthDataPoint;
                        final inicio = DateFormat('HH:mm').format(entrenamiento.dateFrom);
                        final fin = DateFormat('HH:mm').format(entrenamiento.dateTo);
                        String tipo = 'Entrenamiento';
                        IconData icono = Icons.fitness_center;
                        Color color = AppColors.mutedAdvertencia;
                        if (entrenamiento.value is WorkoutHealthValue) {
                          final activityType = (entrenamiento.value as WorkoutHealthValue).workoutActivityType.toString();
                          final details = ModeloDatos().getActivityTypeDetails(activityType);
                          icono = details['icon'] as IconData? ?? Icons.fitness_center;
                          tipo = details['nombre'] as String? ?? activityType;
                        }
                        return Card(
                          color: color.withAlpha(60),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            leading: Icon(icono, color: color),
                            title: Text('Entrenamiento ($tipo)', style: const TextStyle(color: AppColors.textNormal, fontWeight: FontWeight.bold)),
                            subtitle: Text('De $inicio a $fin', style: const TextStyle(color: AppColors.textNormal)),
                          ),
                        );
                      } else if (item['type'] == 'entrenamientoMrFit') {
                        final entrenamiento = item['data'] as Map<String, dynamic>;
                        final inicio = DateFormat('HH:mm').format(entrenamiento['start'] as DateTime);
                        final fin = DateFormat('HH:mm').format(entrenamiento['end'] as DateTime);
                        final titulo = entrenamiento['title'] ?? 'Entrenamiento MrFit';
                        String tipo = 'MrFit';
                        IconData icono = Icons.fitness_center;
                        Color color = AppColors.mutedGreen;
                        if (entrenamiento.containsKey('activityType')) {
                          final details = ModeloDatos().getActivityTypeDetails(entrenamiento['activityType'] as String);
                          icono = details['icon'] as IconData? ?? Icons.fitness_center;
                          tipo = details['nombre'] as String? ?? 'MrFit';
                        }
                        return Card(
                          color: color.withAlpha(60),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: ListTile(
                            leading: Icon(icono, color: color),
                            title: Text('$titulo ($tipo)', style: const TextStyle(color: AppColors.textNormal, fontWeight: FontWeight.bold)),
                            subtitle: Text('De $inicio a $fin', style: const TextStyle(color: AppColors.textNormal)),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
