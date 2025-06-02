import 'package:flutter/material.dart';
import 'package:mrfit/utils/colors.dart';

class NotFoundData extends StatelessWidget {
  final String title;
  final String? textNoResults;

  const NotFoundData({
    required this.title,
    this.textNoResults,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.mutedAdvertencia,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.background,
              size: 48.0,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.background,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (textNoResults != null) ...[
              const SizedBox(height: 8.0),
              Text(
                textNoResults!,
                style: const TextStyle(
                  color: AppColors.background,
                  fontSize: 16.0,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
