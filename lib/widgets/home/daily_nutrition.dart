import 'package:flutter/material.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';

class DailyNutritionWidget extends StatefulWidget {
  final DateTime day;
  final Usuario usuario;

  const DailyNutritionWidget({
    super.key,
    required this.day,
    required this.usuario,
  });

  @override
  State<DailyNutritionWidget> createState() => _DailyNutritionWidgetState();
}

class _DailyNutritionWidgetState extends State<DailyNutritionWidget> {
  late Future<void> _initialization;
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
    });
  }

  Future<void> _updateCaloricDifference(int delta) async {
    setState(() {
      _currentCalories += delta;
    });
    await widget.usuario.setDiferenciaCalorica(
      widget.day,
      _currentCalories.toDouble(),
    );
  }

  Widget _buildContent(bool isLoading, bool isToday) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
                child: Icon(
                  Icons.restaurant,
                  color: AppColors.mutedGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Diferencia calórica',
                style: TextStyle(
                  color: AppColors.textMedium,
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
              _buildButton(
                '--',
                () => _updateCaloricDifference(-100),
                isToday && !isLoading,
              ),
              _buildButton(
                '-',
                () => _updateCaloricDifference(-25),
                isToday && !isLoading,
              ),
              _buildDisplay(isLoading ? '-' : '$_currentCalories'),
              _buildButton(
                '+',
                () => _updateCaloricDifference(25),
                isToday && !isLoading,
              ),
              _buildButton(
                '++',
                () => _updateCaloricDifference(100),
                isToday && !isLoading,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = widget.day.year == now.year && widget.day.month == now.month && widget.day.day == now.day;

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        }

        return _buildContent(isLoading, isToday);
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
              color: enabled ? AppColors.mutedGreen : AppColors.textMedium.withAlpha(125),
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplay(String value) {
    return Expanded(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.2,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.mutedGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'kcal',
                style: TextStyle(
                  color: AppColors.mutedGreen,
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
