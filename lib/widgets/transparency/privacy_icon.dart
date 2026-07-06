// MIGRATION: components/transparency/PrivacyIcon.tsx → Dart StatelessWidget.
//            Props preserved: handleIconPress, isOpen, iconName, iconSize, iconRef.
//            `iconRef` (React ref to measure position) → not needed in Flutter;
//            position measurement is done in PrivacyTooltip via RenderBox.

import 'package:flutter/material.dart';

class PrivacyIcon extends StatelessWidget {
  final VoidCallback handleIconPress;
  final bool isOpen;
  final String iconName; // asset path e.g. 'assets/images/privacy/privacy-low.png'
  final double iconSize;

  const PrivacyIcon({
    super.key,
    required this.handleIconPress,
    required this.isOpen,
    required this.iconName,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleIconPress,
      child: Image.asset(
        iconName,
        width: iconSize,
        height: iconSize,
        // MIGRATION: When tooltip is open, hide the duplicate icon (same as
        //            childrenWrapperStyle={{ opacity: showTooltip ? 0 : 1 }}).
        opacity: AlwaysStoppedAnimation(isOpen ? 0.0 : 1.0),
      ),
    );
  }
}
