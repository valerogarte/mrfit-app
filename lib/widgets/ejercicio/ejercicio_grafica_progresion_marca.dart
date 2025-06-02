import 'package:flutter/material.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/chart/grafica.dart';

class EjercicioGraficaProgresionMarca extends StatefulWidget {
  final Ejercicio ejercicio;

  const EjercicioGraficaProgresionMarca({super.key, required this.ejercicio});

  @override
  State<EjercicioGraficaProgresionMarca> createState() => _EjercicioGraficaProgresionMarcaState();
}

class _EjercicioGraficaProgresionMarcaState extends State<EjercicioGraficaProgresionMarca> {
  int selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  // List size matches the number of charts (4)
  final List<GlobalKey> _chipKeys = List.generate(4, (_) => GlobalKey());

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: widget.ejercicio.getProgressionRecords(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final progression = snapshot.data!;
        final fechas = progression.keys.toList()..sort();

        List<String> labels = fechas;
        List<double> rmData = [];
        List<double> maxRepsData = [];
        List<double> pesoMaximoData = [];
        List<double> volumenMaximoData = [];

        for (final fin in fechas) {
          final record = progression[fin]!;
          rmData.add(record['rm'] as double);
          maxRepsData.add((record['maxReps'] as num).toDouble());
          pesoMaximoData.add(record['pesoMaximo'] as double);
          volumenMaximoData.add(record['volumenMaximo'] as double);
        }

        // Lista de gráficos disponibles
        final charts = [
          if (rmData.any((value) => value > 0.0)) {'title': 'RM', 'values': rmData},
          if (maxRepsData.any((value) => value > 0.0)) {'title': 'Máx Reps', 'values': maxRepsData},
          if (pesoMaximoData.any((value) => value > 0.0)) {'title': 'Máx Peso', 'values': pesoMaximoData},
          if (volumenMaximoData.any((value) => value > 0.0)) {'title': 'Máx Volumen', 'values': volumenMaximoData},
        ];

        return Column(
          children: [
            // Fila de pastillas de selección
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              child: Row(
                children: List.generate(charts.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        chipTheme: Theme.of(context).chipTheme.copyWith(
                              checkmarkColor: Colors.transparent,
                            ),
                      ),
                      child: ChoiceChip(
                        showCheckmark: false,
                        key: _chipKeys[i],
                        label: Text(
                          charts[i]['title'] as String,
                          style: TextStyle(
                            color: selectedIndex == i ? null : AppColors.textMedium,
                          ),
                        ),
                        selected: selectedIndex == i,
                        backgroundColor: AppColors.background,
                        selectedColor: AppColors.mutedAdvertencia,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          side: const BorderSide(color: AppColors.appBarBackground),
                        ),
                        onSelected: (bool selected) {
                          setState(() {
                            selectedIndex = i;
                          });
                          if (_chipKeys[i].currentContext != null) {
                            Scrollable.ensureVisible(
                              _chipKeys[i].currentContext!,
                              duration: const Duration(milliseconds: 300),
                              alignment: 0.5,
                            );
                          }
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Se muestra el gráfico seleccionado
            ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: ChartWidget(title: charts[selectedIndex]['title'] as String, labels: labels, values: charts[selectedIndex]['values'] as List<double>, textNoResults: 'Cuando realices este ejercicio se mostrarán los datos'),
            ),
          ],
        );
      },
    );
  }
}
