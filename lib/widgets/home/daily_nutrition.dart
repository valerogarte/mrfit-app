import 'package:flutter/material.dart';
import '../../models/usuario/usuario.dart';
import '../../utils/colors.dart';

class DailyNutritionWidget extends StatefulWidget {
  final DateTime day;
  final Usuario usuario;

  const DailyNutritionWidget({
    Key? key,
    required this.day,
    required this.usuario,
  }) : super(key: key);

  @override
  State<DailyNutritionWidget> createState() => _DailyNutritionWidgetState();
}

class _DailyNutritionWidgetState extends State<DailyNutritionWidget> {
  late Future<void> _initialization;
  double _progress = 0.0;
  int _currentCalories = 0;

  @override
  void initState() {
    super.initState();
    _initialization = _loadCaloricDifference();
  }

  @override
  void didUpdateWidget(covariant DailyNutritionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day) {
      setState(() {
        _initialization = _loadCaloricDifference();
      });
    }
  }

  Future<void> _loadCaloricDifference() async {
    final kcal = await widget.usuario.getByDate(widget.day);
    setState(() {
      _currentCalories = kcal?.round() ?? 0;
      _progress = (_currentCalories + 2000) / 4000;
    });
  }

  Future<void> _updateCaloricDifference(int delta) async {
    setState(() {
      _currentCalories += delta;
      _progress = (_currentCalories + 2000) / 4000;
    });
    await widget.usuario.setDiferenciaCalorica(
      widget.day,
      _currentCalories.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = widget.day.year == now.year && widget.day.month == now.month && widget.day.day == now.day;

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.appBarBackground.withAlpha(75),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.advertencia,
                    child: const Icon(
                      Icons.restaurant,
                      color: AppColors.background,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Diferencia calórica',
                    style: TextStyle(
                      color: AppColors.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildButton('--', () => _updateCaloricDifference(-100), isToday),
                  _buildButton('-', () => _updateCaloricDifference(-25), isToday),
                  _buildDisplay(),
                  _buildButton('+', () => _updateCaloricDifference(25), isToday),
                  _buildButton('++', () => _updateCaloricDifference(100), isToday),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed, bool enabled) {
    return Expanded(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.2,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.background,
            shape: const CircleBorder(),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? AppColors.mutedAdvertencia : AppColors.textColor.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    return Expanded(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.2,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_currentCalories',
                style: const TextStyle(
                  color: AppColors.advertencia,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'kcal',
                style: TextStyle(
                  color: AppColors.advertencia,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
