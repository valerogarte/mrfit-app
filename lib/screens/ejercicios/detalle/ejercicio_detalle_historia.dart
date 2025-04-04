import 'package:flutter/material.dart';
import 'package:mrfit/models/entrenamiento/serie_realizada.dart';
import '../../../models/ejercicio/ejercicio.dart';
import '../../../utils/colors.dart';
import '../../../widgets/entrenamiento/entrenamiento_resumen_series.dart';
import '../../../widgets/not_found/not_found.dart';

class EjercicioHistoria extends StatelessWidget {
  final Ejercicio ejercicio;

  const EjercicioHistoria({Key? key, required this.ejercicio}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<int, Map<String, dynamic>>>(
      future: ejercicio.getSeriesByEjercicio(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final seriesGrouped = snapshot.data!;
        if (seriesGrouped.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: NotFoundData(
              title: 'Sin datos de historia',
              textNoResults: 'Cuando realices este ejercicio se mostrarán los datos.',
            ),
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Iteramos solo los últimos 2 grupos de entrenamiento
              ...seriesGrouped.entries.toList().reversed.take(50).map((entry) {
                final inicio = entry.value['inicio'];
                final series = entry.value['series'] as List<SerieRealizada>;
                // Nuevo bloque para calcular y formatear la diferencia de tiempo
                final inicioDate = DateTime.parse(inicio);
                final now = DateTime.now();
                final diff = now.difference(inicioDate);
                final years = diff.inDays ~/ 365;
                final months = (diff.inDays % 365) ~/ 30;
                final days = (diff.inDays % 365) % 30;
                final hours = diff.inHours % 24;
                final components = [
                  if (years > 0) '$years ${years == 1 ? "año" : "años"}',
                  if (months > 0) '$months ${months == 1 ? "mes" : "meses"}',
                  if (days > 0) '$days ${days == 1 ? "día" : "días"}',
                  if (hours > 0) '$hours ${hours == 1 ? "hora" : "horas"}'
                ];
                final displayComponents = components.take(2).toList();
                final timeText = displayComponents.isNotEmpty ? 'Hace ${displayComponents.join(" ")}' : 'Recientemente';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeText,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      // Mostrar detalles de cada serie con el formato requerido, modificando el índice para encapsularlo en un círculo
                      ...series.asMap().entries.map<Widget>((entry) {
                        final index = entry.key;
                        final serie = entry.value;
                        return ResumenSerie(index: index, serie: serie);
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
