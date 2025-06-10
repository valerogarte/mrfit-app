import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/utils/colors.dart'; // Importa los colores personalizados

// Página de actividad: muestra el listado de pasos del día.
class ActividadPage extends ConsumerWidget {
  const ActividadPage({super.key});

  // Obtiene la fecha de hoy en formato yyyy-MM-dd
  String _getTodayString() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(now);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.read(usuarioProvider);
    final today = _getTodayString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pasos del día'),
        backgroundColor: AppColors.appBarBackground, // Color del AppBar
      ),
      backgroundColor: AppColors.background, // Fondo principal
      body: FutureBuilder<List<List<HealthDataPoint>>>(
        // Se ejecutan ambas llamadas en paralelo.
        future: Future.wait([
          usuario.getStepsByDate(today),
          (() async {
            // Se usa HealthFactory para obtener los datos crudos.
            final parsedDate = DateTime.parse(today);
            final start = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            final end = start.add(const Duration(days: 1));
            final health = Health();
            final dataPoints = await health.getHealthDataFromTypes(
              startTime: start,
              endTime: end,
              types: [HealthDataType.STEPS],
            );
            final dataPointsRaw = health.removeDuplicates(dataPoints);
            return dataPointsRaw;
          })(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Muestra un indicador de carga mientras se obtienen los datos
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            // Muestra un mensaje de error si ocurre algún problema
            return Center(
              child: Text(
                'Error al cargar los pasos',
                style: const TextStyle(color: AppColors.mutedRed),
              ),
            );
          }
          // Los resultados: [originalSteps, rawSteps]
          final originalSteps = snapshot.data?[0] ?? [];
          final rawSteps = snapshot.data?[1] ?? [];
          // Se ordena según fecha
          rawSteps.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));
          if (rawSteps.isEmpty) {
            return const Center(
              child: Text(
                'No hay pasos registrados hoy.',
                style: TextStyle(color: AppColors.mutedSilver),
              ),
            );
          }
          return ListView.builder(
            itemCount: rawSteps.length,
            itemBuilder: (context, index) {
              final paso = rawSteps[index];
              final horaInicio = "${DateFormat('HH:mm:ss').format(paso.dateFrom)}.${paso.dateFrom.millisecond.toString().padLeft(3, '0')}";
              final horaFin = "${DateFormat('HH:mm:ss').format(paso.dateTo)}.${paso.dateTo.millisecond.toString().padLeft(3, '0')}";
              final cantidad = paso.value is NumericHealthValue ? (paso.value as NumericHealthValue).numericValue.toInt() : 0;
              final sourceName = paso.sourceName ?? 'Desconocido';
              final diferencia = paso.dateTo.difference(paso.dateFrom).inMilliseconds; // Se agrega la declaración de diferencia
              // Calcula acumulados totales, válidos y por SourceName hasta este registro en rawSteps
              int acumuladoTotal = 0;
              int acumuladoValido = 0;
              int acumuladoSource = 0; // acumulado para registros de este sourceName
              for (int i = 0; i <= index; i++) {
                final p = rawSteps[i];
                final value = p.value is NumericHealthValue ? (p.value as NumericHealthValue).numericValue.toInt() : 0;
                acumuladoTotal += value;
                final isExtra = !originalSteps.any((s) => s.dateFrom.millisecondsSinceEpoch == p.dateFrom.millisecondsSinceEpoch && s.dateTo.millisecondsSinceEpoch == p.dateTo.millisecondsSinceEpoch && s.value.toString() == p.value.toString());
                if (!isExtra) {
                  acumuladoValido += value;
                }
                final pSourceName = p.sourceName ?? 'Desconocido';
                if (pSourceName == sourceName) {
                  acumuladoSource += value;
                }
              }
              // Determina si el registro es "extra" (no está en los pasos originales)
              final isExtra =
                  !originalSteps.any((s) => s.dateFrom.millisecondsSinceEpoch == paso.dateFrom.millisecondsSinceEpoch && s.dateTo.millisecondsSinceEpoch == paso.dateTo.millisecondsSinceEpoch && s.value.toString() == paso.value.toString());
              return Card(
                color: AppColors.cardBackground, // mismo fondo normal para todos
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
                      // Muestra horaInicio y diferencia en la misma línea
                      Row(
                        children: [
                          Text(
                            horaInicio,
                            style: const TextStyle(
                              color: AppColors.textNormal,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // const SizedBox(width: 8),
                          // Text(
                          //   '$diferencia ms',
                          //   style: const TextStyle(
                          //     color: AppColors.mutedGreen,
                          //     fontSize: 12,
                          //   ),
                          // ),
                        ],
                      ),
                      Text(
                        horaFin,
                        style: const TextStyle(
                          color: AppColors.textNormal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pasos: $cantidad', style: const TextStyle(color: AppColors.mutedGreen)),
                      Text(sourceName, style: const TextStyle(color: AppColors.mutedSilver)),
                    ],
                  ),
                  trailing: FittedBox(
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // evita que la columna se expanda verticalmente
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Acum. Total', style: TextStyle(fontSize: 11, color: AppColors.mutedSilver)),
                        Text(
                          '$acumuladoTotal',
                          style: const TextStyle(
                            color: AppColors.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Acum. Válido', style: TextStyle(fontSize: 11, color: AppColors.mutedSilver)),
                        Text(
                          '$acumuladoValido',
                          style: const TextStyle(
                            color: AppColors.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Acum. $sourceName', style: const TextStyle(fontSize: 11, color: AppColors.mutedSilver)),
                        Text(
                          '$acumuladoSource',
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
              );
            },
          );
        },
      ),
    );
  }
}
