import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mrfit/providers/usuario_provider.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/chart/grafica.dart';

class MedidasPage extends ConsumerWidget {
  const MedidasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.read(usuarioProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medidas"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      // SafeArea con padding horizontal para margen externo.
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          margin: const EdgeInsets.symmetric(horizontal: 12.0), // <- ahora aplicamos margen fuera
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // BASAL_METABOLIC_RATE destacado
              FutureBuilder<double>(
                future: usuario.getCurrentBasalMetabolicRate(9999),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || snapshot.data == null || snapshot.data == 0.0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.cardBackground,
                      elevation: 0, // Sin sombra
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_fire_department, color: AppColors.mutedAdvertencia, size: 28),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Metabolismo Basal',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.mutedAdvertencia,
                                          fontSize: 18,
                                        ),
                                  ),
                                ),
                                // Icono de información arriba a la derecha
                                Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.info_outline, color: AppColors.mutedAdvertencia, size: 24),
                                    tooltip: '¿Qué es el metabolismo basal?',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: AppColors.cardBackground,
                                          title: Text(
                                            '¿Qué es el metabolismo basal?',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  color: AppColors.mutedAdvertencia,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          content: Text(
                                            'El metabolismo basal (BMR) es la cantidad mínima de energía que tu cuerpo necesita para mantener las funciones vitales en reposo, como respirar, mantener la temperatura corporal, la circulación sanguínea y el funcionamiento de los órganos.\n\n'
                                            'Este valor representa las calorías que consumirías si permanecieras en reposo absoluto durante 24 horas.\n\n'
                                            'El BMR depende de factores como la edad, el sexo, el peso, la altura y la composición corporal.\n\n'
                                            'Conocer tu metabolismo basal es útil para planificar dietas, controlar el peso y ajustar rutinas de ejercicio, ya que te ayuda a entender cuánta energía necesitas diariamente solo para mantenerte vivo, sin contar la actividad física ni la digestión.',
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: AppColors.textMedium,
                                                ),
                                          ),
                                          actions: [
                                            TextButton(
                                              style: TextButton.styleFrom(
                                                foregroundColor: AppColors.accentColor,
                                              ),
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: const Text('Cerrar'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.data!.toStringAsFixed(0)} kcal/día',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.textMedium, fontSize: 20),
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
                    return const SizedBox.shrink();
                  }
                  final sortedData = snapshot.data!.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
                  if (sortedData.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: AppColors.cardBackground,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                          child: ChartWidget(
                            title: 'Peso',
                            labels: const [],
                            values: const [],
                            textNoResults: 'Aún no te has pesado.',
                          ),
                        ),
                      ),
                    );
                  }
                  final labels = sortedData.map((e) => e.key.toIso8601String()).toList();
                  final values = sortedData.map((e) => e.value).toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.cardBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                        child: ChartWidget(
                          title: 'Peso',
                          labels: labels,
                          values: values,
                          textNoResults: 'Aún no te has pesado.',
                        ),
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
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.cardBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                        child: ChartWidget(
                          title: 'Masa Muscular',
                          labels: labels,
                          values: values,
                          textNoResults: 'Sin datos de masa muscular.',
                        ),
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
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.cardBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                        child: ChartWidget(
                          title: 'Masa Magra',
                          labels: labels,
                          values: values,
                          textNoResults: 'Sin datos de masa magra.',
                        ),
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
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.cardBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                        child: ChartWidget(
                          title: 'Grasa Corporal (%)',
                          labels: labels,
                          values: values,
                          textNoResults: 'Sin datos de grasa corporal.',
                        ),
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
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.cardBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                        child: ChartWidget(
                          title: 'Índice de Masa Corporal (BMI)',
                          labels: labels,
                          values: values,
                          textNoResults: 'Sin datos de IMC.',
                        ),
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
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.cardBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                        child: ChartWidget(
                          title: 'Masa Muscular',
                          labels: labels,
                          values: values,
                          textNoResults: 'Sin datos de huesos.',
                        ),
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
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.cardBackground,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
                        child: ChartWidget(
                          title: 'Masa Muscular',
                          labels: labels,
                          values: values,
                          textNoResults: 'Sin datos de huesos.',
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
