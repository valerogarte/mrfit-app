import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class ConfigBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  const ConfigBottomSheet({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textNormal, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
