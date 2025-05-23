import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/chart/triple_ring_loader.dart';

class DailyStats {
  final int steps;
  final int minutes;
  final int kcal;
  final Map<String, bool> permissions;

  DailyStats({
    required this.steps,
    required this.minutes,
    required this.kcal,
    required this.permissions,
  });
}

Future<DailyStats> _loadDailyStats(Usuario usuario, DateTime day) async {
  final Map<String, bool> grantedPermissions = {};

  for (var key in usuario.healthDataTypesString.keys) {
    final bool permissionGranted = await usuario.checkPermissionsFor(key);
    grantedPermissions[key] = permissionGranted;
  }

  int steps = 0;
  int minutes = 0;
  int kcal = 0;

  final String formattedDay = day.toIso8601String().split('T').first;
  final parsedDate = DateTime.parse(formattedDay);

  if (grantedPermissions['STEPS'] == true) {
    steps = await usuario.getTotalSteps(date: formattedDay);
  }

  if (grantedPermissions['STEPS'] == true && grantedPermissions['WORKOUT'] == true) {
    minutes = await usuario.getTimeActivityByDateForCalendar(formattedDay);
  }

  if (grantedPermissions['TOTAL_CALORIES_BURNED'] == true) {
    final Map<DateTime, double> kcalMap = await usuario.getTotalCaloriesBurned(date: formattedDay);
    kcal = kcalMap[parsedDate]?.round() ?? 0;
  }

  return DailyStats(steps: steps, minutes: minutes, kcal: kcal, permissions: grantedPermissions);
}

Widget permissionButton({
  required Color color,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return Row(
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: color,
        child: Icon(icon, color: AppColors.background, size: 18),
      ),
      const SizedBox(width: 12),
      ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.settings, size: 16),
        label: const Text('Permisos'),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 32),
        ),
      ),
    ],
  );
}

Widget dailyStatsWidget({required DateTime day, required Usuario usuario}) {
  final int targetSteps = usuario.objetivoPasosDiarios;
  final int targetMinActividad = usuario.objetivoTiempoEntrenamiento;
  final int targetKcalBurned = usuario.objetivoKcal;

  return FutureBuilder<DailyStats>(
    future: _loadDailyStats(usuario, day),
    builder: (context, snapshot) {
      Widget content;

      if (snapshot.connectionState != ConnectionState.done) {
        final items = [
          (AppColors.accentColor, Icons.directions_walk, 0, 'pasos', targetSteps),
          (AppColors.mutedAdvertencia, Icons.access_time, 0, 'min', targetMinActividad),
          (AppColors.mutedGreen, Icons.local_fire_department, 0, 'kcal', targetKcalBurned),
        ];
        content = _buildStatsContainer(
          children: buildInfoItems(items: items, isAnimated: false),
          loader: const _StaticTripleRingLoader(trainedToday: false),
          key: const ValueKey('placeholder'),
        );
      } else if (snapshot.hasError) {
        Logger().w('Error cargando datos diarios: ${snapshot.error}');
        content = const SizedBox(key: ValueKey('error'));
      } else {
        final stats = snapshot.data!;

        final hasStepsPermission = stats.permissions['STEPS'] == true;
        final hasActivityPermission = stats.permissions['STEPS'] == true && stats.permissions['WORKOUT'] == true;
        final hasCaloriesPermission = stats.permissions['TOTAL_CALORIES_BURNED'] == true;

        final List<Widget> statWidgets = [];

        // Steps widget
        if (hasStepsPermission) {
          statWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedInfoItem(
                color: AppColors.accentColor,
                icon: Icons.directions_walk,
                finalValue: stats.steps,
                label: 'pasos',
                duration: const Duration(milliseconds: 500),
              ),
            ),
          );
        } else {
          statWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: permissionButton(
                color: AppColors.accentColor,
                icon: Icons.directions_walk,
                onTap: () => usuario.requestPermissions(),
              ),
            ),
          );
        }

        // Activity minutes widget
        if (hasActivityPermission) {
          statWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedInfoItem(
                color: AppColors.mutedAdvertencia,
                icon: Icons.access_time,
                finalValue: stats.minutes,
                label: 'min',
                duration: const Duration(milliseconds: 500),
              ),
            ),
          );
        } else {
          statWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: permissionButton(
                color: AppColors.mutedAdvertencia,
                icon: Icons.access_time,
                onTap: () async {
                  await usuario.requestPermissions();
                },
              ),
            ),
          );
        }

        // Calories widget
        if (hasCaloriesPermission) {
          statWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedInfoItem(
                color: AppColors.mutedGreen,
                icon: Icons.local_fire_department,
                finalValue: stats.kcal,
                label: 'kcal',
                duration: const Duration(milliseconds: 500),
              ),
            ),
          );
        } else {
          statWidgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: permissionButton(
                color: AppColors.mutedGreen,
                icon: Icons.local_fire_department,
                onTap: () => usuario.requestPermissions(),
              ),
            ),
          );
        }

        content = _buildStatsContainer(
          children: statWidgets,
          loader: AnimatedTripleRingLoader(
            pasosPercent: hasStepsPermission && targetSteps > 0 ? stats.steps / targetSteps : 0,
            minutosPercent: hasActivityPermission && targetMinActividad > 0 ? stats.minutes / targetMinActividad : 0,
            kcalPercent: hasCaloriesPermission && targetKcalBurned > 0 ? stats.kcal / targetKcalBurned : 0,
            trainedToday: hasStepsPermission || hasActivityPermission || hasCaloriesPermission,
          ),
          key: const ValueKey('loaded'),
        );
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: content,
      );
    },
  );
}

