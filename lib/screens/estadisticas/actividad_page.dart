import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:fl_chart/fl_chart.dart';

class ActividadPage extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  final bool showDataPoints; // Permite mostrar/ocultar detalles

  const ActividadPage({
    super.key,
    required this.selectedDate,
    this.showDataPoints = false, // Por defecto, no muestra detalles
  });

  @override
  _ActividadPageState createState() => _ActividadPageState();
}

class _ActividadPageState extends ConsumerState<ActividadPage> {
  int? selectedHour;

  String _getSelectedDateString() => DateFormat('yyyy-MM-dd').format(widget.selectedDate);

  @override
  Widget build(BuildContext context) {
    final usuario = ref.read(usuarioProvider);
    final dateString = _getSelectedDateString();
    final formattedDate = DateFormat('dd/MM/yyyy').format(widget.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Pasos del día: $formattedDate'),
        backgroundColor: AppColors.background,
      ),
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<List<HealthDataPoint>>>(
        future: Future.wait([
          usuario.getStepsByDate(dateString),
          (() async {
            final start = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
            final end = start.add(const Duration(days: 1));
            final health = Health();
            final dataPoints = await health.getHealthDataFromTypes(
              startTime: start,
              endTime: end,
              types: [HealthDataType.STEPS],
            );
            return health.removeDuplicates(dataPoints);
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
          final raw = snap.data![1]..sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

          if (raw.isEmpty) {
            return Center(
              child: Text(
                'No hay pasos registrados para el $formattedDate.',
                style: const TextStyle(color: AppColors.mutedSilver),
              ),
            );
          }

          // 1) Cuenta por hora (0–23)
          final hourlyCounts = List.generate(24, (_) => 0);
          for (var p in raw) hourlyCounts[p.dateFrom.hour]++;

          // 2) Filtra si hay hora seleccionada
          final display = selectedHour == null ? raw : raw.where((p) => p.dateFrom.hour == selectedHour).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      barTouchData: BarTouchData(
                        enabled: widget.showDataPoints, // Solo permite interacción si showDataPoints es true
                        touchCallback: widget.showDataPoints
                            ? (e, resp) {
                                if (resp != null && resp.spot != null) {
                                  setState(() => selectedHour = resp.spot!.touchedBarGroupIndex);
                                }
                              }
                            : null,
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final h = v.toInt(); // 0–23
                              // Muestra label si la hora es múltiplo de 6 o es la última (23)
                              if (h % 6 == 0 || h == 23) {
                                return Text(h.toString().padLeft(2, '0'));
                              }
                              return const SizedBox.shrink();
                            },
                            interval: 1,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: false, // Oculta todas las líneas de grid
                      ),
                      borderData: FlBorderData(
                        show: false, // Elimina el borde del gráfico
                      ),
                      barGroups: List.generate(24, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: hourlyCounts[i].toDouble(),
                              color: widget.showDataPoints && i == selectedHour ? AppColors.accentColor : AppColors.mutedGreen,
                              width: 14,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ),
              if (widget.showDataPoints) ...[
                if (selectedHour != null)
                  Column(
                    children: [
                      // Muestra el total de pasos de la hora seleccionada
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Pasos dados de ${selectedHour!.toString().padLeft(2, '0')}:00 a ${selectedHour!.toString().padLeft(2, '0')}:59 - '
                          '${display.fold<int>(0, (sum, paso) => sum + ((paso.value is NumericHealthValue) ? (paso.value as NumericHealthValue).numericValue.toInt() : 0))}',
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
                Expanded(
                  child: ListView.builder(
                    itemCount: display.length,
                    itemBuilder: (ctx, i) {
                      final paso = display[i];
                      final inicio = "${DateFormat('HH:mm:ss').format(paso.dateFrom)}.${paso.dateFrom.millisecond.toString().padLeft(3, '0')}";
                      final fin = "${DateFormat('HH:mm:ss').format(paso.dateTo)}.${paso.dateTo.millisecond.toString().padLeft(3, '0')}";
                      final cantidad = (paso.value is NumericHealthValue) ? (paso.value as NumericHealthValue).numericValue.toInt() : 0;
                      final src = paso.sourceName ?? 'Desconocido';

                      // Acumulados
                      int total = 0, valido = 0, srcAcum = 0;
                      for (var j = 0; j <= i; j++) {
                        final p = display[j];
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
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
