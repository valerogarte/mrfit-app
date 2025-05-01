import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class WeeklyStatsWidget extends StatelessWidget {
  final int daysTrainedLast30Days;
  final int daysTrainedLast7Days;

  const WeeklyStatsWidget({
    Key? key,
    required this.daysTrainedLast30Days,
    required this.daysTrainedLast7Days,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.appBarBackground.withAlpha(75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$daysTrainedLast30Days/30',
                  style: TextStyle(
                    fontSize: 40,
                    color: AppColors.accentColor,
                  ),
                ),
                Text(
                  'últimos 30 días.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.fitness_center,
              color: AppColors.accentColor,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$daysTrainedLast7Days/7',
                  style: TextStyle(
                    fontSize: 40,
                    color: AppColors.accentColor,
                  ),
                ),
                Text(
                  'últimos 7 días.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
