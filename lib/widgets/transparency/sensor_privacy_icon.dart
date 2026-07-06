// MIGRATION: components/transparency/SensorPrivacyIcon.tsx → Dart.
//            Uses composite PNG images matching RN exactly:
//            assets/images/privacy/sensor/{sensor}-{storage}-{risk}.png
//            Dimensions match RN: accelerometer w=121, others w=124,
//            cloud h=36, local h=45.

import 'package:flutter/material.dart';

class SensorPrivacyIcon extends StatelessWidget {
  final String sensorType;  // 'accelerometer' | 'light' | 'microphone'
  final String iconName;    // privacy risk asset path (used to extract risk level)
  final String storageType; // 'cloud' | 'local'
  final VoidCallback handleIconPress;

  const SensorPrivacyIcon({
    super.key,
    required this.sensorType,
    required this.iconName,
    required this.storageType,
    required this.handleIconPress,
  });

  String get _risk {
    if (iconName.contains('high')) return 'high';
    if (iconName.contains('medium')) return 'medium';
    return 'low';
  }

  @override
  Widget build(BuildContext context) {
    final assetPath =
        'assets/images/privacy/sensor/$sensorType-$storageType-$_risk.png';
    final width = sensorType == 'accelerometer' ? 121.0 : 124.0;
    final height = storageType == 'cloud' ? 36.0 : 45.0;

    return GestureDetector(
      onTap: handleIconPress,
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => SizedBox(width: width, height: height),
      ),
    );
  }
}
