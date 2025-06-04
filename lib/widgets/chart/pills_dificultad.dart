import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

Widget buildDificultadPills(int dificultad, double width, double height) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
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
