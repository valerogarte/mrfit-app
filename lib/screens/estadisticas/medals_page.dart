import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/chart/medal_card.dart';
import 'package:mrfit/models/usuario/usuario.dart';

class MedalsPage extends StatefulWidget {
  final Usuario usuario;

  const MedalsPage({super.key, required this.usuario});

  @override
  State<MedalsPage> createState() => _MedalsPageState();
}

class _MedalsPageState extends State<MedalsPage> {
  Future<void> recalcularMedallas(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.mutedSilver),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Recalculando medallas. Esto puede tardar unos instantes.',
                style: TextStyle(color: AppColors.textMedium),
              ),
            ),
          ],
        ),
      ),
    );

    String resultMsg = "OK";
    try {
      await widget.usuario.getTop5Records(getFromCache: false);
    } catch (e) {
      resultMsg = "KO";
    }
    if (mounted) {
      // ignore: use_build_context_synchronously
      Navigator.of(context, rootNavigator: true).pop();
      // Actualiza el estado para refrescar las medallas tras recalcular
      setState(() {});
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(resultMsg == "OK" ? "Éxito" : "Error", style: const TextStyle(color: AppColors.textNormal)),
          content: Text(
            resultMsg == "OK" ? "Las medallas se han recalculado correctamente." : "Hubo un error al recalcular las medallas.",
            style: const TextStyle(color: AppColors.textMedium),
          ),
          actions: [
            TextButton(
              child: const Text('OK', style: TextStyle(color: AppColors.mutedSilver)),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  List<Map<String, dynamic>> makeMedals(
    String key,
    List<Map<String, dynamic>> records,
    Map<String, List<int>> defaults,
    Map<String, IconData> iconos,
  ) {
    // thresholds ordenados
    final thresholds = List<int>.from(defaults[key]!)..sort();

    // si no hay registros, saco 3 defaults asc + disabled siguiente
    if (records.isEmpty) {
      final medals = <Map<String, dynamic>>[];
      for (var i = 0; i < 3 && i < thresholds.length; i++) {
        medals.add({
          'icon': iconos[key]!,
          'value': thresholds[i].toString(),
          'units': key == 'STEPS'
              ? 'pasos'
              : key == 'WORKOUT'
                  ? 'min'
                  : 'semanas',
          'date': '-',
          'type': 'disabled',
        });
      }
      // siguiente umbral default o dinámico
      final next = thresholds.length > 3 ? thresholds[3] : thresholds.last;
      medals.add({
        'icon': iconos[key]!,
        'value': next.toString(),
        'units': medals.first['units'],
        'date': '-',
        'type': 'disabled',
      });
      return medals;
    }

    // 1) Top4 reales
    records.sort((a, b) => (b['value'] as int).compareTo(a['value'] as int));
    final topN = records.take(4).toList();

    // 2) Calcula nextThreshold
    final maxValue = records.first['value'] as int;
    final greater = thresholds.firstWhere((u) => u > maxValue, orElse: () => -1);
    int nextThreshold;
    if (greater > 0) {
      nextThreshold = greater;
    } else {
      switch (key) {
        case 'STEPS':
          nextThreshold = ((maxValue + 5000 - 1) ~/ 5000) * 5000;
          break;
        case 'WORKOUT':
          nextThreshold = ((maxValue + 15 - 1) ~/ 15) * 15;
          break;
        case 'WEEKLY_STREAK':
          nextThreshold = maxValue + 1;
          break;
        default:
          nextThreshold = maxValue;
      }
    }

    // 3) Creo tarjetas reales
    final medals = <Map<String, dynamic>>[];
    for (var i = 0; i < topN.length; i++) {
      final rec = topN[i];
      dynamic date;
      if (rec['date'] == "-") {
        date = "-";
      } else {
        date = DateFormat('d MMMM yyyy', 'es_ES').format(DateTime.parse(rec['date']));
      }
      String type = (i == 0)
          ? 'platinum'
          : (i == 1)
              ? 'silver'
              : (i == 2)
                  ? 'bronze'
                  : 'blue';
      medals.add({
        'icon': iconos[key]!,
        'value': rec['value'].toString(),
        'units': key == 'STEPS'
            ? 'pasos'
            : key == 'WORKOUT'
                ? 'min'
                : 'semanas',
        'date': date,
        'type': type,
      });
    }

    // 4) Relleno con defaults hasta minRecords=records<3?3:4
    final minRecords = (records.length < 3) ? 3 : 4;
    final used = medals.map((m) => int.parse(m['value'])).toSet();
    var idx = 0;
    while (medals.length < minRecords && idx < thresholds.length) {
      final u = thresholds[idx++];
      if (!used.contains(u)) {
        medals.add({
          'icon': iconos[key]!,
          'value': u.toString(),
          'units': medals.first['units'],
          'date': '-',
          'type': 'disabled',
        });
        used.add(u);
      }
    }

    // 5) añado la medalla extra
    medals.add({
      'icon': iconos[key]!,
      'value': nextThreshold.toString(),
      'units': medals.first['units'],
      'date': '-',
      'type': 'disabled',
    });

    return medals;
  }

  @override
  Widget build(BuildContext context) {
    final defaults = {
      "STEPS": [5000, 10000, 20000, 30000, 40000],
      "WORKOUT": [60, 90, 120, 180, 210],
      "WEEKLY_STREAK": [2, 4, 6, 8, 10],
    };
    final iconos = {
      "STEPS": Icons.directions_walk,
      "WORKOUT": Icons.access_time,
      "WEEKLY_STREAK": Icons.calendar_today,
    };
    final sectionTitles = {
      "STEPS": "Récords de pasos",
      "WORKOUT": "Tiempo máximo entrenando",
      "WEEKLY_STREAK": "Semanas seguidas entrenando",
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Medallas"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'recalcular') recalcularMedallas(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'recalcular', child: Text('Recalcular')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: widget.usuario.getTop5Records().timeout(const Duration(seconds: 180), onTimeout: () => {}),
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return const Center(child: Text('Error al cargar las medallas.'));
          final data = snap.data ?? {};
          if (data.isEmpty) return const Center(child: Text('No hay registros de medallas.'));
          final sections = ["STEPS", "WORKOUT", "WEEKLY_STREAK"];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: sections.length,
                    itemBuilder: (context, idx) {
                      final keyData = sections[idx];
                      final recs = data[keyData] ?? [];
                      final medals = makeMedals(keyData, recs, defaults, iconos);
                      final w = MediaQuery.of(context).size.width;
                      final mw = w / 4.5;
                      final mh = mw / 0.75;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sectionTitles[keyData]!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                  children: medals.asMap().entries.map((entry) {
                                    final i = entry.key;
                                    final r = entry.value;
                                    // Solo añadir padding a la derecha si no es la última medalla
                                    return Padding(
                                      padding: EdgeInsets.only(right: i == medals.length - 1 ? 0 : 12),
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
