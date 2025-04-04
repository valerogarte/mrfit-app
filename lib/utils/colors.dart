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

  // Color mensaje de error
  static const Color advertencia = Colors.yellow; // Amarillo

  static const Color mutedAdvertencia = Color.fromARGB(255, 202, 202, 41);

  static const Color mutedWarning = Color(0xFF9A9B1F); // Amarillo verdoso apagado

  // Color advertencia
  static const Color deleteColor = Color(0xFFE74C3C); // Rojo brillante

  /// Rojo más apagado que tira hacia el cardBackground
  static const Color mutedRed = Color(0xFF8B3A3A); // Rojo apagado

  /// Color del texto en elementos destacados o blancos
  static const Color whiteText = Color(0xFFFFFFFF); // Blanco puro

  /// Color secundario para elementos adicionales
  static const Color secondaryColor = Color(0xFF3498DB); // Azul medio
}
