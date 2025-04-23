// colors.dart

import 'package:flutter/material.dart';

class AppColors {
  /// Fondo principal de la aplicación
  static const Color background = Color(0xFF1E2A38); // Azul marino oscuro

  /// Fondo de las tarjetas y elementos secundarios
  static const Color cardBackground = Color(0xFF2C3E50); // Azul oscuro grisáceo

  // Fondo del AppBar
  static const Color appBarBackground = Color.fromARGB(255, 59, 96, 132); // Azul oscuro

  /// Color de acento para botones y elementos destacables
  static const Color accentColor = Color(0xFF5DADE2); // Azul claro brillante

  /// Color intermedio entre accentColor y cardBackground
  static const Color intermediateAccentColor = Color(0xFF4A90E2); // Azul intermedio

  /// Color del texto principal
  static const Color textColor = Color(0xFFE0E0E0); // Gris claro

  // Color de resltado
  static const Color mutedAdvertencia = Color.fromARGB(255, 202, 202, 41);

  /// Rojo más apagado que tira hacia el cardBackground
  static const Color mutedRed = Color(0xFFD35400); // Naranja apagado

  static Color mutedGreen = HSLColor.fromColor(Color.lerp(AppColors.accentColor, AppColors.mutedAdvertencia, 0.4)!)
      .withSaturation((HSLColor.fromColor(Color.lerp(AppColors.accentColor, AppColors.mutedAdvertencia, 0.4)!).saturation * 1.25).clamp(0.0, 1.0))
      .toColor(); // Verde apagado

  /// Color del texto en elementos destacados o blancos
  static const Color whiteText = Color(0xFFFFFFFF); // Blanco puro

  /// Color secundario para elementos adicionales
  static const Color secondaryColor = Color(0xFF3498DB); // Azul medio
}