Widget infoItem({
  required Color color,
  required IconData icon,
  required String value,
  required String label,
}) {
  return Row(
    children: [
      CircleAvatar(
        radius: 16,
        backgroundColor: color,
        child: Icon(icon, color: AppColors.background, size: 18),
      ),
      const SizedBox(width: 12),
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$value ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textNormal,
              ),
            ),
            TextSpan(
              text: label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

List<Widget> buildInfoItems({
  required List<(Color, IconData, int, String, int)> items,
  required bool isAnimated,
}) {
  const duration = Duration(milliseconds: 500);
  return items
      .map<Widget>(
        (item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: isAnimated
              ? AnimatedInfoItem(
                  color: item.$1,
                  icon: item.$2,
                  finalValue: item.$3,
                  label: item.$4,
                  duration: duration,
                )
              : infoItem(
                  color: item.$1,
                  icon: item.$2,
                  value: '0',
                  label: item.$4,
                ),
        ),
      )
      .toList();
}

Widget _buildStatsContainer({
  required List<Widget> children,
  required Widget loader,
  required Key key,
}) {
  return Container(
    key: key,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    decoration: BoxDecoration(
      color: AppColors.appBarBackground.withAlpha(75),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
        const SizedBox(width: 20),
        loader,
      ],
    ),
  );
}

class AnimatedInfoItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final int finalValue;
  final String label;
  final Duration duration;

  const AnimatedInfoItem({
    Key? key,
    required this.color,
    required this.icon,
    required this.finalValue,
    required this.label,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: finalValue),
      duration: duration,
      builder: (context, value, child) {
        final formattedValue = value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
        return infoItem(
          color: color,
          icon: icon,
          value: formattedValue,
          label: label,
        );
      },
    );
  }
}

class AnimatedTripleRingLoader extends StatelessWidget {
  final double pasosPercent;
  final double minutosPercent;
  final double kcalPercent;
  final bool trainedToday;
  final Duration duration;

  const AnimatedTripleRingLoader({
    Key? key,
    required this.pasosPercent,
    required this.minutosPercent,
    required this.kcalPercent,
    required this.trainedToday,
    this.duration = const Duration(milliseconds: 1000),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, animationValue, child) {
        return CustomPaint(
          size: const Size(125, 125),
          painter: TripleRingLoaderPainter(
            pasosPercent: pasosPercent * animationValue,
            minutosPercent: minutosPercent * animationValue,
            kcalPercent: kcalPercent * animationValue,
            trainedToday: trainedToday,
            backgroundColorRing: AppColors.background,
            showNumberLap: true,
          ),
        );
      },
    );
  }
}

class _StaticTripleRingLoader extends StatelessWidget {
  final bool trainedToday;
  const _StaticTripleRingLoader({this.trainedToday = false});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(125, 125),
      painter: TripleRingLoaderPainter(
        pasosPercent: 0,
        minutosPercent: 0,
        kcalPercent: 0,
        trainedToday: trainedToday,
        backgroundColorRing: AppColors.background,
        showNumberLap: true,
      ),
    );
  }
}
