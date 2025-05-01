import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';
import 'package:mrfit/models/ejercicio/ejercicio.dart';

Widget buildDificultadPills(Ejercicio ejercicio, double width, double height) {
  final dificultad = int.tryParse(ejercicio.dificultad.titulo) ?? 0;
  return Row(
    mainAxisAlignment: MainAxisAlignment.center, // added to center the pills
    children: List.generate(
      5,
      (index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.0),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: index < dificultad ? AppColors.accentColor : AppColors.appBarBackground,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    ),
  );
}
