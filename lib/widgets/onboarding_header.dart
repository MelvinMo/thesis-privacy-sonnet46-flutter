// MIGRATION: components/OnboardingHeader.tsx → Dart.
//            Added optional onBackPress to match source prop used by several
//            onboarding screens that render a back-chevron button.

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class OnboardingHeader extends StatelessWidget {
  final String title;
  // MIGRATION: onBackPress prop from source → optional VoidCallback.
  //            When provided, renders a leading back-chevron (mirrors RN TouchableOpacity).
  final VoidCallback? onBackPress;

  const OnboardingHeader({
    super.key,
    required this.title,
    this.onBackPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button (only when onBackPress is provided).
          if (onBackPress != null)
            GestureDetector(
              onTap: onBackPress,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(Icons.chevron_left,
                    color: AppColors.generalBlue, size: 24),
              ),
            )
          else
            const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              textAlign: onBackPress != null ? TextAlign.left : TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
