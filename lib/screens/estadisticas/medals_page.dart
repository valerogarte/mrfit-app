import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/chart/medal_card.dart';
import 'package:mrfit/models/usuario/usuario.dart';

class MedalsPage extends StatelessWidget {
  final Usuario usuario;
  final int lookbackDays;

  const MedalsPage({Key? key, required this.usuario, this.lookbackDays = 30}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medallas"),
      ),
      body: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: Future.wait([
          usuario.getMaxRunDistanceRecord(lookbackDays),
          usuario.getMaxStepsDayRecord(lookbackDays),
          usuario.getMaxWorkoutMinutesRecord(lookbackDays),
          usuario.getMaxWorkoutWeeklyRecord(lookbackDays), // Added call
        ]),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final fmt = DateFormat('d MMMM yyyy', 'es_ES');
          final runRecs = snap.data![0];
          final stepsRecs = snap.data![1];
          final workRecs = snap.data![2];
          final weeklyRecs = snap.data![3]; // Added weekly records

          final allRecords = {
            "Pasos": [
              {"icon": Icons.directions_walk, "value": "20000", "units": "pasos", "date": "-", "type": "disabled"},
              {"icon": Icons.directions_walk, "value": "30000", "units": "pasos", "date": "-", "type": "disabled"},
              {"icon": Icons.directions_walk, "value": "40000", "units": "pasos", "date": "-", "type": "disabled"},
              {"icon": Icons.directions_walk, "value": "50000", "units": "pasos", "date": "-", "type": "disabled"},
              {"icon": Icons.directions_walk, "value": "60000", "units": "pasos", "date": "-", "type": "disabled"},
            ],
            "Km": [
              {"icon": Icons.directions_run, "value": "10", "units": "km", "date": "-", "type": "disabled"},
              {"icon": Icons.directions_run, "value": "20", "units": "km", "date": "-", "type": "disabled"},
              {"icon": Icons.directions_run, "value": "30", "units": "km", "date": "-", "type": "disabled"},
              {"icon": Icons.directions_run, "value": "40", "units": "km", "date": "-", "type": "disabled"},
              {"icon": Icons.directions_run, "value": "50", "units": "km", "date": "-", "type": "disabled"},
            ],
            "Minutos entrenados": [
              {"icon": Icons.fitness_center, "value": "60", "units": "min", "date": "-", "type": "disabled"},
              {"icon": Icons.fitness_center, "value": "90", "units": "min", "date": "-", "type": "disabled"},
              {"icon": Icons.fitness_center, "value": "120", "units": "min", "date": "-", "type": "disabled"},
              {"icon": Icons.fitness_center, "value": "180", "units": "min", "date": "-", "type": "disabled"},
              {"icon": Icons.fitness_center, "value": "360", "units": "min", "date": "-", "type": "disabled"},
            ],
            "Semanas seguidas entrenando": [
              {"icon": Icons.fitness_center, "value": "2", "units": "semanas", "date": "-", "type": "disabled"},
              {"icon": Icons.fitness_center, "value": "4", "units": "semanas", "date": "-", "type": "disabled"},
              {"icon": Icons.fitness_center, "value": "6", "units": "semanas", "date": "-", "type": "disabled"},
              {"icon": Icons.fitness_center, "value": "8", "units": "semanas", "date": "-", "type": "disabled"},
              {"icon": Icons.fitness_center, "value": "10", "units": "semanas", "date": "-", "type": "disabled"},
            ],
          };

          void asignarMedallas(List<Map<String, dynamic>> medallas, List<Map<String, dynamic>> topRecords) {
            medallas.sort((a, b) => int.parse(a['value']).compareTo(int.parse(b['value'])));

            for (var m in medallas) {
              m['type'] = 'disabled';
              m['date'] = "-";
            }

            final Set<String> diasAsignados = {};
            final List<Map<String, dynamic>> medallasConseguidas = [];

            for (var m in medallas.reversed) {
              final int val = int.parse(m['value']);
              final record = topRecords.firstWhere(
                (r) => val <= r['value'] && !diasAsignados.contains(DateFormat('yyyy-MM-dd').format(r['date'])),
                orElse: () => {},
              );

              if (record.containsKey('date')) {
                final dia = DateFormat('yyyy-MM-dd').format(record['date']);
                diasAsignados.add(dia);
                m['date'] = DateFormat('d MMMM yyyy', 'es_ES').format(record['date']);
                medallasConseguidas.add(m); // guardamos para luego asignar tipo
              }
            }

            // Asignar oro, plata, bronce según el mayor valor conseguido
            medallasConseguidas.sort((a, b) => int.parse(b['value']).compareTo(int.parse(a['value'])));

            for (var i = 0; i < medallasConseguidas.length; i++) {
              if (i == 0) {
                medallasConseguidas[i]['type'] = 'platinum';
              } else if (i == 1) {
                medallasConseguidas[i]['type'] = 'silver';
              } else if (i == 2) {
                medallasConseguidas[i]['type'] = 'bronze';
              } else {
                medallasConseguidas[i]['type'] = 'blue';
              }
            }
          }

          asignarMedallas(allRecords["Pasos"]!, stepsRecs);
          asignarMedallas(allRecords["Km"]!, runRecs);
          asignarMedallas(allRecords["Minutos entrenados"]!, workRecs);
          asignarMedallas(allRecords["Semanas seguidas entrenando"]!, weeklyRecs); // Assign weekly medals

          final w = MediaQuery.of(context).size.width;
          final mw = w / 4.5;
          final mh = mw / 0.75;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: allRecords.keys.length,
                    itemBuilder: (context, index) {
                      final section = allRecords.keys.elementAt(index);
                      final medals = allRecords[section]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: double.infinity,
                              height: mh,
                              color: Colors.transparent,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: medals.map((r) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 12),
                                      child: MedalCard(
                                        width: mw,
                                        icon: r['icon'] as IconData,
                                        value: r['value'] as String,
                                        units: r['units'] as String,
                                        date: r['date'] as String,
                                        type: r['type'] as String,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
