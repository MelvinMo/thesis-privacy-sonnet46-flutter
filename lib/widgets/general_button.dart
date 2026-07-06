// MIGRATION: components/GeneralButton.tsx → Dart StatelessWidget.
//            Props: title, onPress, isLoading, disabled.
//            Blue background (#4A90D9), loading spinner, disabled state preserved.

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class GeneralButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPress;
  final bool isLoading;
  final bool disabled;

  const GeneralButton({
    super.key,
    required this.title,
    this.onPress,
    this.isLoading = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && !disabled && onPress != null;
    return GestureDetector(
      onTap: isEnabled ? onPress : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        // MIGRATION: RN disabled uses opacity: 0.6 on the blue, not a grey color.
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.generalBlue
              : AppColors.generalBlue.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                title,
                // MIGRATION: RN color: Colors.lightBlack (#181719) on blue button.
                style: const TextStyle(
                  color: AppColors.lightBlack,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
