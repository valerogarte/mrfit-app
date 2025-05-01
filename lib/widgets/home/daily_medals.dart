import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class MedalsWidget extends StatefulWidget {
  const MedalsWidget({Key? key}) : super(key: key);

  @override
  State<MedalsWidget> createState() => _MedalsWidgetState();
}

class _MedalsWidgetState extends State<MedalsWidget> {
  final List<Map<String, dynamic>> _records = [
    {"title": "Carrera más larga", "value": "15 km"},
    {"title": "Mayor número de pasos", "value": "20,000"},
    {"title": "Mayor duración de entrenamiento", "value": "2 horas"},
  ];

  void _addRecord(String title, String value) {
    setState(() {
      _records.add({"title": title, "value": value});
    });
  }

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.emoji_events, color: AppColors.mutedAdvertencia, size: 18),
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
          ..._records.map((record) => _buildRecordItem(record)).toList(),
        ],
      ),
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    // TODO: Meter las medallas en columnas y con scroll horizontal
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            record['title'],
            style: const TextStyle(
              color: AppColors.textMedium,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            record['value'],
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