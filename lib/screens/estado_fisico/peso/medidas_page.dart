import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/usuario_provider.dart';
import '../../../models/usuario/usuario.dart';
import '../../../widgets/chart/grafica.dart';

class MedidasPage extends ConsumerWidget {
  const MedidasPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.read(usuarioProvider);

    return Scaffold(
      body: FutureBuilder<Map<DateTime, double>>(
        future: usuario.getReadWeight(9999),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return const Center(child: Text('Error al cargar los datos'));
          }
          // Ordenamos los datos por fecha
          final sortedData = snapshot.data!.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
          // Convertimos a listas para ChartWidget
          final labels = sortedData.map((e) => e.key.toIso8601String()).toList();
          final values = sortedData.map((e) => e.value).toList();
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
              ),
              clipBehavior: Clip.hardEdge, // agregado para recortar el overflow
              child: ChartWidget(
                title: 'Pesaje',
                labels: labels,
                values: values,
                textNoResults: 'Aún no te has pesado.',
              ),
            ),
          );
        },
      ),
    );
  }
}
