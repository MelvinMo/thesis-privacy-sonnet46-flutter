// MIGRATION: components/Loader.tsx → Dart.
//            Centered ActivityIndicator → CircularProgressIndicator.

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class Loader extends StatelessWidget {
  final double size;
  const Loader({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          color: AppColors.generalBlue,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
