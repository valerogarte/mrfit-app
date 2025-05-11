import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/widgets/chart/grafica.dart';

class MedidasPage extends ConsumerWidget {
  const MedidasPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.read(usuarioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medidas"), // Title "Medidas"
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back arrow
          onPressed: () {
            Navigator.pop(context); // Navigate back
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // BASAL_METABOLIC_RATE destacado
          FutureBuilder<double>(
            future: usuario.getCurrentBasalMetabolicRate(9999),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null || snapshot.data == 0.0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Card(
                    color: Colors.red[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    child: const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No hay datos de metabolismo basal.',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Card(
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Metabolismo Basal [BASAL_METABOLIC_RATE]',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.data!.toStringAsFixed(0)} kcal/día',
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Energía que tu cuerpo consume en reposo cada día.',
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Peso
          FutureBuilder<Map<DateTime, double>>(
            future: usuario.getReadWeight(9999),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const Center(child: Text('Error al cargar los datos'));
              }
              final sortedData = snapshot.data!.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
              if (sortedData.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: ChartWidget(
                      title: 'Pesaje',
                      labels: const [],
                      values: const [],
                      textNoResults: 'Aún no te has pesado.',
                    ),
                  ),
                );
              }
              final labels = sortedData.map((e) => e.key.toIso8601String()).toList();
              final values = sortedData.map((e) => e.value).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.hardEdge,
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
          // Masa muscular
          FutureBuilder<Map<DateTime, double>>(
            future: usuario.getReadMuscleMass(9999),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final sortedData = snapshot.data!.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
              if (sortedData.isEmpty) return const SizedBox.shrink();
              final labels = sortedData.map((e) => e.key.toIso8601String()).toList();
              final values = sortedData.map((e) => e.value).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ChartWidget(
                    title: 'Masa Muscular',
                    labels: labels,
                    values: values,
                    textNoResults: 'Sin datos de masa muscular.',
                  ),
                ),
              );
            },
          ),
          // Masa magra
          FutureBuilder<Map<DateTime, double>>(
            future: usuario.getReadLeanBodyMass(9999),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final sortedData = snapshot.data!.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
              if (sortedData.isEmpty) return const SizedBox.shrink();
              final labels = sortedData.map((e) => e.key.toIso8601String()).toList();
              final values = sortedData.map((e) => e.value).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ChartWidget(
                    title: 'Masa Magra [LEAN_BODY_MASS]',
                    labels: labels,
                    values: values,
                    textNoResults: 'Sin datos de masa magra.',
                  ),
                ),
              );
            },
          ),
          // Grasa corporal
          FutureBuilder<Map<DateTime, double>>(
            future: usuario.getReadBodyFat(9999),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final sortedData = snapshot.data!.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
              if (sortedData.isEmpty) return const SizedBox.shrink();
              final labels = sortedData.map((e) => e.key.toIso8601String()).toList();
              final values = sortedData.map((e) => e.value).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ChartWidget(
                    title: 'Grasa Corporal (%) [BODY_FAT]',
                    labels: labels,
                    values: values,
                    textNoResults: 'Sin datos de grasa corporal.',
                  ),
                ),
              );
            },
          ),
          // BMI
          FutureBuilder<Map<DateTime, double>>(
            future: usuario.getReadBMI(9999),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final sortedData = snapshot.data!.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
              if (sortedData.isEmpty) return const SizedBox.shrink();
              final labels = sortedData.map((e) => e.key.toIso8601String()).toList();
              final values = sortedData.map((e) => e.value).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ChartWidget(
                    title: 'Índice de Masa Corporal (BMI) [BODY_MASS_INDEX]',
                    labels: labels,
                    values: values,
                    textNoResults: 'Sin datos de IMC.',
                  ),
                ),
              );
            },
          ),
          FutureBuilder<Map<DateTime, double>>(
            future: usuario.getReadBodyBone(9999),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final sortedData = snapshot.data!.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
              if (sortedData.isEmpty) return const SizedBox.shrink();
              final labels = sortedData.map((e) => e.key.toIso8601String()).toList();
              final values = sortedData.map((e) => e.value).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ChartWidget(
                    title: 'Masa Muscular',
                    labels: labels,
                    values: values,
                    textNoResults: 'Sin datos de huesos.',
                  ),
                ),
              );
            },
          ),
          FutureBuilder<Map<DateTime, double>>(
            future: usuario.getReadBodyWater(9999),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return const SizedBox.shrink();
              }
              final sortedData = snapshot.data!.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
              if (sortedData.isEmpty) return const SizedBox.shrink();
              final labels = sortedData.map((e) => e.key.toIso8601String()).toList();
              final values = sortedData.map((e) => e.value).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ChartWidget(
                    title: 'Masa Muscular',
                    labels: labels,
                    values: values,
                    textNoResults: 'Sin datos de huesos.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
