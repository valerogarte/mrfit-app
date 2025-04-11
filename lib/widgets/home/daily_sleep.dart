import 'package:flutter/material.dart';
import '../../models/usuario/usuario.dart';
import '../../utils/colors.dart';

class Sleep {
  final int sleepMinutes;
  Sleep({required this.sleepMinutes});
}

Future<Sleep> _loadSleepData(Usuario usuario, DateTime day) async {
  final String formattedDay = day.toIso8601String().split('T').first;
  final parsedDate = DateTime.parse(formattedDay);
  final Map<DateTime, int> sleepMap = await usuario.getSleepByDate(formattedDay);
  final int sleepMinutes = sleepMap[parsedDate] ?? 0;
  return Sleep(sleepMinutes: sleepMinutes);
}

Widget sleepStatsWidget({required DateTime day, required Usuario usuario}) {
  final int targetSleepMinutes = usuario.getTargetSleepMinutes();

  return Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.appBarBackground.withAlpha(75),
      borderRadius: BorderRadius.circular(30),
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: FutureBuilder<Sleep>(
        future: _loadSleepData(usuario, day),
        builder: (context, snapshot) {
          Widget content;
          if (snapshot.connectionState != ConnectionState.done) {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.mutedAdvertencia,
                      child: const Icon(Icons.bedtime, color: AppColors.background, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "0 min",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                HorizontalSleepLoader(sleepMinutes: 0, targetSleepMinutes: targetSleepMinutes),
              ],
            );
          } else if (snapshot.hasError) {
            content = const SizedBox(key: ValueKey('error'));
          } else {
            final sleepData = snapshot.data!;
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.mutedAdvertencia,
                      child: const Icon(Icons.bedtime, color: AppColors.background, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${sleepData.sleepMinutes} min',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                HorizontalSleepLoader(sleepMinutes: sleepData.sleepMinutes, targetSleepMinutes: targetSleepMinutes),
              ],
            );
          }
          return content;
        },
      ),
    ),
  );
}

class HorizontalSleepLoader extends StatelessWidget {
  final int sleepMinutes;
  final int targetSleepMinutes;
  const HorizontalSleepLoader({
    Key? key,
    required this.sleepMinutes,
    required this.targetSleepMinutes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double percent = targetSleepMinutes > 0 ? sleepMinutes / targetSleepMinutes : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: percent),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) {
        return Container(
          width: double.infinity,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.background, // fondo del loader modificado
            borderRadius: BorderRadius.circular(10),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.mutedAdvertencia, // relleno del loader modificado
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }
}
