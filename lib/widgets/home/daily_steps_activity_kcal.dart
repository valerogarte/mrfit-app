import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:mrfit/models/usuario/usuario.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/widgets/chart/triple_ring_loader.dart';

// Duración unificada para animaciones de valor y ring.
const Duration kStatsAnimationDuration = Duration(milliseconds: 1000);

// Widget principal que calcula y muestra las estadísticas diarias.
// Unifica lógica y UI para mayor claridad y simplicidad.
Widget dailyStatsWidget({
  required Usuario usuario,
  required Map<String, bool> grantedPermissions,
  required List<HealthDataPoint> dataPointsSteps,
  required List<HealthDataPoint> dataPointsWorkout,
  required List<Map<String, dynamic>> entrenamientosMrFit,
}) {
  final int targetSteps = usuario.objetivoPasosDiarios;
  final int targetMinActividad = usuario.objetivoTiempoEntrenamiento;
  final int targetHorasActivo = usuario.objetivoKcal;

  int steps = 0;
  int minutes = 0;
  int horasActivo = 0;

  if (grantedPermissions['STEPS'] == true) {
    steps = usuario.getTotalSteps(dataPointsSteps);
  }
  if (grantedPermissions['STEPS'] == true && grantedPermissions['WORKOUT'] == true) {
    minutes = usuario.getTimeActivityByDateForCalendar(
      grantedPermissions,
      dataPointsSteps,
      dataPointsWorkout,
      entrenamientosMrFit,
    );
    horasActivo = usuario.getTimeUserActivity(
      steps: dataPointsSteps,
      entrenamientos: dataPointsWorkout,
      entrenamientosMrFit: entrenamientosMrFit,
    );
  }

  final hasStepsPermission = grantedPermissions['STEPS'] == true;
  final hasActivityPermission = grantedPermissions['STEPS'] == true && grantedPermissions['WORKOUT'] == true;

  final List<Widget> statWidgets = [];

  // Steps widget
  if (hasStepsPermission) {
    statWidgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedInfoItem(
          color: AppColors.accentColor,
          icon: Icons.directions_walk,
          finalValue: steps,
          label: 'pasos',
          duration: kStatsAnimationDuration, // Unifica duración
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
          finalValue: minutes,
          label: 'min',
          duration: kStatsAnimationDuration, // Unifica duración
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
  if (hasActivityPermission) {
    statWidgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedInfoItem(
          color: AppColors.mutedGreen,
          icon: Icons.local_fire_department,
          finalValue: horasActivo,
          label: 'h activo',
          duration: kStatsAnimationDuration,
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

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Muestra el botón de permisos si no está disponible Activity Recognition.
      if (!usuario.isActivityRecognitionAvailable) ...[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.privacy_tip, color: AppColors.background),
            label: const Text(
              'Permisos para acceder a tu actividad',
              style: TextStyle(color: AppColors.background),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mutedAdvertencia,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () async {
              await usuario.ensurePermissions();
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
      _buildStatsContainer(
        children: statWidgets,
        loader: AnimatedTripleRingLoader(
          pasosPercent: hasStepsPermission && targetSteps > 0 ? steps / targetSteps : 0,
          minutosPercent: hasActivityPermission && targetMinActividad > 0 ? minutes / targetMinActividad : 0,
          horasActivo: hasActivityPermission && targetHorasActivo > 0 ? horasActivo / targetHorasActivo : 0,
          trainedToday: hasStepsPermission || hasActivityPermission || hasActivityPermission,
          duration: kStatsAnimationDuration, // Unifica duración
        ),
        key: const ValueKey('loaded'),
      ),
    ],
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
      color: AppColors.cardBackground,
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
    super.key,
    required this.color,
    required this.icon,
    required this.finalValue,
    required this.label,
    this.duration = kStatsAnimationDuration,
  });

  @override
  Widget build(BuildContext context) {
    // Usar ValueKey para reiniciar la animación cuando cambia el valor final
    return TweenAnimationBuilder<int>(
      key: ValueKey(finalValue),
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
  final double horasActivo;
  final bool trainedToday;
  final Duration duration;

  const AnimatedTripleRingLoader({
    super.key,
    required this.pasosPercent,
    required this.minutosPercent,
    required this.horasActivo,
    required this.trainedToday,
    this.duration = kStatsAnimationDuration, // Usa duración unificada por defecto
  });

  @override
  Widget build(BuildContext context) {
    // Animar cada anillo por separado para una animación fluida y predecible.
    return TweenAnimationBuilder<double>(
      key: ValueKey('${pasosPercent}_${minutosPercent}_$horasActivo'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animationValue, child) {
        // Cada porcentaje se anima individualmente para evitar saltos.
        // Importante: NO clampees aquí, deja que el painter reciba el valor real.
        final animatedPasos = pasosPercent * animationValue;
        final animatedMinutos = minutosPercent * animationValue;
        final animatedHorasActivo = horasActivo * animationValue;
        return CustomPaint(
          size: const Size(125, 125),
          painter: TripleRingLoaderPainter(
            pasosPercent: animatedPasos,
            minutosPercent: animatedMinutos,
            horasActivo: animatedHorasActivo,
            trainedToday: trainedToday,
            backgroundColorRing: AppColors.background,
            showNumberLap: true,
          ),
        );
      },
    );
  }
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
          backgroundColor: color.withAlpha(50),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(0, 32),
        ),
      ),
    ],
  );
}
