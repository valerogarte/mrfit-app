import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/usuario/usuario.dart';

class MedalsWidget extends StatefulWidget {
  final Usuario usuario;
  final int lookbackDays;

  const MedalsWidget({
    Key? key,
    required this.usuario,
    this.lookbackDays = 30,
  }) : super(key: key);

  @override
  State<MedalsWidget> createState() => _MedalsWidgetState();
}

class _MedalsWidgetState extends State<MedalsWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait([
        widget.usuario.getMaxRunDistanceRecord(widget.lookbackDays),
        widget.usuario.getMaxStepsDayRecord(widget.lookbackDays),
        widget.usuario.getMaxWorkoutMinutesRecord(widget.lookbackDays),
      ]),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final runRec = snap.data![0];
        final stepsRec = snap.data![1];
        final workRec = snap.data![2];
        final fmt = DateFormat('dd/MM');

        final records = [
          {"title": "Carrera más larga", "value": "${runRec['value']} km", "date": runRec['date'] != null ? fmt.format(runRec['date']) : ""},
          {"title": "Mayor número de pasos", "value": stepsRec['value'].toString(), "date": stepsRec['date'] != null ? fmt.format(stepsRec['date']) : ""},
          {"title": "Mayor duración de entrenamiento", "value": "${workRec['value']} min", "date": workRec['date'] != null ? fmt.format(workRec['date']) : ""},
        ];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.appBarBackground.withAlpha(75),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.background,
                    child: const Icon(
                      Icons.emoji_events,
                      color: AppColors.mutedAdvertencia,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Medallas",
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...records.map((r) => _buildRecordItem(r)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              r['title'],
              style: const TextStyle(
                color: AppColors.textMedium,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if ((r['date'] as String).isNotEmpty)
              Text(
                "Logro: ${r['date']}",
                style: const TextStyle(
                  color: AppColors.textMedium,
                  fontSize: 12,
                ),
              ),
          ]),
          Text(
            r['value'],
            style: const TextStyle(
              color: AppColors.accentColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
