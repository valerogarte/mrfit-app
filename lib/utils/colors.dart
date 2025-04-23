// colors.dart

import 'package:flutter/material.dart';

class AppColors {
  /// Fondo principal de la aplicación
  static const Color background = Color.from(alpha: 1, red: 0.118, green: 0.165, blue: 0.22);

  /// Fondo de las tarjetas y elementos secundarios
  static const Color cardBackground = Color.from(alpha: 1, red: 0.173, green: 0.243, blue: 0.314);

  // Fondo del AppBar
  static const Color appBarBackground = Color.from(alpha: 1, red: 0.231, green: 0.376, blue: 0.518);

  /// Color del texto en elementos destacados o blancos
  static const Color textNormal = Color.from(alpha: 1, red: 1, green: 1, blue: 1);

  /// Color del texto principal
  static const Color textMedium = Color.from(alpha: 1, red: 0.878, green: 0.878, blue: 0.878);

  /// Color de acento para botones y elementos destacables
  static const Color accentColor = Color.from(alpha: 1, red: 0.365, green: 0.678, blue: 0.886);

  // Color de resltado
  static const Color mutedAdvertencia = Color.from(alpha: 1, red: 0.792, green: 0.792, blue: 0.161);

  /// Rojo más apagado que tira hacia el cardBackground
  static const Color mutedRed = Color.from(alpha: 1, red: 0.827, green: 0.329, blue: 0);

  // Verde alternativo
  static Color mutedGreen =
      HSLColor.fromColor(Color.lerp(AppColors.accentColor, AppColors.mutedAdvertencia, 0.4)!).withSaturation((HSLColor.fromColor(Color.lerp(AppColors.accentColor, AppColors.mutedAdvertencia, 0.4)!).saturation * 1.25).clamp(0.0, 1.0)).toColor();
}
