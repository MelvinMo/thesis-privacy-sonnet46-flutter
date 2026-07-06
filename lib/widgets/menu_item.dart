// MIGRATION: components/MenuItem.tsx → Dart.

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onPress;

  const MenuItem({super.key, required this.title, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  color: Colors.white,
                  fontSize: 14,
                )),
            const Icon(Icons.chevron_right, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
